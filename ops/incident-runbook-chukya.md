# Chukya 3.0 Pink Shield — Incident Runbook

# SRE copy-paste ready. Keep this file in version control.

# Last updated: 2026-03-27

## Severity Definitions

- SEV-1 (Critical): Police notifications failing, victim safety compromised
- SEV-2 (High): False positive rate > 7%, latency > 30s, data integrity issue
- SEV-3 (Medium): Degraded performance, non-critical feature broken
- SEV-4 (Low): Cosmetic, logging, or monitoring gap

---

## Phase 1: Triage (0–5 min)

1. Confirm the alert source (Prometheus, PagerDuty, user report).
2. Check Firestore feature flags:
   ```
   firebase firestore:get settings/feature_flags --project=<PROJECT_ID>
   ```
3. Check if police notifications are paused:
   - Field: `chukya_police_notifications_paused`
   - If `false` and incident is SEV-1, immediately set to `true`:
   ```
   firebase firestore:set settings/feature_flags --merge --data='{"chukya_police_notifications_paused":true}' --project=<PROJECT_ID>
   ```

---

## Phase 2: Containment (5–30 min)

### Kill switch — disable Chukya entirely

```bash
firebase firestore:set settings/feature_flags --merge \
  --data='{"chukya_enabled":false,"chukya_police_notifications_paused":true}' \
  --project=<PROJECT_ID>
```

### Scale down Kubernetes deployment (if service-level issue)

```bash
kubectl -n staging scale deployment/chukya-safety --replicas=0
```

### Helm rollback (if bad deploy)

```bash
# List releases
helm history chukya-safety --namespace staging
# Rollback to previous revision
helm rollback chukya-safety <REVISION> --namespace staging
```

### Cloud Functions rollback

```bash
# List function versions
gcloud functions list --project=<PROJECT_ID> --filter="name:chukya"
# Redeploy previous tag
cd functions && git checkout <PREVIOUS_TAG> && firebase deploy --only functions --project=<PROJECT_ID>
```

---

## Phase 3: Investigation (30–240 min)

### Collect logs

```bash
# Kubernetes pods
kubectl -n staging logs deployment/chukya-safety --tail=500 --since=1h

# Cloud Functions
gcloud functions logs read chukyaCheckFingerprint --project=<PROJECT_ID> --limit=200
gcloud functions logs read addThreatProfile --project=<PROJECT_ID> --limit=200

# Firestore audit (requires Cloud Audit Logs enabled)
gcloud logging read 'resource.type="datastore_database" AND protoPayload.methodName=~"google.firestore.v1.Firestore.(Write|Commit)"' \
  --project=<PROJECT_ID> --limit=100 --format=json
```

### Check Prometheus metrics

```
chukya_detection_rate
chukya_false_positive_rate
chukya_police_notification_latency_seconds
chukya_evidence_upload_duration_seconds
```

### Verify Firestore state

```bash
# Check recent proximity_alerts
firebase firestore:get proximity_alerts --project=<PROJECT_ID> --limit=10

# Check police_notifications
firebase firestore:get police_notifications --project=<PROJECT_ID> --limit=10

# Check threat_watchlist
firebase firestore:get threat_watchlist --project=<PROJECT_ID> --limit=10
```

---

## Phase 4: Remediation

1. Apply the fix (code patch, config change, or data correction).
2. Deploy fix through normal CI pipeline (do NOT hotfix production directly).
3. Re-enable Chukya feature flags:
   ```bash
   firebase firestore:set settings/feature_flags --merge \
     --data='{"chukya_enabled":true,"chukya_police_notifications_paused":false}' \
     --project=<PROJECT_ID>
   ```
4. Scale back up if previously scaled down:
   ```bash
   kubectl -n staging scale deployment/chukya-safety --replicas=2
   ```
5. Run smoke tests to validate:
   ```bash
   API_BASE=https://staging-api.example.com TEST_TOKEN=<token> ./tools/smoke_all.sh
   node tools/inject_chukya_assert_admin.js
   ```

---

## Phase 5: Postmortem (within 48h)

### Template

- **Incident ID**: CHUKYA-YYYY-MM-DD-NNN
- **Severity**: SEV-X
- **Duration**: start – end (Xh Ym)
- **Impact**: number of victims affected, missed/false notifications
- **Root cause**: [description]
- **Timeline**: minute-by-minute actions taken
- **What went well**: [list]
- **What went wrong**: [list]
- **Action items**: [list with owners and due dates]

### Distribution

- Product Lead
- Legal Counsel
- Police Liaison
- On-call SRE
- Executive sponsor (SEV-1 only)

---

## Escalation Contacts

- **SRE On-call**: [PagerDuty rotation]
- **Product Lead**: [name, phone, email]
- **Legal Counsel**: [name, phone, email]
- **Police Liaison**: [name, phone, email]
- **Executive Sponsor**: [name, phone, email] (SEV-1 only)

---

## Key Thresholds (from chukya_config.dart)

- policeNotifyConfidence: 0.80
- consecutiveDetectionsRequired: 2
- cancelGraceWindowSeconds: 5
- False positive alert threshold: > 7% for 10 min
- Police latency alert threshold: > 30s median for 5 min
