CREATE TABLE IF NOT EXISTS identity_profiles (
    identity_id TEXT PRIMARY KEY,
    role TEXT NOT NULL,
    display_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ppv_purchases (
    purchase_id TEXT PRIMARY KEY,
    ppv_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    price_cents BIGINT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ppv_purchases_user_ppv_created_at
    ON ppv_purchases (user_id, ppv_id, created_at DESC);

CREATE TABLE IF NOT EXISTS ppv_access_grants (
    ppv_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    access_status TEXT NOT NULL,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (ppv_id, user_id)
);

CREATE TABLE IF NOT EXISTS ppv_replays (
    event_id TEXT PRIMARY KEY,
    replay_url TEXT NOT NULL,
    expires_in_hours INTEGER NOT NULL,
    status TEXT NOT NULL,
    ready_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ppv_settlements (
    event_id TEXT PRIMARY KEY,
    gross_cents BIGINT NOT NULL,
    fees_cents BIGINT NOT NULL,
    net_cents BIGINT NOT NULL,
    fee_bps INTEGER NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS evidence_records (
    item_id TEXT PRIMARY KEY,
    source TEXT NOT NULL,
    content_type TEXT NOT NULL,
    notes TEXT NOT NULL DEFAULT '',
    digest TEXT NOT NULL,
    status TEXT NOT NULL,
    stored_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_evidence_records_source_stored_at
    ON evidence_records (source, stored_at DESC);
