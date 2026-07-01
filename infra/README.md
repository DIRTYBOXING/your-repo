# Observability Stack — Apply & Verification Guide

This guide covers the exact steps to deploy, verify, and operate the DFC observability stack. Follow in order for a safe rollout.

---

## 1. Replace Placeholders & Commit

**Edit these files:**

- `infra/alertmanager-manifest.yaml` — Replace `<SLACK_WEBHOOK_TOKEN>`, `<PAGERDUTY_INTEGRATION_KEY>`, `<RUNBOOK_HOST>`, `<ALERTMANAGER_URL>`
- `feed-alerts-annotated.yaml` — Replace `https://<RUNBOOK_HOST>/...`
- `feed-kpi-full-datasource.json` — Replace `https://<RUNBOOK_HOST>/...`
- `example/main.dart` — Set OTLP/Collector endpoint if needed
- `.github/workflows/observability-smoke.yml` — Ensure `ALERTMANAGER_URL` and `RUNBOOK_HOST` are referenced via GitHub Secrets

**Commit:**

```bash
git add infra/alertmanager-manifest.yaml feed-alerts-annotated.yaml feed-kpi-full-datasource.json example/main.dart .github/workflows/observability-smoke.yml infra/README.md
git commit -m "observability: finalize alertmanager, prometheus rules, grafana dashboard, CI smoke test"
git push
```

---

## 2. Create Secrets Securely

**Kubernetes:**

```bash
kubectl create ns observability --dry-run=client -o yaml | kubectl apply -f -
kubectl -n observability create secret generic alertmanager-secrets \
  --from-literal=SLACK_WEBHOOK_TOKEN='<SLACK_WEBHOOK_TOKEN>' \
  --from-literal=PAGERDUTY_INTEGRATION_KEY='<PAGERDUTY_INTEGRATION_KEY>' \
  --dry-run=client -o yaml | kubectl apply -f -
```

**GitHub:** Add `ALERTMANAGER_URL` and `RUNBOOK_HOST` to repository Secrets.

---

## 3. Apply Alertmanager Manifest & Prometheus Rules

```bash
kubectl apply -f infra/alertmanager-manifest.yaml
kubectl apply -f feed-alerts-annotated.yaml
```

**Verify:**

```bash
kubectl -n observability get pods -l app=alertmanager
kubectl -n observability logs deploy/alertmanager -c alertmanager --tail=200
kubectl -n observability get configmap alertmanager-config -o yaml
```

---

## 4. Import Grafana Dashboard

- Grafana → Dashboards → Import → Paste JSON (`feed-kpi-full-datasource.json`) → select Prometheus datasource
- Replace runbook links in UI if any remain
- Confirm Deploys annotation appears once CI emits `deploys_total`

---

## 5. Run Dart Example Locally or in Staging

```bash
cd example
dart pub get
dart run example/main.dart
```

**Verify:**

```bash
kubectl -n observability get pods -l app=otel-collector
kubectl -n observability logs deploy/otel-collector-gateway -c otel-collector --tail=200
# In Prometheus UI or Grafana, query:
# feed_ingestion_processed_total
# feed_ingestion_errors_total
# feed_duplicate_rate
```

---

## 6. Test Alertmanager Routing (End-to-End)

```bash
curl -XPOST -H "Content-Type: application/json" -d '[{"labels":{"alertname":"TestAlert","severity":"page","pipeline_stage":"ingest","sourceId":"test"},"annotations":{"summary":"Test alert","description":"This is a test","runbook":"https://<RUNBOOK_HOST>/runbooks/test"}}]' http://<ALERTMANAGER_URL>/api/v1/alerts
```

**Verify:**

- PagerDuty: incident created for `severity: page`
- Slack: message posted to `#ops-alerts` for `severity: ticket` or default channel
- Alertmanager UI: shows the incoming alert

---

## 7. Enable CI Smoke Test

- Add secrets to GitHub: `ALERTMANAGER_URL`, `RUNBOOK_HOST`
- Trigger workflow manually (Actions → observability-smoke → Run workflow)
- Confirm job runs, example emits telemetry, test alert appears in PagerDuty/Slack

---

## 8. Tune Thresholds & Run Canary

- Run canary traffic for 7–14 days; collect baseline metrics
- Adjust Prometheus rule thresholds based on observed medians and p95s
- Suggested initial tuning:
  - Ingestion error rate: page if >0.5% sustained 10m
  - Duplicate rate: page if >2% sustained 15m
  - Freshness median: ticket if >6h sustained 15m
  - p95 latency: page if >30s sustained 10m

---

## Troubleshooting

- **No metrics in Prometheus:** Confirm Collector OTLP receiver reachable; check service DNS and ports (4317/4318)
- **No alerts in PagerDuty/Slack:** Check Alertmanager logs for delivery errors; verify webhook keys and network egress
- **High alert noise:** Remove high-cardinality labels from `group_by`; increase `for:` durations; combine signals
- **Grafana panels empty:** Ensure datasource selected and time range covers emitted metrics; check Prometheus queries in panel

---

## Files to Commit

- `infra/alertmanager-manifest.yaml` (with secrets referenced or templated)
- `feed-alerts-annotated.yaml`
- `feed-kpi-full-datasource.json`
- `example/main.dart`
- `.github/workflows/observability-smoke.yml`
- `infra/README.md`
