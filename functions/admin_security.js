const ADMINISTRATIVE_ROLES = new Set(["none", "support", "moderator", "admin"]);

function hasMfaClaim(token) {
  return typeof token?.firebase?.sign_in_second_factor === "string" &&
    token.firebase.sign_in_second_factor.length > 0;
}

function hasRecentAuthentication(token, nowSeconds, maximumAgeSeconds = 900) {
  const authenticatedAt = Number(token?.auth_time || 0);
  const age = nowSeconds - authenticatedAt;
  return Number.isSafeInteger(authenticatedAt) && authenticatedAt > 0 &&
    Number.isSafeInteger(age) && age >= 0 && age <= maximumAgeSeconds;
}

function nextAdministrativeClaims(currentClaims, role) {
  if (!ADMINISTRATIVE_ROLES.has(role)) throw new TypeError("Invalid administrative role.");
  const claims = {...(currentClaims || {})};
  delete claims.admin;
  delete claims.moderator;
  delete claims.support;
  if (role !== "none") claims[role] = true;
  return claims;
}

module.exports = {
  ADMINISTRATIVE_ROLES,
  hasMfaClaim,
  hasRecentAuthentication,
  nextAdministrativeClaims,
};
