Summary
Implements trust scoring in normalization, routes borderline items to a review queue,
and extends the admin monitor to review and act on queued items.

Changes

- services/source_trust_rules_service.dart: trust scoring heuristics
- migrations/0001_create_review_queue.sql: DB migration stub for review queue table
- services/review_queue_service.dart: queue insert/query/update API
- ui/admin/feed_pipeline_monitor_screen.dart: review queue UI extension
- test/trust_rules_test.dart: unit tests for trust heuristics
- test/review_queue_integration_test.dart: integration test for routing and review actions

Why

- Surface borderline items for manual review to reduce false positives
- Provide a safe path to approve or downrank items without immediate code changes

Verification

- Items with low trust land in review queue
- Review actions update source reputation and downstream ranking
- Integration tests pass

Checklist

- [ ] DB migration included
- [ ] Admin UI changes covered by basic UI tests
- [ ] Integration tests for review flow
- [ ] Logging for review actions
