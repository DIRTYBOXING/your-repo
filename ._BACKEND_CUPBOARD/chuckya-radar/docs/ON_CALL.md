# CHUCKYA Radar — On-Call Runbook

**Purpose**: Quick on-call runbook for staging and pilot incidents. Single source of truth for immediate triage, verification, and export procedures.

---

## Quick Status Checks

### Services

```bash
docker-compose -f docker-compose.yml -f docker-compose.override.yml ps
curl -sS http://localhost:8081/health
```

**Success**: health endpoint returns `ok`.

### Logs

```bash
docker-compose logs verifier --tail=200
docker-compose logs ws-server --tail=200
```

### Audit Folder

```bash
ls -l ops-audit | tail
```

---

## Triage Flow for Incoming Alert

1. **Acknowledge** — mark alert in Ops console as acknowledged. Record time and operator ID.
2. **Verify signature** — confirm payload signature verified by verifier logs. If verifier shows failure, escalate to Security.
3. **Check consent flags** — confirm `consent.location` and `consent.imei` values in `signed_payload.json`. Do not request PII unless consent is `true` AND Legal approves.
4. **Assess confidence** — review `riskScore`, UWB vector, BLE sightings, and any attached media. If confidence low, monitor; if medium/high, follow escalation below.
5. **Escalate** — follow Code Amber/Red/Black SOP on operator card.

---

## Export Request Procedure

| Step | Action                                                                                                                            |
| ---- | --------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Ops requests export in UI and records reason.                                                                                     |
| 2    | Legal receives notification and must respond within **5 minutes**. Legal must include approval timestamp and short justification. |
| 3    | Once Legal approves, Ops clicks **Generate Export**. System creates `evidence.zip` and `chain_of_custody.json`.                   |
| 4    | Verify manifest and signature locally before handing to police.                                                                   |

### Verification Commands

```bash
# Download evidence
curl -X POST "http://localhost:8081/v1/radar/alerts/<ALERT_ID>/export" -o evidence.zip
unzip -o evidence.zip -d evidence

# Canonicalize and verify signature
jq -S . evidence/payload.json > evidence/payload.canon
jq -r '.signatureBase64' evidence/signed_payload.json | base64 -d > evidence/sig.bin
openssl dgst -sha256 -verify public.pem -signature evidence/sig.bin evidence/payload.canon && echo "signature OK"

# Compute SHA256 and compare to manifest
openssl dgst -sha256 evidence/payload.canon
jq . evidence/chain_of_custody.json
```

**Success**: `signature OK` and SHA256 matches manifest entry.

---

## Immediate Escalation Contacts

| Role              | Contact                    | Channel               |
| ----------------- | -------------------------- | --------------------- |
| Ops Lead          | ops_lead@example.com       | Slack `#ops`          |
| Mobile Engineer   | mobile_eng@example.com     | Slack `#mobile`       |
| Hardware Engineer | hw_eng@example.com         | Slack `#hardware`     |
| Backend Engineer  | backend_eng@example.com    | Slack `#backend`      |
| Legal Approver    | legal_approver@example.com | Phone +61-400-000-000 |
| Police Liaison    | police_liaison@example.com | Phone +61-400-111-111 |

**Record every contact attempt in the incident log.**

---

## Emergency Quick Fixes

### Service Restart

```bash
docker-compose restart verifier ws-server
```

### Requeue Failed Uploads

Check `verifier` retry queue and reprocess.

### Revoke Export Access

Rotate export key in Secret Manager and notify Security.

---

## Post-Incident

- Create postmortem within **24 hours**.
- Attach: logs, `ops-audit` folder, export manifest, approver timestamps, and recommended fixes.
- File ticket for any system failures discovered during incident.
