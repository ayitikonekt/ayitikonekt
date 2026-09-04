const {applicationDefault, initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {
  ADMINISTRATIVE_ROLES,
  nextAdministrativeClaims,
} = require("../admin_security");

async function main() {
  const [targetUid, role, confirmation] = process.argv.slice(2);
  if (!targetUid || !ADMINISTRATIVE_ROLES.has(role) || confirmation !== "--confirm") {
    throw new Error(
      "Usage: npm run admin:role -- <uid> <none|support|moderator|admin> --confirm",
    );
  }

  initializeApp({credential: applicationDefault(), projectId: "ayitikonekt"});
  const auth = getAuth();
  const target = await auth.getUser(targetUid);
  if (role !== "none" && target.email && !target.emailVerified) {
    throw new Error("The target email must be verified before assigning a role.");
  }

  const previousClaims = target.customClaims || {};
  const previousRoles = ["support", "moderator", "admin"]
    .filter((candidate) => previousClaims[candidate] === true);
  await auth.setCustomUserClaims(
    targetUid,
    nextAdministrativeClaims(previousClaims, role),
  );
  await auth.revokeRefreshTokens(targetUid);
  await getFirestore().collection("administrativeAudit").add({
    type: "role_change",
    actorId: "technical-owner-cli",
    actorRole: "iam-technical-owner",
    targetId: targetUid,
    previousRoles,
    newRole: role,
    reason: "Bootstrap or recovery by the technical owner",
    status: "completed",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  process.stdout.write(
    `Role ${role} assigned to ${targetUid}. Existing sessions were revoked.\n`,
  );
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
});
