const {setGlobalOptions} = require("firebase-functions/v2");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {
  MAX_FAVORITE_CHANGES_PER_HOUR,
  MAX_UNIQUE_VIEWS_PER_HOUR,
  nextRateLimit,
  safeCounter,
  shouldCountProductView,
} = require("./security");

initializeApp();
setGlobalOptions({maxInstances: 20});

const db = getFirestore();
const monitoredCallable = {enforceAppCheck: false};

function authenticatedUid(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Authentication required.");
  return uid;
}

function requiredString(value, field, maxLength) {
  if (typeof value !== "string" || value.trim().length === 0 || value.length > maxLength) {
    throw new HttpsError("invalid-argument", `Invalid ${field}.`);
  }
  return value.trim();
}

function publicProfile(uid, data) {
  return {
    uid,
    name: String(data.name || ""),
    lastName: String(data.lastName || ""),
    country: String(data.country || ""),
    city: String(data.city || ""),
    photo: String(data.photo || ""),
    verified: data.verified === true,
    reputation: Number(data.reputation || 5),
    reviewCount: Number(data.reviewCount || 0),
  };
}

exports.syncPublicProfileOnUserWrite = onDocumentWritten("users/{uid}", async (event) => {
  const uid = event.params.uid;
  const profileRef = db.collection("publicProfiles").doc(uid);
  if (!event.data.after.exists) {
    await profileRef.delete();
    return;
  }
  await profileRef.set(publicProfile(uid, event.data.after.data()));
});

// Migra de forma segura cuentas creadas antes de publicProfiles.
exports.syncMyPublicProfile = onCall(async (request) => {
  const uid = authenticatedUid(request);
  const userSnapshot = await db.collection("users").doc(uid).get();
  if (!userSnapshot.exists) throw new HttpsError("not-found", "Profile not found.");
  await db.collection("publicProfiles").doc(uid)
    .set(publicProfile(uid, userSnapshot.data()));
  return {synced: true};
});

