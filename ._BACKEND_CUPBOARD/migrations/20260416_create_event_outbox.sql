CREATE TABLE IF NOT EXISTS event_outbox (
    id BIGSERIAL PRIMARY KEY,
    stream TEXT NOT NULL,
    event_type TEXT NOT NULL,
    source TEXT NOT NULL,
    subject TEXT,
    payload JSONB NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'pending',
    occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_event_outbox_status_created_at
    ON event_outbox (status, created_at);

CREATE INDEX IF NOT EXISTS idx_event_outbox_stream_created_at
    ON event_outbox (stream, created_at);
