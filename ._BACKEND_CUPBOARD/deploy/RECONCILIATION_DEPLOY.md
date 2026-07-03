# Reconciliation Worker — Deploy Assets

## Files

| File | Purpose |
|------|---------|
| `systemd/dfc-reconciliation.service` | oneshot systemd unit (single-server deployments) |
| `systemd/dfc-reconciliation.timer` | nightly schedule at 02:00 UTC, with `Persistent=true` |
| `k8s/reconciliation-cronjob.yaml` | Kubernetes CronJob (`concurrencyPolicy: Forbid`) |
| `../server/jobs/reconciliation-runner.js` | Node.js entrypoint with redis SETNX lock |

---

## systemd installation

```bash
sudo cp dfc-reconciliation.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now dfc-reconciliation.timer

# Check next run time
systemctl list-timers dfc-reconciliation.timer

# Trigger manually
sudo systemctl start dfc-reconciliation.service
journalctl -u dfc-reconciliation.service -f
```

Override environment via `/etc/dfc/reconciliation.env`:
```
REDIS_URL=redis://redis-primary:6379
RECON_LOCK_TTL_MS=300000
```

---

## Kubernetes deployment

```bash
# Create secret for Redis URL
kubectl create secret generic dfc-redis-credentials \
  --from-literal=url="redis://redis-primary.dfc-production.svc:6379" \
  -n dfc-production

# Apply the CronJob
kubectl apply -f k8s/reconciliation-cronjob.yaml -n dfc-production

# Verify
kubectl get cronjob dfc-wallet-reconciliation -n dfc-production

# Trigger manually (creates a one-off Job)
kubectl create job --from=cronjob/dfc-wallet-reconciliation \
  reconciliation-manual-$(date +%s) -n dfc-production
```

---

## Redis distributed lock (runner-level)

`reconciliation-runner.js` uses `redis` v4 `SET key NX PX` for single-run semantics:

- **Acquire**: `SET dfc:reconciliation:lock <pid:ts> NX PX 300000`
- **Release**: `GET` then `DEL` only if value still matches (prevents stealing a renewed lock)
- **Fallback**: If Redis is unreachable the runner logs a warning and proceeds without the lock — safe for single-instance deployments, `concurrencyPolicy: Forbid` handles it in K8s.

Exit codes:
- `0` — run completed successfully
- `1` — job threw an error (triggers K8s job failure + PagerDuty via Alertmanager)
- `2` — lock held by another instance (counted as success, K8s `SuccessExitStatus` not relevant — runner exits 0 in K8s to avoid false failures; see code)

---

## Prometheus alert

`monitoring/prometheus/dfc-payments.rules.yml` contains:

```yaml
- alert: WalletReconciliationMismatchHigh
  expr: dfc_wallet_reconciliation_mismatch_ratio > 0.01
  for: 5m
  labels: { severity: warning, service: payments }
```

Fires when > 1 % of accounts in a run have a discrepancy. Investigate via:

```bash
curl http://localhost:4000/api/admin/reconciliation/latest | jq .
```
