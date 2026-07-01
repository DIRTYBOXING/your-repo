# Final Pre-Launch Sign-Off Checklist

This checklist must be systematically completed and approved by the respective heads of departments before production cutover traffic is routed to the consolidated branch.

---

## ⚖️ Legal & Compliance Sign-Off
- [ ] **Data Consent Policies:** Confirmed that registration flows capture unambiguous user consent according to EU GDPR and COPPA regulations where child profiles might apply.
- [ ] **Payment Terms of Service:** Updated explicit user declarations on PPV purchases, recurring subs, and refund structures.
- [ ] **Entity Isolation:** Confirmed separate business entities have correct merchant accounts setup on Stripe.

*Approval Signature:* __________________________  *Date:* ____________

---

## 💳 Finance Sign-Off
- [ ] **Stripe Live Credentials:** Live keys are verified and configured in GCP Secret Manager, not containing remnants of any `sk_test_` configurations.
- [ ] **Test Transaction Refunded:** Completed a manual $1.00 USD transaction on staging/production, verified payout, and issued a standard refund receipt.
- [ ] **Transfer / Payout splits:** Checked revenue formulas and promoter cuts inside [lib/shared/services/promoter_settlement_snapshot_service.dart](lib/shared/services/promoter_settlement_snapshot_service.dart) for accurate bank reconciliation.

*Approval Signature:* __________________________  *Date:* ____________

---

## 🛠️ DevOps & QA Infrastructure Sign-Off
- [ ] **No-Stub Compilation:** Ran build scripts and confirmed that zero standard `throw UnimplementedError()` blocks exist in active live loops.
- [ ] **Firebase Custom Claims Enforced:** Confirmed that admin/ops accounts are verified directly in role validations using claims payload decodes rather than simple document properties.
- [ ] **Stripe Webhook Signatures:** Configured `STRIPE_WEBHOOK_SECRET` live verified endpoints back to API endpoint paths.
- [ ] **Database Sweep Complete:** Verified through [scripts/cleanup_test_promos.py](scripts/cleanup_test_promos.py) that no fake, smoke, test, or sample promotional banners exist in database.

*Approval Signature:* __________________________  *Date:* ____________
