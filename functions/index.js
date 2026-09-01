const {setGlobalOptions} = require("firebase-functions/v2");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentDeleted, onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onObjectFinalized} = require("firebase-functions/v2/storage");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {
  MAX_FAVORITE_CHANGES_PER_HOUR,
  MAX_UNIQUE_VIEWS_PER_HOUR,
  nextRateLimit,
  safeCounter,
  shouldCountProductView,
} = require("./security");
const {isAllowedImage} = require("./image_security");

initializeApp();
setGlobalOptions({maxInstances: 20});

const db = getFirestore();
const monitoredCallable = {enforceAppCheck: false};
const MAX_CONTACT_REQUESTS_PER_HOUR = 30;
const MAX_REVIEW_REPORTS_PER_HOUR = 10;
const MAX_MESSAGES_PER_HOUR = 120;
const FIREBASE_STORAGE_BUCKET = "ayitikonekt.firebasestorage.app";
const MAX_SUPPORT_TICKETS_PER_HOUR = 10;
const SUPPORT_CATEGORIES = new Set([
  "supportAccount", "supportListings", "supportSafety", "supportReviews",
  "supportTechnical", "supportOther",
]);
const SUPPORT_STATUSES = new Set([
  "received", "reviewing", "waiting", "resolved", "closed",
]);

async function firstBytes(file, maximum = 32) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    file.createReadStream({start: 0, end: maximum - 1})
      .on("data", (chunk) => chunks.push(chunk))
      .on("end", () => resolve(Buffer.concat(chunks)))
      .on("error", reject);
  });
}

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

function requiredIdentifier(value, field, maxLength = 330) {
  const identifier = requiredString(value, field, maxLength);
  if (!/^[A-Za-z0-9_-]+$/.test(identifier)) {
    throw new HttpsError("invalid-argument", `Invalid ${field}.`);
  }
  return identifier;
}

function conversationIdFor(productId, firstUid, secondUid) {
  return `${productId}_${[firstUid, secondUid].sort().join("_")}`;
}

function hasRole(request, role) {
  return request.auth?.token?.[role] === true;
}

function requireSupportStaff(request) {
  const uid = authenticatedUid(request);
  if (!hasRole(request, "support") && !hasRole(request, "admin")) {
    throw new HttpsError("permission-denied", "Support access required.");
  }
  return uid;
}

