# CHUCKYA Operator Quick Card

**Print on A4 or laminate as badge card.**

---

## Immediate Actions on Alert

1. **ACKNOWLEDGE** alert in Ops console. Record time and operator ID.
2. **CHECK CONFIDENCE** — read `riskScore`, UWB vector, BLE sightings.
3. **NOTIFY WEARER** (if imminent approach) — system sends silent haptic + escape arrow.
4. **CONTACT VENUE SECURITY** — provide location sector and intercept path.

---

## Escalation Levels

### Code Amber — Suspicious proximity

- Log event, increase monitoring, **NO export**.

### Code Red — Confirmed approach with supporting signals

- Notify venue security, prepare export request, inform Legal.

### Code Black — Imminent danger

- Ops requests export **IMMEDIATELY**.
- Legal must approve.
- **Call police.**

---

## Export Checklist

1. Ops clicks **Request Export** — record reason.
2. Legal approves in UI — record justification.
3. Generate export — download `evidence.zip`.
4. Run verification (terminal or tools script).

### Verification One-Liner

```bash
jq -S . evidence/payload.json > evidence/payload.canon && \
jq -r '.signatureBase64' evidence/signed_payload.json | \
base64 -d > evidence/sig.bin && \
openssl dgst -sha256 -verify public.pem \
-signature evidence/sig.bin evidence/payload.canon
```

**Success**: output `Verified OK` or `signature OK`.

---

## Do Not

- **Do NOT** include GPS or IMEI in exports unless Legal approved AND consent recorded.
- **Do NOT** hand over evidence without verifying signature and manifest.
- **Do NOT** act on a single low-confidence alert without corroborating signals.

---

## Contacts

| Role           | Contact                    | Phone           |
| -------------- | -------------------------- | --------------- |
| Ops Lead       | ops_lead@example.com       | —               |
| Legal Approver | legal_approver@example.com | +61-400-000-000 |
| Police Liaison | police_liaison@example.com | +61-400-111-111 |

---

## Quick Troubleshooting

| Issue                | Action                                                          |
| -------------------- | --------------------------------------------------------------- |
| No evidence zip      | Check verifier logs, retry export                               |
| Signature fails      | **Do NOT hand over.** Escalate to Backend Engineer and Security |
| High false positives | Pause automated escalations, open incident review               |

---

> **Remember**: This system is a warning tool. Protect privacy by default. Follow two-person export rules. Your calm, correct actions save lives and preserve trust.
