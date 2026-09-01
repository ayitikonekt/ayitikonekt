const {HttpsError} = require("firebase-functions/v2/https");
const {Timestamp} = require("firebase-admin/firestore");

const RATE_WINDOW_MS = 60 * 60 * 1000;
const MAX_FAVORITE_CHANGES_PER_HOUR = 40;
const MAX_UNIQUE_VIEWS_PER_HOUR = 120;

function safeCounter(value, field) {
  if (!Number.isSafeInteger(value) || value < 0) {
    throw new HttpsError("failed-precondition", `Invalid ${field} counter.`);
  }
  return value;
}

function nextRateLimit(snapshot, maximum, now) {
  const data = snapshot.data() || {};
  const windowStartedAt = data.windowStartedAt;
  const activeWindow = windowStartedAt instanceof Timestamp &&
    now.toMillis() - windowStartedAt.toMillis() < RATE_WINDOW_MS;
  const count = activeWindow && Number.isSafeInteger(data.count) ? data.count : 0;
  if (count >= maximum) {
    throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");
  }
  return {
    count: count + 1,
    windowStartedAt: activeWindow ? windowStartedAt : now,
    lastRequestAt: now,
  };
}

function shouldCountProductView(product, uid, lastViewedAt, now) {
  if (String(product.sellerId || "") === uid) return false;
  return !(lastViewedAt instanceof Timestamp &&
    now.toMillis() - lastViewedAt.toMillis() < RATE_WINDOW_MS);
}

module.exports = {
  MAX_FAVORITE_CHANGES_PER_HOUR,
  MAX_UNIQUE_VIEWS_PER_HOUR,
  nextRateLimit,
  safeCounter,
  shouldCountProductView,
};
