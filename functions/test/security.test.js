const test = require("node:test");
const assert = require("node:assert/strict");
const {Timestamp} = require("firebase-admin/firestore");

const {
  nextRateLimit,
  safeCounter,
  shouldCountProductView,
} = require("../security");

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
