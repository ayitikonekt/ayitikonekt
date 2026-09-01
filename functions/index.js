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
const MAX_CONTACT_REQUESTS_PER_HOUR = 30;
const MAX_REVIEW_REPORTS_PER_HOUR = 10;

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

exports.registerProductInteraction = onCall(monitoredCallable, async (request) => {
  const uid = authenticatedUid(request);
  const productId = requiredString(request.data?.productId, "productId", 160);
  const channel = requiredString(request.data?.channel, "channel", 20);
  if (!["phone", "email", "whatsapp"].includes(channel)) {
    throw new HttpsError("invalid-argument", "Invalid contact channel.");
  }

  const productRef = db.collection("products").doc(productId);
  const actorRef = db.collection("users").doc(uid);
  const interactionRef = db.collection("reviewInteractions").doc(`${productId}_${uid}`);
  const rateLimitRef = actorRef.collection("securityLimits").doc("productContacts");

  return db.runTransaction(async (transaction) => {
    const now = Timestamp.now();
    const [productSnapshot, actorSnapshot, interactionSnapshot, rateLimitSnapshot] =
      await Promise.all([
        transaction.get(productRef),
        transaction.get(actorRef),
        transaction.get(interactionRef),
        transaction.get(rateLimitRef),
      ]);
    if (!productSnapshot.exists) throw new HttpsError("not-found", "Product not found.");
    if (!actorSnapshot.exists) {
      throw new HttpsError("failed-precondition", "User profile is required.");
    }
    const product = productSnapshot.data();
    const sellerId = String(product.sellerId || "");
    if (!sellerId || sellerId === uid) {
      throw new HttpsError("permission-denied", "You cannot contact your own listing.");
    }

    const rateLimit = nextRateLimit(
      rateLimitSnapshot,
      MAX_CONTACT_REQUESTS_PER_HOUR,
      now,
    );
    transaction.set(rateLimitRef, rateLimit);
    if (!interactionSnapshot.exists) {
      transaction.set(interactionRef, {
        productId,
        sellerId,
        reviewerId: uid,
        type: "contact_request",
        channels: [channel],
        status: "eligible",
        createdAt: FieldValue.serverTimestamp(),
        lastContactAt: FieldValue.serverTimestamp(),
        reviewedAt: null,
      });
    } else {
      const interaction = interactionSnapshot.data();
      if (interaction.productId !== productId || interaction.sellerId !== sellerId ||
          interaction.reviewerId !== uid) {
        throw new HttpsError("failed-precondition", "Invalid interaction.");
      }
      const channels = Array.isArray(interaction.channels) ? interaction.channels : [];
      transaction.update(interactionRef, {
        channels: [...new Set([...channels, channel])].slice(0, 3),
        lastContactAt: FieldValue.serverTimestamp(),
      });
    }
    return {operationId: interactionRef.id, eligible: !interactionSnapshot.data()?.reviewedAt};
  });
});