async function verifiedSupportAttachments(uid, ticketId, rawPaths) {
  if (!Array.isArray(rawPaths) || rawPaths.length > 3) {
    throw new HttpsError("invalid-argument", "Invalid support attachments.");
  }
  const bucket = getStorage().bucket();
  const prefix = `support_tickets/${uid}/${ticketId}/`;
  const verified = [];
  for (const rawPath of rawPaths) {
    const objectPath = requiredString(rawPath, "attachmentPath", 700);
    if (!objectPath.startsWith(prefix) || objectPath.slice(prefix.length).includes("/")) {
      throw new HttpsError("permission-denied", "Invalid attachment owner.");
    }
    const [metadata] = await bucket.file(objectPath).getMetadata().catch(() => {
      throw new HttpsError("failed-precondition", "Attachment does not exist.");
    });
    const size = Number(metadata.size || 0);
    const contentType = String(metadata.contentType || "");
    if (!/^image\/(jpeg|png|webp)$/.test(contentType) ||
        !Number.isSafeInteger(size) || size < 1 || size > 5 * 1024 * 1024) {
      throw new HttpsError("invalid-argument", "Invalid support attachment.");
    }
    verified.push(objectPath);
  }
  return verified;
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

exports.validateProductImage = onObjectFinalized({
  bucket: FIREBASE_STORAGE_BUCKET,
}, async (event) => {
  const object = event.data;
  const objectName = String(object.name || "");
  const match = objectName.match(
    /^products\/([A-Za-z0-9_-]{1,128})\/([A-Za-z0-9_-]{1,160})\/([A-Za-z0-9_.-]{1,160})$/,
  );
  if (!match) return;
  const [, ownerId, productId] = match;
  const bucket = getStorage().bucket(object.bucket);
  const file = bucket.file(objectName);
  const productSnapshot = await db.collection("products").doc(productId).get();
  const declaredType = String(object.contentType || "");
  const size = Number(object.size || 0);
  let validSignature = false;
  try {
    validSignature = isAllowedImage(await firstBytes(file), declaredType);
  } catch (_) {
    validSignature = false;
  }
  if (!productSnapshot.exists || productSnapshot.data().sellerId !== ownerId ||
      !Number.isSafeInteger(size) || size < 1 || size > 8 * 1024 * 1024 ||
      !validSignature) {
    await file.delete({ignoreNotFound: true});
    return;
  }

  const [files] = await bucket.getFiles({prefix: `products/${ownerId}/${productId}/`});
  const productFiles = files
    .filter((candidate) => candidate.name.split("/").length === 4)
    .sort((left, right) => left.name.localeCompare(right.name));
  const excess = productFiles.slice(8);
  if (excess.length > 0) {
    await Promise.all(excess.map((candidate) => candidate.delete({ignoreNotFound: true})));
  }
});

exports.cleanupDeletedProductImages = onDocumentDeleted("products/{productId}", async (event) => {
  const product = event.data?.data() || {};
  const ownerId = String(product.sellerId || "");
  const productId = String(event.params.productId || "");
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(ownerId) ||
      !/^[A-Za-z0-9_-]{1,160}$/.test(productId)) return;
  const bucket = getStorage().bucket(FIREBASE_STORAGE_BUCKET);
  await bucket.deleteFiles({
    prefix: `products/${ownerId}/${productId}/`,
    force: true,
  });
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

exports.createConversation = onCall(monitoredCallable, async (request) => {
  const uid = authenticatedUid(request);
  const productId = requiredIdentifier(request.data?.productId, "productId", 160);
  const otherUserId = requiredIdentifier(request.data?.otherUserId, "otherUserId", 128);
  if (otherUserId === uid) {
    throw new HttpsError("invalid-argument", "Participants must be different.");
  }
  const productRef = db.collection("products").doc(productId);
  const otherUserRef = db.collection("users").doc(otherUserId);
  const conversationId = conversationIdFor(productId, uid, otherUserId);
  const conversationRef = db.collection("conversations").doc(conversationId);

  return db.runTransaction(async (transaction) => {
    const [productSnapshot, otherUserSnapshot, conversationSnapshot] = await Promise.all([
      transaction.get(productRef),
      transaction.get(otherUserRef),
      transaction.get(conversationRef),
    ]);
    if (!productSnapshot.exists) throw new HttpsError("not-found", "Product not found.");
    if (!otherUserSnapshot.exists) throw new HttpsError("not-found", "Participant not found.");
    const product = productSnapshot.data();
    const sellerId = String(product.sellerId || "");
    if (sellerId !== uid && sellerId !== otherUserId) {
      throw new HttpsError("permission-denied", "The seller must participate.");
    }
    if (!conversationSnapshot.exists) {
      transaction.set(conversationRef, {
        participantIds: [uid, otherUserId].sort(),
        productId,
        createdBy: uid,
        status: "active",
        lastMessage: "",
        lastMessageAt: null,
        lastSenderId: "",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      const participants = conversationSnapshot.data().participantIds;
      if (!Array.isArray(participants) || participants.length !== 2 ||
          !participants.includes(uid) || !participants.includes(otherUserId)) {
        throw new HttpsError("failed-precondition", "Invalid conversation.");
      }
    }
    return {conversationId};
  });
});

async function verifiedMessageAttachments(uid, conversationId, rawAttachments) {
  if (!Array.isArray(rawAttachments) || rawAttachments.length > 4) {
    throw new HttpsError("invalid-argument", "Invalid attachments.");
  }
  const prefix = `conversation_uploads/${uid}/${conversationId}/`;
  const allowedTypes = new Set([
    "image/jpeg", "image/png", "image/webp", "application/pdf",
  ]);
  return Promise.all(rawAttachments.map(async (rawPath) => {
    const storagePath = requiredString(rawPath, "attachment path", 700);
    if (!storagePath.startsWith(prefix) || storagePath.includes("..")) {
      throw new HttpsError("permission-denied", "Invalid attachment owner.");
    }
    const [metadata] = await getStorage().bucket().file(storagePath).getMetadata();
    const contentType = String(metadata.contentType || "");
    const size = Number(metadata.size || 0);
    if (!allowedTypes.has(contentType) || !Number.isSafeInteger(size) ||
        size < 1 || size > 8 * 1024 * 1024) {
      throw new HttpsError("invalid-argument", "Invalid attachment file.");
    }
    return {
      storagePath,
      contentType,
      size,
      name: storagePath.split("/").pop().slice(0, 160),
    };
  }));
}

exports.sendMessage = onCall(monitoredCallable, async (request) => {
  const uid = authenticatedUid(request);
  const conversationId = requiredIdentifier(
    request.data?.conversationId,
    "conversationId",
    700,
  );
  const text = typeof request.data?.text === "string" ? request.data.text.trim() : "";
  if (text.length > 2000) throw new HttpsError("invalid-argument", "Message is too long.");
  const attachments = await verifiedMessageAttachments(
    uid,
    conversationId,
    request.data?.attachments ?? [],
  );
  if (!text && attachments.length === 0) {
    throw new HttpsError("invalid-argument", "Message cannot be empty.");
  }

  const conversationRef = db.collection("conversations").doc(conversationId);
  const senderRef = db.collection("users").doc(uid);
  const rateLimitRef = senderRef.collection("securityLimits").doc("messages");
  const messageRef = conversationRef.collection("messages").doc();

  return db.runTransaction(async (transaction) => {
    const now = Timestamp.now();
    const [conversationSnapshot, senderSnapshot, rateLimitSnapshot] = await Promise.all([
      transaction.get(conversationRef),
      transaction.get(senderRef),
      transaction.get(rateLimitRef),
    ]);
    if (!conversationSnapshot.exists) {
      throw new HttpsError("not-found", "Conversation not found.");
    }
    if (!senderSnapshot.exists) {
      throw new HttpsError("failed-precondition", "Sender profile is required.");
    }
    const conversation = conversationSnapshot.data();
    const participants = conversation.participantIds;
    if (!Array.isArray(participants) || participants.length !== 2 ||
        new Set(participants).size !== 2 || !participants.includes(uid) ||
        conversation.status !== "active") {
      throw new HttpsError("permission-denied", "Invalid conversation participant.");
    }
    const previousRequest = rateLimitSnapshot.data()?.lastRequestAt;
    if (previousRequest instanceof Timestamp &&
        now.toMillis() - previousRequest.toMillis() < 750) {
      throw new HttpsError("resource-exhausted", "Messages are being sent too quickly.");
    }
    transaction.set(rateLimitRef, nextRateLimit(
      rateLimitSnapshot,
      MAX_MESSAGES_PER_HOUR,
      now,
    ));
    transaction.set(messageRef, {
      senderId: uid,
      text,
      attachments,
      type: attachments.length > 0 ? (text ? "mixed" : "attachment") : "text",
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.update(conversationRef, {
      lastMessage: text.substring(0, 240),
      lastMessageAt: FieldValue.serverTimestamp(),
      lastSenderId: uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    const recipientId = participants.find((participant) => participant !== uid);
    transaction.set(
      db.collection("users").doc(recipientId).collection("notifications").doc(`message_${messageRef.id}`),
      {
        type: "message",
        title: "Nuevo mensaje",
        message: text ? text.substring(0, 160) : "Recibiste un archivo adjunto.",
        conversationId,
        actorId: uid,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      },
    );
    return {messageId: messageRef.id};
  });
});

exports.getMessageAttachmentUrl = onCall(monitoredCallable, async (request) => {
  const uid = authenticatedUid(request);
  const conversationId = requiredIdentifier(
    request.data?.conversationId,
    "conversationId",
    700,
  );
  const messageId = requiredIdentifier(request.data?.messageId, "messageId", 128);
  const index = request.data?.index;
  if (!Number.isInteger(index) || index < 0 || index > 3) {
    throw new HttpsError("invalid-argument", "Invalid attachment index.");
  }
  const conversationRef = db.collection("conversations").doc(conversationId);
  const messageRef = conversationRef.collection("messages").doc(messageId);
  const [conversationSnapshot, messageSnapshot] = await Promise.all([
    conversationRef.get(), messageRef.get(),
  ]);
  if (!conversationSnapshot.exists || !messageSnapshot.exists) {
    throw new HttpsError("not-found", "Message not found.");
  }
  const participants = conversationSnapshot.data().participantIds;
  if (!Array.isArray(participants) || participants.length !== 2 ||
      !participants.includes(uid)) {
    throw new HttpsError("permission-denied", "Conversation access denied.");
  }
  const attachments = messageSnapshot.data().attachments;
  if (!Array.isArray(attachments) || !attachments[index]?.storagePath) {
    throw new HttpsError("not-found", "Attachment not found.");
  }
  const [url] = await getStorage().bucket().file(attachments[index].storagePath)
    .getSignedUrl({action: "read", expires: Date.now() + 15 * 60 * 1000});
  return {url, expiresInSeconds: 900};
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

exports.createSupportTicket = onCall(monitoredCallable, async (request) => {
  const uid = authenticatedUid(request);
  const ticketId = requiredIdentifier(request.data?.ticketId, "ticketId", 160);
  const category = requiredString(request.data?.category, "category", 40);
  const subject = requiredString(request.data?.subject, "subject", 100);
  const description = requiredString(request.data?.description, "description", 1200);
  const contact = requiredString(request.data?.contact, "contact", 254);
  if (!SUPPORT_CATEGORIES.has(category) || subject.length < 4 || description.length < 10) {
    throw new HttpsError("invalid-argument", "Invalid support request.");
  }

  const attachments = await verifiedSupportAttachments(
    uid,
    ticketId,
    request.data?.attachmentPaths || [],
  );
  const ticketRef = db.collection("supportTickets").doc(ticketId);
  const userRef = db.collection("users").doc(uid);
  const rateLimitRef = userRef.collection("securityLimits").doc("supportTickets");

  await db.runTransaction(async (transaction) => {
    const now = Timestamp.now();
    const [userSnapshot, ticketSnapshot, rateLimitSnapshot] = await Promise.all([
      transaction.get(userRef),
      transaction.get(ticketRef),
      transaction.get(rateLimitRef),
    ]);
    if (!userSnapshot.exists) {
      throw new HttpsError("failed-precondition", "User profile is required.");
    }
    if (ticketSnapshot.exists) {
      throw new HttpsError("already-exists", "Support ticket already exists.");
    }
    transaction.set(rateLimitRef, nextRateLimit(
      rateLimitSnapshot,
      MAX_SUPPORT_TICKETS_PER_HOUR,
      now,
    ));
    transaction.set(ticketRef, {
      userId: uid,
      category,
      subject,
      description,
      contact,
      attachments,
      status: "received",
      assignedTo: "",
      responseCount: 0,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return {ticketId};
});

exports.updateSupportTicket = onCall(async (request) => {
  const staffId = requireSupportStaff(request);
  const ticketId = requiredIdentifier(request.data?.ticketId, "ticketId", 160);
  const status = requiredString(request.data?.status, "status", 20);
  const note = requiredString(request.data?.note, "note", 2000);
  if (!SUPPORT_STATUSES.has(status)) {
    throw new HttpsError("invalid-argument", "Invalid support status.");
  }
  const ticketRef = db.collection("supportTickets").doc(ticketId);
  const responseRef = ticketRef.collection("responses").doc();
  const auditRef = db.collection("supportAudit").doc();

  await db.runTransaction(async (transaction) => {
    const ticketSnapshot = await transaction.get(ticketRef);
    if (!ticketSnapshot.exists) throw new HttpsError("not-found", "Ticket not found.");
    const ticket = ticketSnapshot.data();
    const previousStatus = String(ticket.status || "received");
    const responseCount = Number(ticket.responseCount || 0);
    if (!Number.isSafeInteger(responseCount) || responseCount < 0) {
      throw new HttpsError("failed-precondition", "Invalid ticket state.");
    }
    transaction.update(ticketRef, {
      status,
      assignedTo: staffId,
      responseCount: responseCount + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(responseRef, {
      ticketId,
      authorId: staffId,
      authorRole: hasRole(request, "admin") ? "admin" : "support",
      note,
      previousStatus,
      status,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.set(auditRef, {
      type: "support_intervention",
      ticketId,
      actorId: staffId,
      actorRole: hasRole(request, "admin") ? "admin" : "support",
      previousStatus,
      status,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return {updated: true};
});
