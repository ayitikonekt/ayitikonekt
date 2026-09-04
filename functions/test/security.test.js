const test = require("node:test");
const assert = require("node:assert/strict");
const {Timestamp} = require("firebase-admin/firestore");

const {
  nextRateLimit,
  safeCounter,
  shouldCountProductView,
} = require("../security");
const {detectedImageType, isAllowedImage} = require("../image_security");
const {
  hasMfaClaim,
  hasRecentAuthentication,
  nextAdministrativeClaims,
} = require("../admin_security");

function snapshot(data = {}) {
  return {data: () => data};
}

test("solo acepta contadores enteros seguros y no negativos", () => {
  assert.equal(safeCounter(0, "view"), 0);
  assert.equal(safeCounter(12, "favorite"), 12);
  for (const invalid of [-1, 1.5, "2", Number.MAX_SAFE_INTEGER + 1]) {
    assert.throws(() => safeCounter(invalid, "view"), {code: "failed-precondition"});
  }
});

test("bloquea una cuenta cuando alcanza el límite", () => {
  const now = Timestamp.fromMillis(2_000_000);
  const current = snapshot({count: 40, windowStartedAt: Timestamp.fromMillis(1_000_000)});
  assert.throws(() => nextRateLimit(current, 40, now), {code: "resource-exhausted"});
});

test("reinicia el límite después de una hora", () => {
  const now = Timestamp.fromMillis(4_700_000);
  const result = nextRateLimit(
    snapshot({count: 40, windowStartedAt: Timestamp.fromMillis(1_000_000)}),
    40,
    now,
  );
  assert.equal(result.count, 1);
  assert.equal(result.windowStartedAt.toMillis(), now.toMillis());
});

test("el vendedor no suma vistas y una repetición dentro de una hora tampoco", () => {
  const now = Timestamp.fromMillis(5_000_000);
  assert.equal(shouldCountProductView({sellerId: "alice"}, "alice", null, now), false);
  assert.equal(
    shouldCountProductView(
      {sellerId: "bob"},
      "alice",
      Timestamp.fromMillis(4_000_000),
      now,
    ),
    false,
  );
  assert.equal(
    shouldCountProductView(
      {sellerId: "bob"},
      "alice",
      Timestamp.fromMillis(1_000_000),
      now,
    ),
    true,
  );
});

test("detecta la firma binaria real de las imagenes", () => {
  const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0]);
  const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const webp = Buffer.from("RIFF0000WEBP", "ascii");
  assert.equal(detectedImageType(jpeg), "image/jpeg");
  assert.equal(detectedImageType(png), "image/png");
  assert.equal(detectedImageType(webp), "image/webp");
});

test("rechaza archivos disfrazados y tipos declarados incorrectamente", () => {
  const script = Buffer.from("<script>alert(1)</script>");
  const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0]);
  assert.equal(isAllowedImage(script, "image/jpeg"), false);
  assert.equal(isAllowedImage(jpeg, "image/png"), false);
  assert.equal(isAllowedImage(jpeg, "image/jpeg"), true);
  assert.equal(isAllowedImage(jpeg, "image/svg+xml"), false);
});

test("exige una segunda fase real para operaciones administrativas", () => {
  assert.equal(hasMfaClaim({}), false);
  assert.equal(hasMfaClaim({firebase: {sign_in_second_factor: ""}}), false);
  assert.equal(hasMfaClaim({firebase: {sign_in_second_factor: "phone"}}), true);
});

test("exige autenticacion administrativa reciente", () => {
  assert.equal(hasRecentAuthentication({auth_time: 500}, 1000), true);
  assert.equal(hasRecentAuthentication({auth_time: 99}, 1000), false);
  assert.equal(hasRecentAuthentication({auth_time: 1001}, 1000), false);
  assert.equal(hasRecentAuthentication({}, 1000), false);
});

test("los roles administrativos son exclusivos y preservan otros claims", () => {
  assert.deepEqual(
    nextAdministrativeClaims({support: true, plan: "pro"}, "moderator"),
    {plan: "pro", moderator: true},
  );
  assert.deepEqual(
    nextAdministrativeClaims({admin: true, plan: "pro"}, "none"),
    {plan: "pro"},
  );
  assert.throws(() => nextAdministrativeClaims({}, "owner"));
});
