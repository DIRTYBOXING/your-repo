-- migrations/20260411_create_posts_and_follows.sql
-- DFC Media Pipeline: posts (with media processing state) and follows tables

-- ─── Posts ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS posts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       TEXT NOT NULL,
  content       TEXT,
  media_key     TEXT,                      -- S3 key in uploads/originals/
  media_status  TEXT NOT NULL DEFAULT 'none',
                                           -- none | pending | processing | ready | failed
  og_image_url  TEXT,                      -- public CDN URL of the 1200x630 OG image
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at    TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_posts_user_id   ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created   ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_media_key ON posts(media_key);

-- Keep updated_at current on every write
CREATE OR REPLACE FUNCTION posts_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_posts_updated_at ON posts;
CREATE TRIGGER trg_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION posts_set_updated_at();

-- ─── Follows ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS follows (
  follower_id   TEXT NOT NULL,
  followee_id   TEXT NOT NULL,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT now(),
  PRIMARY KEY (follower_id, followee_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_followee ON follows(followee_id);
