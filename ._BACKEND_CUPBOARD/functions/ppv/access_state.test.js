const test = require("node:test");
const assert = require("node:assert/strict");

const { getCanonicalPpvAccessState } = require("./access_state");

function makeDocSnapshot(id, data) {
  return {
    id,
    exists: data !== undefined,
    data: () => data,
    ref: { id },
  };
}

function makeQuerySnapshot(docs) {
  return {
    empty: docs.length === 0,
    docs: docs.map(({ id, data }) => makeDocSnapshot(id, data)),
  };
}

class FakeQuery {
  constructor(db, path, filters = [], limitCount = null) {
    this.db = db;
    this.path = path;
    this.filters = filters;
    this.limitCount = limitCount;
  }

  where(field, op, value) {
    assert.equal(op, "==");
    return new FakeQuery(
      this.db,
      this.path,
      [...this.filters, [field, value]],
      this.limitCount,
    );
  }

  limit(count) {
    return new FakeQuery(this.db, this.path, this.filters, count);
  }

  async get() {
    let docs = this.db._getCollectionDocs(this.path);
    docs = docs.filter(({ data }) =>
      this.filters.every(([field, value]) => data?.[field] === value),
    );
    if (this.limitCount !== null) {
      docs = docs.slice(0, this.limitCount);
    }
    return makeQuerySnapshot(docs);
  }
}

class FakeDocumentReference {
  constructor(db, path, id) {
    this.db = db;
    this.path = path;
    this.id = id;
    this.ref = this;
  }

  async get() {
    return makeDocSnapshot(this.id, this.db._getDocument(this.path, this.id));
  }

  collection(name) {
    return new FakeCollectionReference(
      this.db,
      `${this.path}/${this.id}/${name}`,
    );
  }
}

class FakeCollectionReference {
  constructor(db, path) {
    this.db = db;
    this.path = path;
  }

  doc(id) {
    return new FakeDocumentReference(this.db, this.path, id);
  }

  where(field, op, value) {
    return new FakeQuery(this.db, this.path).where(field, op, value);
  }
}

class FakeDb {
  constructor(seed = {}) {
    this.seed = seed;
  }

  collection(path) {
    return new FakeCollectionReference(this, path);
  }

  _getCollectionDocs(path) {
    const collection = this.seed[path] || {};
    return Object.entries(collection).map(([id, data]) => ({ id, data }));
  }

  _getDocument(path, id) {
    return this.seed[path]?.[id];
  }
}

test("returns active access from an authoritative canonical purchase record", async () => {
  const db = new FakeDb({
    ppv_events: {
      canonical_evt: { eventId: "legacy_evt" },
    },
    ppv_purchases: {
      user_123_canonical_evt: {
        userId: "user_123",
        ppvId: "canonical_evt",
        status: "completed",
        accessGranted: true,
        updatedAt: "2026-04-16T00:00:00.000Z",
      },
    },
  });

  const result = await getCanonicalPpvAccessState({
    db,
    userId: "user_123",
    eventId: "legacy_evt",
  });

  assert.equal(result.hasAccess, true);
  assert.equal(result.reason, "active");
  assert.equal(result.purchaseId, "user_123_canonical_evt");
});

test("returns active access from a canonical checkout session before legacy ledgers", async () => {
  const db = new FakeDb({
    ppv_events: {
      canonical_evt: { eventId: "legacy_evt" },
    },
    ppv_checkout_sessions: {
      legacy_pi_pi_123: {
        userId: "user_123",
        ppvId: "canonical_evt",
        tierId: 5,
        tierName: "FULL SHOW",
        tierKey: "FULL SHOW",
        status: "complete",
        accessGranted: true,
        completedAt: "2026-04-16T03:00:00.000Z",
      },
    },
    ppv_purchases: {
      user_123_canonical_evt: {
        userId: "user_123",
        ppvId: "canonical_evt",
        status: "completed",
        accessGranted: true,
        tierId: 3,
        updatedAt: "2026-04-16T01:00:00.000Z",
      },
    },
  });

  const result = await getCanonicalPpvAccessState({
    db,
    userId: "user_123",
    eventId: "legacy_evt",
  });

  assert.equal(result.hasAccess, true);
  assert.equal(result.reason, "active");
  assert.equal(result.purchaseId, "legacy_pi_pi_123");
  assert.equal(result.tierId, 5);
  assert.equal(result.tierName, "FULL SHOW");
});

test("refunded canonical checkout session blocks legacy purchase fallback", async () => {
  const db = new FakeDb({
    ppv_checkout_sessions: {
      legacy_pi_pi_456: {
        userId: "user_123",
        ppvId: "evt_blocked",
        status: "refunded",
        paymentStatus: "refunded",
        updatedAt: "2026-04-16T05:00:00.000Z",
      },
    },
    ppv_purchases: {
      user_123_evt_blocked: {
        userId: "user_123",
        ppvId: "evt_blocked",
        status: "completed",
        accessGranted: true,
        updatedAt: "2026-04-16T01:00:00.000Z",
      },
    },
  });

  const result = await getCanonicalPpvAccessState({
    db,
    userId: "user_123",
    eventId: "evt_blocked",
  });

  assert.equal(result.hasAccess, false);
  assert.equal(result.hasAny, true);
  assert.equal(result.reason, "refunded");
  assert.equal(result.purchaseId, "legacy_pi_pi_456");
});

test("refunded purchase state blocks stale access fallbacks", async () => {
  const db = new FakeDb({
    ppv_purchases: {
      user_123_evt_refunded: {
        userId: "user_123",
        ppvId: "evt_refunded",
        status: "refunded",
        updatedAt: "2026-04-16T01:00:00.000Z",
      },
    },
    ppv_access: {
      user_123_evt_refunded: {
        userId: "user_123",
        eventId: "evt_refunded",
        isActive: true,
        grantedAt: "2026-04-16T00:00:00.000Z",
      },
    },
  });

  const result = await getCanonicalPpvAccessState({
    db,
    userId: "user_123",
    eventId: "evt_refunded",
  });

  assert.equal(result.hasAccess, false);
  assert.equal(result.hasAny, true);
  assert.equal(result.reason, "refunded");
  assert.equal(result.purchaseId, "user_123_evt_refunded");
});

test("falls back to access records when no authoritative purchase exists", async () => {
  const db = new FakeDb({
    ppv_purchases: {
      user_123_evt_access_only: {
        userId: "user_123",
        ppvId: "evt_access_only",
        note: "legacy non-authoritative record",
      },
    },
    "users/user_123/ppv_access": {
      evt_access_only: {
        userId: "user_123",
        eventId: "evt_access_only",
        isActive: true,
        grantedAt: "2026-04-16T02:00:00.000Z",
      },
    },
  });

  const result = await getCanonicalPpvAccessState({
    db,
    userId: "user_123",
    eventId: "evt_access_only",
  });

  assert.equal(result.hasAccess, true);
  assert.equal(result.reason, "active");
  assert.equal(result.purchaseId, "evt_access_only");
});
