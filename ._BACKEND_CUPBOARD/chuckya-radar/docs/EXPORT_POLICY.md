# CHUCKYA Radar — Export Policy

**Purpose**: Governs all evidence exports from the CHUCKYA Radar system. Every export MUST follow these procedures. No exceptions.

---

## Two-Person Approval Rule

Every export of alert data, evidence packages, or any payload containing PII requires approval from **two separate individuals**:

| Role               | Responsibility                                               |
| ------------------ | ------------------------------------------------------------ |
| **Ops Requestor**  | Initiates export, records reason, confirms payload scope     |
| **Legal Approver** | Reviews request, confirms legal basis, records justification |

Both approver IDs and timestamps are logged in `chain_of_custody.json`. The system blocks export generation if either approval is missing.

---

## What Gets Exported

| Artifact                | Contents                                                          | Always included |
| ----------------------- | ----------------------------------------------------------------- | --------------- |
| `payload.json`          | Raw alert data (event type, timestamp, risk score, consent flags) | Yes             |
| `signed_payload.json`   | Payload + cryptographic signature + public key reference          | Yes             |
| `chain_of_custody.json` | SHA256 hashes, approver IDs, timestamps, export reason            | Yes             |
| `evidence.zip`          | Bundle of all above artifacts                                     | Yes             |

### Conditional fields (consent-gated)

| Field             | Included only when                             |
| ----------------- | ---------------------------------------------- |
| GPS coordinates   | `consent.location` = `true` AND Legal approval |
| IMEI / device ID  | `consent.imei` = `true` AND Legal approval     |
| Media attachments | Explicit user opt-in at time of alert          |

---

## What Is NEVER Exported

- Private signing keys (remain in Android Keystore / Secure Enclave)
- Raw BLE advertising data from non-paired devices
- Historical location trails (only point-in-time if consented)
- Operator credentials or session tokens
- Internal system logs (available only to Auditor role via separate channel)

---

## Export Procedure

### Step 1 — Request

Ops clicks **Request Export** in the Ops console.

- Record: alert ID, reason for export, requesting operator ID.
- System flags the request as **Pending Legal Approval**.

### Step 2 — Legal Review

Legal Approver receives notification (email + Slack `#legal`).

- **Response SLA**: 5 minutes during active incidents, 30 minutes otherwise.
- Legal must record: approval/denial, justification, legal basis (e.g., MOU reference, court order number).
- If denied, system logs denial reason and notifies Ops.

### Step 3 — Generate

After Legal approves, Ops clicks **Generate Export**.

- System creates `evidence.zip` containing all artifacts.
- SHA256 of every file is computed and written to `chain_of_custody.json`.
- Export event is logged to the immutable audit trail.

### Step 4 — Verify Before Handoff

Before handing evidence to any external party:

```bash
# Unpack
unzip -o evidence.zip -d evidence

# Verify signature
jq -S . evidence/payload.json > evidence/payload.canon
jq -r '.signatureBase64' evidence/signed_payload.json | base64 -d > evidence/sig.bin
openssl dgst -sha256 -verify public.pem -signature evidence/sig.bin evidence/payload.canon

# Verify SHA256 matches manifest
openssl dgst -sha256 evidence/payload.canon
jq '.artifacts' evidence/chain_of_custody.json
```

**Do NOT hand over evidence unless both checks pass.**

---

## Retention Policy

| Data type              | Retention period         | Storage                        |
| ---------------------- | ------------------------ | ------------------------------ |
| Active alerts          | Until resolved + 90 days | Firestore                      |
| Exported evidence      | 7 years                  | S3/GCS bucket with Object Lock |
| Audit logs             | 7 years                  | Append-only cloud storage      |
| Denied export requests | 2 years                  | Audit log                      |

After retention period, data is securely deleted with confirmation logged.

---

## MOU Requirements

Before any data sharing with external parties (venues, law enforcement, partners):

- [ ] Signed MOU on file specifying: data scope, retention, deletion timeline, breach notification procedure
- [ ] MOU reviewed by Legal within last 12 months
- [ ] Contact list for the external party's data protection officer on file
- [ ] Incident notification procedure agreed (24-hour breach disclosure)

---

## Abuse and Revocation

If misuse of export access is detected:

1. Revoke operator's export permissions within **15 minutes**.
2. Freeze all pending exports.
3. Preserve all logs and audit trails.
4. Notify affected parties within **24 hours**.
5. Rotate export encryption keys via Secret Manager.
6. Open formal incident review.

---

## Contact List

| Role                    | Contact                    | Backup                |
| ----------------------- | -------------------------- | --------------------- |
| Ops Lead                | ops_lead@example.com       | Slack `#ops`          |
| Legal Approver          | legal_approver@example.com | Phone +61-400-000-000 |
| Security                | security@example.com       | Slack `#security`     |
| Data Protection Officer | dpo@example.com            | —                     |
| Police Liaison          | police_liaison@example.com | Phone +61-400-111-111 |

---

_This policy must be reviewed quarterly. Any changes require Legal and Security sign-off._
