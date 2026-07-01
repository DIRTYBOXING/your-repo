# Data Lifecycle

## Stages

- **Collection** — User input, API ingestion, sensor data (wearables), Firestore writes
- **Storage** — Firestore (primary), Cloud Storage (media), BigQuery (analytics)
- **Processing** — AI engines, ranking algorithms, feed pipelines, content moderation
- **Retention** — Active data: indefinite while account active; Financial: 7 years; Logs: 90 days
- **Archival** — Cold storage for inactive accounts (>2 years), compressed event archives
- **Deletion** — GDPR erasure requests (30-day SLA), orphaned media cleanup, expired tokens

## Automation

- Auto-delete old logs (Cloud Scheduler → 90-day log purge)
- Auto-archive events (events older than 6 months → cold storage)
- Auto-clean orphaned media (weekly scan: media with no parent document → delete)
- Auto-expire sessions (inactive sessions purged after 30 days)
- Auto-rotate API keys (90-day rotation enforced)

## Firestore Data Lifecycle

| Collection    | Retention     | Archive Policy                    |
| ------------- | ------------- | --------------------------------- |
| users         | Account life  | 2 years inactive → archive        |
| posts         | Indefinite    | Flagged content → 90 days         |
| orders        | 7 years       | Financial compliance              |
| events        | Indefinite    | Past events → cold after 6 months |
| fighter_stats | Indefinite    | Active fighters only              |
| media_assets  | 1 year unused | Orphan scan weekly                |
| audit_logs    | 400 days      | Auto-purge                        |

## BigQuery Ingestion

- Real-time: orders, events, user signups
- Batch (daily): fighter stats, engagement metrics, feed analytics
- Retention: 2 years in BigQuery, then archive to Cloud Storage