exports.createReview = onCall(monitoredCallable, async (request) => {
  const uid = authenticatedUid(request);
  const productId = requiredString(request.data?.productId, "productId", 160);
  const operationId = requiredString(request.data?.operationId, "operationId", 330);
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
  const expectedOperationId = `${productId}_${uid}`;
  if (operationId !== expectedOperationId) {
    throw new HttpsError("permission-denied", "Invalid review operation.");
  }
  const interactionRef = db.collection("reviewInteractions").doc(operationId);
  const reviewRef = db.collection("reviews").doc(operationId);

  await db.runTransaction(async (transaction) => {
    const [productSnapshot, reviewerSnapshot, interactionSnapshot, existingReview] = await Promise.all([
      transaction.get(productRef), transaction.get(reviewerRef),
      transaction.get(interactionRef), transaction.get(reviewRef),
    ]);
    if (!productSnapshot.exists) throw new HttpsError("not-found", "Product not found.");
    if (!reviewerSnapshot.exists) {
      throw new HttpsError("failed-precondition", "Reviewer profile is required.");
    }
    if (existingReview.exists) throw new HttpsError("already-exists", "Review already exists.");
    const product = productSnapshot.data();
    const sellerId = String(product.sellerId || "");
    if (!sellerId || sellerId === uid) throw new HttpsError("permission-denied", "Invalid seller.");
    if (!interactionSnapshot.exists) {
      throw new HttpsError("failed-precondition", "A valid interaction is required.");
    }
    const interaction = interactionSnapshot.data();
    if (interaction.productId !== productId || interaction.sellerId !== sellerId ||
        interaction.reviewerId !== uid || interaction.status !== "eligible" ||
        interaction.reviewedAt != null) {
      throw new HttpsError("failed-precondition", "This interaction cannot be reviewed.");
    }
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
      operationId,
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
      status: "published",
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
    transaction.update(interactionRef, {
      status: "reviewed",
      reviewedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(
      db.collection("users").doc(sellerId).collection("notifications").doc(`review_${operationId}`),
      {
        type: "review",
        title: "Nueva reseña",
        message: `${reviewer.name || "Alguien"} calificó tu publicación.`,
        productId,
        actorId: uid,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      },
    );
  });
  return {created: true};
});

exports.reportReview = onCall(monitoredCallable, async (request) => {
  const uid = authenticatedUid(request);
  const reviewId = requiredString(request.data?.reviewId, "reviewId", 330);
  const reason = requiredString(request.data?.reason, "reason", 500);
  const reviewRef = db.collection("reviews").doc(reviewId);
  const reporterRef = db.collection("users").doc(uid);
  const reportRef = db.collection("reviewReports").doc(`${reviewId}_${uid}`);
  const rateLimitRef = reporterRef.collection("securityLimits").doc("reviewReports");

  return db.runTransaction(async (transaction) => {
    const now = Timestamp.now();
    const [reviewSnapshot, reporterSnapshot, reportSnapshot, rateLimitSnapshot] =
      await Promise.all([
        transaction.get(reviewRef), transaction.get(reporterRef),
        transaction.get(reportRef), transaction.get(rateLimitRef),
      ]);
    if (!reviewSnapshot.exists) throw new HttpsError("not-found", "Review not found.");
    if (!reporterSnapshot.exists) {
      throw new HttpsError("failed-precondition", "User profile is required.");
    }
    if (reportSnapshot.exists) {
      throw new HttpsError("already-exists", "Review already reported.");
    }
    const review = reviewSnapshot.data();
    if (review.reviewerId === uid) {
      throw new HttpsError("permission-denied", "You cannot report your own review.");
    }
    transaction.set(rateLimitRef, nextRateLimit(
      rateLimitSnapshot,
      MAX_REVIEW_REPORTS_PER_HOUR,
      now,
    ));
    transaction.set(reportRef, {
      reviewId,
      reporterId: uid,
      sellerId: String(review.sellerId || ""),
      reviewerId: String(review.reviewerId || ""),
      reason,
      status: "open",
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.update(reviewRef, {reported: true});
    return {reported: true};
  });
});

exports.moderateReview = onCall(async (request) => {
  const uid = authenticatedUid(request);
  if (request.auth?.token?.admin !== true && request.auth?.token?.moderator !== true) {
    throw new HttpsError("permission-denied", "Moderator access required.");
  }
  const reviewId = requiredString(request.data?.reviewId, "reviewId", 330);
  const action = requiredString(request.data?.action, "action", 20);
  if (!["hide", "restore"].includes(action)) {
    throw new HttpsError("invalid-argument", "Invalid moderation action.");
  }
  const reviewRef = db.collection("reviews").doc(reviewId);
  const auditRef = db.collection("moderationAudit").doc();

  await db.runTransaction(async (transaction) => {
    const reviewSnapshot = await transaction.get(reviewRef);
    if (!reviewSnapshot.exists) throw new HttpsError("not-found", "Review not found.");
    const review = reviewSnapshot.data();
    const currentStatus = String(review.status || "published");
    const nextStatus = action === "hide" ? "hidden" : "published";
    if (currentStatus === nextStatus) return;
    const sellerId = String(review.sellerId || "");
    const sellerRef = db.collection("users").doc(sellerId);
    const sellerSnapshot = await transaction.get(sellerRef);
    if (!sellerSnapshot.exists) throw new HttpsError("not-found", "Seller not found.");
    const seller = sellerSnapshot.data();
    const rating = Number(review.rating);
    const count = Number(seller.reviewCount || 0);
    const total = Number(seller.reviewRatingTotal || 0);
    const delta = nextStatus === "hidden" ? -1 : 1;
    const nextCount = count + delta;
    const nextTotal = total + (delta * rating);
    if (!Number.isInteger(rating) || rating < 1 || rating > 5 ||
        nextCount < 0 || nextTotal < 0) {
      throw new HttpsError("failed-precondition", "Invalid reputation state.");
    }
    const reputation = nextCount === 0 ? 5 : nextTotal / nextCount;
    transaction.update(reviewRef, {
      status: nextStatus,
      moderatedAt: FieldValue.serverTimestamp(),
      moderatedBy: uid,
    });
    transaction.update(sellerRef, {
      reputation,
      reviewCount: nextCount,
      reviewRatingTotal: nextTotal,
    });
    transaction.set(db.collection("publicProfiles").doc(sellerId), {
      reputation,
      reviewCount: nextCount,
    }, {merge: true});
    transaction.set(auditRef, {
      type: "review_moderation",
      reviewId,
      action,
      moderatorId: uid,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return {moderated: true};
});

// Operación administrativa de una sola vez para conservar reseñas anteriores.
exports.migrateLegacyReviews = onCall(async (request) => {
  authenticatedUid(request);
  if (request.auth?.token?.admin !== true) {
    throw new HttpsError("permission-denied", "Administrator access required.");
  }
  const snapshot = await db.collection("reviews").limit(400).get();
  const batch = db.batch();
  let migrated = 0;
  for (const document of snapshot.docs) {
    const data = document.data();
    const changes = {};
    if (typeof data.status !== "string") changes.status = "published";
    if (typeof data.operationId !== "string") changes.operationId = document.id;
    if (typeof data.reported !== "boolean") changes.reported = false;
    if (Object.keys(changes).length > 0) {
      batch.update(document.ref, changes);
      migrated += 1;
    }
  }
  if (migrated > 0) await batch.commit();
  return {migrated, remainingPossible: snapshot.size === 400};
});
