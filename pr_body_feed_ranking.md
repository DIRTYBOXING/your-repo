Summary
Adds runtime-configurable ranking weights and implements canonical URL normalization
and content fingerprinting in the normalize stage. Also enforces freshness TTL and
adds schema validation to reduce malformed items.

Changes

- lib/core/config/chukya_config.dart: FeedRankingConfig class and loader
- services/auto_feed_orchestrator_service.dart: read config on refresh and use weights in scoring
- services/scoring_helpers.dart: small helpers for recency/trust/engagement scoring
- services/normalizer.dart: canonicalization and fingerprint dedupe
- test/chukya_config_test.dart: config parsing tests
- test/normalizer_test.dart: dedupe and canonicalization unit tests

Why

- Enables runtime tuning of ranking weights without code deploys
- Reduces duplicates and malformed items entering the pipeline

Verification

- `dart analyze` returns no errors
- `dart test` tests/chukya_config_test.dart and tests/normalizer_test.dart pass
- Staging feed-smoke (ingest → normalize → index → sample query) passes

Checklist

- [ ] Unit tests added for config parsing and dedupe
- [ ] Integration smoke added to CI
- [ ] Feature flag default set to safe values
- [ ] PR description documents canary plan
