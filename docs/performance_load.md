# Performance & Load

## Load Test Targets

| Scenario                | Target      | Tool              |
| ----------------------- | ----------- | ----------------- |
| Concurrent users        | 1,000       | k6 / Artillery    |
| Firestore read ops/sec  | 10,000      | Load test script  |
| Firestore write ops/sec | 1,000       | Load test script  |
| Webhook events/min      | 200         | replay_webhook.sh |
| PPV purchase burst      | 500/min     | Stripe test mode  |
| Feed load (cold)        | < 2s p95    | Lighthouse        |
| Feed load (cached)      | < 500ms p95 | CDN metrics       |
| API response time       | < 200ms p95 | Cloud Run metrics |

## Optimizations

- **CDN caching** — Static assets (24h), media (12h), API responses (5min selective)
- **Query indexing** — Composite indexes for all feed, ranking, and search queries
- **Cloud Run concurrency** — 80 concurrent requests per instance, min 1 / max 100 instances
- **Firestore query optimization** — Denormalized reads, subcollection pagination, cursor-based paging
- **Image optimization** — WebP format, responsive sizes (320/640/1280), lazy loading
- **Bundle optimization** — Tree shaking, deferred loading for non-critical features
- **Connection pooling** — Firestore SDK connection reuse, HTTP/2 multiplexing

## Monitoring

- Cloud Run metrics: request count, latency p50/p95/p99, error rate, instance count
- Firestore metrics: read/write ops, active connections, document size
- Stripe metrics: webhook delivery rate, payment success rate, latency
- Custom dashboards: real-time user count, feed render time, PPV purchase funnel

## Alerts

| Metric               | Warning | Critical |
| -------------------- | ------- | -------- |
| Error rate           | > 1%    | > 5%     |
| Response time p95    | > 500ms | > 2s     |
| Instance count       | > 50    | > 80     |
| Firestore ops/sec    | > 8,000 | > 9,500  |
| Webhook failure rate | > 1%    | > 5%     |

## Capacity Planning

- Current capacity: 10,000 concurrent users
- Scale target (6 months): 50,000 concurrent
- Scale target (12 months): 200,000 concurrent
- Auto-scaling: Cloud Run handles burst, Firestore scales automatically
- Cost projections reviewed monthly against usage growth
