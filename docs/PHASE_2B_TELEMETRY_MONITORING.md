# Phase 2B Telemetry Monitoring Configuration

This file configures the telemetry and monitoring infrastructure for Phase 2B creator dashboard real-time streams.

## Firestore Telemetry Collection

### Collection Structure

```
telemetry/
  └── creator_listeners/
      └── {docId}
          ├── creatorId (string)
          ├── status (enum: connected|disconnected|error)
          ├── errorMessage (string, nullable)
          ├── timestamp (timestamp)
          ├── latencyMs (number)
          └── metadata (object)
```

### Sample Document

```json
{
  "creatorId": "hero_creator_test_001",
  "status": "connected",
  "errorMessage": null,
  "timestamp": "2026-07-09T12:34:56Z",
  "latencyMs": 245,
  "metadata": {
    "profileStream": "connected",
    "earningsStream": "connected",
    "clipsStream": "connected",
    "rankingStream": "connected",
    "badgesStream": "connected",
    "insightsStream": "connected",
    "subscriptionCount": 6
  }
}
```

## Google Cloud Logging Queries

### Query 1: Listener Connection Rate

**Purpose**: Monitor real-time stream connection health

```sql
resource.type="cloud_firestore_database"
resource.labels.database_id="(default)"
protoPayload.methodName="google.firestore.v1.Firestore.Listen"
protoPayload.request.database="/creator_dashboards/hero_creator_test_001"
| STATS COUNT as connection_attempts,
        COUNT(EXTRACT(protoPayload.response.status = "OK")) as successful_connections
| FIELD timestamp >= "-1h"
```

**Expected**:

- Successful connections ≥ 99% (< 1 failure per 100 attempts)
- Average response time < 500ms

---

### Query 2: Conversion Write Success Rate

**Purpose**: Ensure conversion events are being recorded reliably

```sql
resource.type="cloud_firestore_database"
resource.labels.database_id="(default)"
protoPayload.methodName="google.firestore.v1.Firestore.Write"
protoPayload.request.database="/creator_dashboards/hero_creator_test_001/conversions"
| STATS COUNT(SELECT CASE
    WHEN protoPayload.response.status = "OK" THEN 1
    END) as successful_writes,
  COUNT(*) as total_writes
| FIELD timestamp >= "-1h"
```

**Expected**:

- Success rate: 100% (0 failures)
- Write latency P95 < 100ms
- No duplicate writes (same requestId)

---

### Query 3: Stream Latency Percentiles

**Purpose**: Monitor real-time stream performance under load

```sql
resource.type="cloud_firestore_database"
resource.labels.database_id="(default)"
protoPayload.methodName=~"google.firestore.v1.Firestore.Listen|google.firestore.v1.Firestore.RunQuery"
protoPayload.request.database=~"/creator_dashboards.*"
| STATS
  PERCENTILE(protoPayload.response.timeMs, 50) as p50,
  PERCENTILE(protoPayload.response.timeMs, 95) as p95,
  PERCENTILE(protoPayload.response.timeMs, 99) as p99,
  COUNT(*) as request_count
| FIELD timestamp >= "-1h"
```

**Expected**:

- P50 latency < 300ms
- P95 latency < 500ms
- P99 latency < 1000ms

---

### Query 4: Error Rate by Type

**Purpose**: Track error patterns and failure modes

```sql
resource.type="cloud_firestore_database"
resource.labels.database_id="(default)"
protoPayload.response.status != "OK"
protoPayload.request.database=~"/creator_dashboards.*"
| STATS COUNT(*) as error_count by protoPayload.response.error
| ORDER BY error_count DESC
| FIELD timestamp >= "-1h"
```

**Expected**:

- PERMISSION_DENIED: 0 (no rule violations)
- DEADLINE_EXCEEDED: < 1 per 10,000 requests
- INTERNAL: < 1 per 10,000 requests

---

### Query 5: Duplicate Conversion Detection

**Purpose**: Identify idempotency failures (critical for payouts)

```sql
resource.type="cloud_firestore_database"
resource.labels.database_id="(default)"
protoPayload.methodName="google.firestore.v1.Firestore.Write"
protoPayload.request.database="/creator_dashboards/hero_creator_test_001/conversions"
protoPayload.response.status="OK"
| EXTRACT jsonPayload.metadata.requestId as requestId
| GROUP BY requestId
| SELECT requestId, COUNT(*) as write_count
| FILTER write_count > 1
| FIELD timestamp >= "-1h"
```

**Expected**: 0 rows (no duplicate conversions)

---

## Dashboard Metrics (Cloud Console)

### Create Custom Metrics

Add these to a Cloud Monitoring dashboard:

**Metric 1: Listener Uptime**

```
resource.type="global"
metric.type="custom.googleapis.com/creator_listener_uptime"
| GRAPH_PERIOD "1m"
| ALIGN MEAN()
```

