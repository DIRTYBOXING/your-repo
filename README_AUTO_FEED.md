# Data Fight Central Auto-Feed Pipeline

## Overview

This pipeline fetches, deduplicates, normalizes, and queues trusted fight content from RSS and YouTube sources for Data Fight Central. It is production-grade, admin-operable, and designed for extensibility and operational clarity.

## Key Files

- `src/feeds/intake.ts`: Main intake service (fetch, dedupe, normalize, enqueue)
- `config/auto_feed_sources.json`: Source config (trusted RSS/YouTube channels)
- `infra/feeds_tables.sql`: Postgres schema for dedupe, incoming, moderation
- `infra/auto_feed_scheduler.yaml`: Cloud Scheduler job (optional)
- `scripts/auto_feed_cron.sh`: Cron script for local/VM automation

## How It Works

1. **Fetch**: Intake service fetches from all configured sources (RSS, YouTube, API).
2. **Normalize**: Items are mapped to a common schema.
3. **Deduplicate**: Content hashes prevent duplicate ingestion (windowed by hours).
4. **Moderation**: Items requiring review are queued for moderation.
5. **Enqueue**: New, trusted items are inserted into the publishing queue.

## Setup

1. Install dependencies:
   ```bash
   npm install rss-parser node-fetch pg
   ```
2. Set environment variables (use Secret Manager in production):
   - `DATABASE_URL` (Postgres connection string)
   - `YOUTUBE_API_KEY` (YouTube Data API v3 key)
3. Create DB tables:
   ```bash
   psql $DATABASE_URL -f infra/feeds_tables.sql
   ```
4. Configure sources in `config/auto_feed_sources.json`.
5. Run intake manually:
   ```bash
   npx ts-node src/feeds/intake.ts
   ```
6. (Optional) Schedule with cron or Cloud Scheduler.

## Security & Ops

- **Secrets**: Never commit API keys or DB credentials. Use environment variables or Secret Manager.
- **Monitoring**: Log fetch/parse errors, dedupe rate, moderation queue size.
- **Testing**: Run in staging before enabling auto-publish.

## Extending

- Add new sources to `config/auto_feed_sources.json`.
- Implement additional fetchers or moderation logic in `src/feeds/intake.ts`.