exports.toggleFavorite = onCall(monitoredCallable, async (request) => {
  const uid = authenticatedUid(request);
  const productId = requiredString(request.data?.productId, "productId", 160);
  const add = request.data?.add;
  if (typeof add !== "boolean") {
    throw new HttpsError("invalid-argument", "Invalid favorite state.");
  }

  const productRef = db.collection("products").doc(productId);
  const favoriteRef = db.collection("users").doc(uid).collection("favorites").doc(productId);
  const actorRef = db.collection("users").doc(uid);
  const rateLimitRef = actorRef.collection("securityLimits").doc("favoriteChanges");

  return db.runTransaction(async (transaction) => {
    const now = Timestamp.now();
    const [productSnapshot, favoriteSnapshot, actorSnapshot, rateLimitSnapshot] = await Promise.all([
      transaction.get(productRef),
      transaction.get(favoriteRef),
      transaction.get(actorRef),
      transaction.get(rateLimitRef),
    ]);
    if (!productSnapshot.exists) {
      throw new HttpsError("not-found", "Product is not available.");
    }

    if (!actorSnapshot.exists) {
      throw new HttpsError("failed-precondition", "User profile is required.");
    }

    const product = productSnapshot.data();
    const currentCount = safeCounter(product.favorites, "favorite");
    if (favoriteSnapshot.exists === add) return {favoriteCount: currentCount};

    const rateLimit = nextRateLimit(
      rateLimitSnapshot,
      MAX_FAVORITE_CHANGES_PER_HOUR,
      now,
    );
    const nextCount = add ? currentCount + 1 : currentCount - 1;
    if (nextCount < 0) {
      throw new HttpsError("failed-precondition", "Favorite counter is inconsistent.");
    }
    if (add) {
      transaction.set(favoriteRef, {productId, createdAt: FieldValue.serverTimestamp()});
    } else {
      transaction.delete(favoriteRef);
    }
    transaction.set(rateLimitRef, rateLimit);
    transaction.update(productRef, {favorites: nextCount});

    const sellerId = String(product.sellerId || "");
    if (add && sellerId && sellerId !== uid) {
      const actor = actorSnapshot.data() || {};
      const actorName = `${actor.name || ""} ${actor.lastName || ""}`.trim() || "Alguien";
      const notificationRef = db.collection("users").doc(sellerId)
        .collection("notifications").doc(`${productId}_${uid}`);
      transaction.set(notificationRef, {
        type: "favorite",
        title: "Nuevo favorito",
        message: `${actorName} agregó "${product.title || "tu producto"}" a sus favoritos.`,
        productId,
        actorId: uid,
        actorName,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    return {favoriteCount: nextCount};
  });
});

exports.recordProductView = onCall(monitoredCallable, async (request) => {
  const uid = authenticatedUid(request);
  const productId = requiredString(request.data?.productId, "productId", 160);
  const productRef = db.collection("products").doc(productId);
  const eventRef = productRef.collection("viewEvents").doc(uid);
  const actorRef = db.collection("users").doc(uid);
  const rateLimitRef = actorRef.collection("securityLimits").doc("productViews");

  return db.runTransaction(async (transaction) => {
    const now = Timestamp.now();
    const [productSnapshot, eventSnapshot, actorSnapshot, rateLimitSnapshot] = await Promise.all([
      transaction.get(productRef),
      transaction.get(eventRef),
      transaction.get(actorRef),
      transaction.get(rateLimitRef),
    ]);
    if (!productSnapshot.exists) throw new HttpsError("not-found", "Product not found.");
    if (!actorSnapshot.exists) {
      throw new HttpsError("failed-precondition", "User profile is required.");
    }
    const product = productSnapshot.data();
    const currentCount = safeCounter(product.views, "view");
    const lastViewedAt = eventSnapshot.data()?.viewedAt;
    if (!shouldCountProductView(product, uid, lastViewedAt, now)) {
      return {viewCount: currentCount, counted: false};
    }
    const rateLimit = nextRateLimit(
      rateLimitSnapshot,
      MAX_UNIQUE_VIEWS_PER_HOUR,
      now,
    );
    transaction.set(rateLimitRef, rateLimit);
    transaction.set(eventRef, {viewerId: uid, viewedAt: now});
    transaction.update(productRef, {views: currentCount + 1});
    return {viewCount: currentCount + 1, counted: true};
  });
});

exports.createReview = onCall(async (request) => {
  const uid = authenticatedUid(request);
  const productId = requiredString(request.data?.productId, "productId", 160);
  const comment = requiredString(request.data?.comment, "comment", 1200);
  const rating = request.data?.rating;
  const tags = request.data?.tags;
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    throw new HttpsError("invalid-argument", "Rating must be between 1 and 5.");
  }
  if (!Array.isArray(tags) || tags.length > 8 || tags.some((tag) => typeof tag !== "string" || tag.length > 60)) {
    throw new HttpsError("invalid-argument", "Invalid review tags.");
  }

  const productRef = db.collection("products").doc(productId);
  const reviewerRef = db.collection("users").doc(uid);
  const reviewRef = db.collection("reviews").doc(`${productId}_${uid}`);

  await db.runTransaction(async (transaction) => {
    const [productSnapshot, reviewerSnapshot, existingReview] = await Promise.all([
      transaction.get(productRef), transaction.get(reviewerRef), transaction.get(reviewRef),
    ]);
    if (!productSnapshot.exists) throw new HttpsError("not-found", "Product not found.");
    if (existingReview.exists) throw new HttpsError("already-exists", "Review already exists.");
    const product = productSnapshot.data();
    const sellerId = String(product.sellerId || "");
    if (!sellerId || sellerId === uid) throw new HttpsError("permission-denied", "Invalid seller.");
    const sellerRef = db.collection("users").doc(sellerId);
    const sellerSnapshot = await transaction.get(sellerRef);
    const seller = sellerSnapshot.data() || {};
    const reviewer = reviewerSnapshot.data() || {};
    const previousCount = Number(seller.reviewCount || 0);
    const previousTotal = Number(seller.reviewRatingTotal || 0);
    const newCount = previousCount + 1;
    const newTotal = previousTotal + rating;
    const now = FieldValue.serverTimestamp();

    transaction.set(reviewRef, {
      productId,
      productTitle: product.title || "",
      sellerId,
      sellerName: product.sellerName || "",
      reviewerId: uid,
      reviewerName: `${reviewer.name || ""} ${reviewer.lastName || ""}`.trim(),
      reviewerPhoto: reviewer.photo || "",
      rating,
      comment,
      tags,
      reported: false,
      createdAt: now,
      updatedAt: now,
    });
    transaction.update(sellerRef, {
      reputation: newTotal / newCount,
      reviewCount: newCount,
      reviewRatingTotal: newTotal,
    });
    transaction.set(db.collection("publicProfiles").doc(sellerId), {
      ...publicProfile(sellerId, seller),
      reputation: newTotal / newCount,
      reviewCount: newCount,
    }, {merge: true});
  });
  return {created: true};
});