**Metric 2: Conversion Write Latency**

```
resource.type="cloud_firestore_database"
metric.type="firestore.googleapis.com/write_latencies"
resource.labels.database_id="(default)"
| GRAPH_PERIOD "1m"
| ALIGN DELTA()
| PLOT STACKED()
```

**Metric 3: Stream Error Rate**

```
resource.type="cloud_firestore_database"
metric.type="firestore.googleapis.com/error_count"
resource.labels.database_id="(default)"
| GRAPH_PERIOD "1m"
| ALIGN RATE()
```

---

## Alert Policies

### Alert 1: Listener Downtime

**Condition**: Uptime < 99.9% for 5 minutes

```
resource.type="cloud_firestore_database"
protoPayload.response.status != "OK"
protoPayload.request.database="/creator_dashboards/hero_creator_test_001"
| CONDITION COUNT(*) > 10
| OVER_TIME 5m
```

**Action**: Page on-call engineer, log incident

---

### Alert 2: Conversion Write Failure

**Condition**: Write failure rate > 0.1% for 2 minutes

```
resource.type="cloud_firestore_database"
protoPayload.methodName="google.firestore.v1.Firestore.Write"
protoPayload.request.database="/creator_dashboards/hero_creator_test_001/conversions"
| CONDITION (COUNT(SELECT CASE WHEN protoPayload.response.status != "OK" THEN 1 END) / COUNT(*)) > 0.001
| OVER_TIME 2m
```

**Action**: Alert payments team, trigger manual reconciliation

---

### Alert 3: Latency Spike

**Condition**: P95 latency > 1000ms for 5 minutes

```
resource.type="cloud_firestore_database"
protoPayload.request.database=~"/creator_dashboards.*"
| CONDITION PERCENTILE(protoPayload.response.timeMs, 95) > 1000
| OVER_TIME 5m
```

**Action**: Check Firestore scaling status, review query patterns

---

## Telemetry Log Retention

- **Creator listener logs**: Retain 7 days (rolling)
- **Conversion events**: Retain 90 days (compliance audit trail)
- **Error logs**: Retain 30 days (incident investigation)

### Cleanup Schedule

```bash
# Daily: Archive and compress old telemetry
0 2 * * * gsutil cp gs://dfc-prod/telemetry/* gs://dfc-archive/telemetry/ && gsutil rm gs://dfc-prod/telemetry/*

# Weekly: Verify conversion audit log integrity
0 3 * * 0 firestore export gs://dfc-archive/conversions-backup-$(date +%Y%m%d)
```

---

## Metrics to Watch (First 72 Hours)

| Metric                         | Target    | Warning    | Alert      |
| ------------------------------ | --------- | ---------- | ---------- |
| Listener uptime                | > 99.9%   | < 99.5%    | < 95%      |
| Profile stream latency (P95)   | < 500ms   | < 1s       | > 2s       |
| Earnings stream latency (P95)  | < 500ms   | < 1s       | > 2s       |
| Clips stream latency (P95)     | < 1s      | < 2s       | > 5s       |
| Conversion write latency (P95) | < 100ms   | < 200ms    | > 500ms    |
| Conversion success rate        | 100%      | 99.9%      | < 99%      |
| Conversion duplicate rate      | 0/1000    | < 0.1%     | > 0.1%     |
| Firestore document read count  | < 500/min | < 1000/min | > 2000/min |
| Firestore document write count | < 100/min | < 200/min  | > 500/min  |

---

## Canary Rollout Monitoring

### Phase 1 (Day 1) — Internal Only

Monitor every 15 minutes:

- Listener connection rate
- Conversion write success
- Stream latency

Alert threshold: Any metric hits WARNING

### Phase 2 (Day 2) — Staging Creators

Monitor every 5 minutes:

- All Phase 1 metrics
- Add: Duplicate conversion detection
- Add: Database index hit rate

Alert threshold: Any metric hits ALERT

### Phase 3 (Day 3) — Limited Release

Monitor continuously:

- All metrics
- Add: Payout reconciliation
- Add: Creator dashboard engagement

Alert threshold: Automatic escalation

---

## Post-Incident Checklist

If an alert fires:

1. [ ] Page on-call engineer
2. [ ] Create incident ticket
3. [ ] Export relevant Firestore logs
4. [ ] Archive telemetry for analysis
5. [ ] Identify root cause
6. [ ] Implement fix
7. [ ] Re-run E2E validation
8. [ ] Monitor for regression (2 hours)
9. [ ] Document incident in runbook
10. [ ] Schedule postmortem

---

## Tools

- **Cloud Logging**: https://console.cloud.google.com/logs
- **Cloud Monitoring**: https://console.cloud.google.com/monitoring
- **Firebase Console**: https://console.firebase.google.com
- **Firestore Emulator**: `firebase emulators:start`
