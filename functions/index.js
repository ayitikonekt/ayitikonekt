const {setGlobalOptions} = require("firebase-functions/v2");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");

initializeApp();
setGlobalOptions({maxInstances: 20});

const db = getFirestore();

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

exports.toggleFavorite = onCall(async (request) => {
  const uid = authenticatedUid(request);
  const productId = requiredString(request.data?.productId, "productId", 160);
  const add = request.data?.add;
  if (typeof add !== "boolean") {
    throw new HttpsError("invalid-argument", "Invalid favorite state.");
  }

  const productRef = db.collection("products").doc(productId);
  const favoriteRef = db.collection("users").doc(uid).collection("favorites").doc(productId);
  const actorRef = db.collection("users").doc(uid);

  return db.runTransaction(async (transaction) => {
    const [productSnapshot, favoriteSnapshot, actorSnapshot] = await Promise.all([
      transaction.get(productRef),
      transaction.get(favoriteRef),
      transaction.get(actorRef),
    ]);
    if (!productSnapshot.exists) {
      throw new HttpsError("not-found", "Product is not available.");
    }

    const product = productSnapshot.data();
    const currentCount = Number(product.favorites || 0);
    if (favoriteSnapshot.exists === add) return {favoriteCount: currentCount};

    const nextCount = add ? currentCount + 1 : Math.max(0, currentCount - 1);
    if (add) {
      transaction.set(favoriteRef, {productId, createdAt: FieldValue.serverTimestamp()});
    } else {
      transaction.delete(favoriteRef);
    }
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

exports.recordProductView = onCall(async (request) => {
  const uid = authenticatedUid(request);
  const productId = requiredString(request.data?.productId, "productId", 160);
  const productRef = db.collection("products").doc(productId);
  const eventRef = productRef.collection("viewEvents").doc(uid);

  return db.runTransaction(async (transaction) => {
    const [productSnapshot, eventSnapshot] = await Promise.all([
      transaction.get(productRef), transaction.get(eventRef),
    ]);
    if (!productSnapshot.exists) throw new HttpsError("not-found", "Product not found.");
    const currentCount = Number(productSnapshot.data().views || 0);
    const lastViewedAt = eventSnapshot.data()?.viewedAt;
    if (lastViewedAt instanceof Timestamp && Date.now() - lastViewedAt.toMillis() < 3600000) {
      return {viewCount: currentCount};
    }
    transaction.set(eventRef, {viewerId: uid, viewedAt: FieldValue.serverTimestamp()});
    transaction.update(productRef, {views: currentCount + 1});
    return {viewCount: currentCount + 1};
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
