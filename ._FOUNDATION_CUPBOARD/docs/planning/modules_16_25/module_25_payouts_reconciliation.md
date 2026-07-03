# Module 25 — Payout Reconciliation and Dispute Handling

**Owner:** @finance

**Files to add/modify**
- backend/finance/reconciliation_service.dart
- backend/finance/dispute_manager.dart
- infra/finance/payout_report_worker.dart

**APIs required**
- POST /finance/reconcile (dateRange)
- POST /finance/dispute (payoutId, reason)
- GET /finance/payouts/{batchId}/status

**DB collections**
- payout_batches (batchId, status, totalAmount)
- reconciliation_entries (entryId, ledgerRef, amount, status)
- disputes (disputeId, payoutId, reason, status)

**Tests**
- Accounting invariants tests (debits == credits)
- Reconciliation end-to-end with sample dataset
- Dispute lifecycle tests

**Release gate**
- Reconciliation completes and ledger balances for sample dataset
- Dispute flow creates audit trail and updates payout status
- No critical mismatches in staging reconciliation run
