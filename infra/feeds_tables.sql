CREATE TABLE IF NOT EXISTS feeds_dedupe (
  hash TEXT PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS feeds_incoming (
  id BIGSERIAL PRIMARY KEY,
  source_id TEXT,
  external_id TEXT,
  title TEXT,
  body TEXT,
  published_at TIMESTAMPTZ,
  author TEXT,
  media_url TEXT,
  trusted BOOLEAN,
  trust_score NUMERIC,
  metadata JSONB,
  raw JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS feeds_moderation (
  id BIGSERIAL PRIMARY KEY,
  source_id TEXT,
  external_id TEXT,
  title TEXT,
  body TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);
