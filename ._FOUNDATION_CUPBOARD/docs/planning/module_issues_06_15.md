# Modules 6-15 Issue Bodies

## Module 6: Media Processing Pipeline
Title: Implement Media Processing Pipeline (transcode, thumbnails, captions)

Owner: @infra-media
Files:
- infra/media/transcoder_adapter.dart
- infra/media/thumbnail_service.dart
- infra/media/captions_ingest.dart
- scripts/media/processing_worker.ps1

APIs:
- POST /media/transcode
- POST /media/thumbnail
- POST /media/captions/ingest
- POST /media/processing/callback

Data:
- renditions
- thumbnails
- captions
- media_errors

Tests:
- codec/profile unit tests
- integration transcode callback tests
- playback compatibility regression tests

Release gate:
- staging transcodes complete end-to-end
- thumbnails and captions linked on playback objects
- no critical processing errors for sample suite

## Module 7: Rights and Policy Metadata
Title: Implement Rights and Policy Metadata Service

Owner: @legal-tech
Files:
- backend/rights/rights_service.dart
- backend/rights/controllers/rights_controller.dart
- backend/rights/models/rights_model.dart

APIs:
- POST /rights/assign
- GET /rights/{contentId}
- POST /rights/takedown

Data:
- content_rights
- geo_policy
- age_policy
- takedown_requests

Tests:
- rights policy unit tests
- age and region integration tests
- takedown lifecycle tests

Release gate:
- policy enforcement verified in staging
- takedown flow auditable

## Module 8: Feed Candidate Generation
Title: Implement Feed Candidate Generation Service

Owner: @data-backend
Files:
- backend/feed/candidate_service.dart
- backend/feed/candidate_scheduler.dart

APIs:
- POST /feed/generate-candidates
- GET /feed/candidates/{userId}

Data:
- feed_candidates
- candidate_scores
- user_interest_vectors

Tests:
- candidate diversity and quality tests
- latency and throughput tests

Release gate:
- p95 latency meets SLA
- candidate quality checks pass for test cohorts

## Module 9: Feed Ranking Service
Title: Implement Feed Ranking Service

Owner: @data-science
Files:
- backend/ranking/ranking_service.dart
- backend/ranking/feature_extractor.dart

APIs:
- POST /ranking/score
- GET /ranking/top/{userId}

Data:
- ranking_features
- ranking_logs
- exploration_state

Tests:
- offline ranking metric tests
- online AB harness tests
- safety/ranking interaction tests

Release gate:
- ranking KPI uplift and no safety regression in staging experiments

## Module 10: Feedback Ingestor
Title: Implement Feedback Ingestor (views, likes, shares, reports)

Owner: @analytics
Files:
- backend/feedback/ingestor.dart
- backend/feedback/producer_adapter.dart

APIs:
- POST /feedback/event
- GET /feedback/summary/{userId}

Data:
- event_stream
- user_actions
- creator_actions

Tests:
- schema contract tests
- dedupe and exactly-once tests
- backfill compatibility tests

Release gate:
- no event loss over threshold
- schema compatibility pass in pipeline checks

## Module 11: Notification Rules Engine
Title: Implement Notification Rules Engine

Owner: @notifications
Files:
- backend/notifications/rules_engine.dart
- backend/notifications/delivery_worker.dart

APIs:
- POST /notifications/schedule
- GET /notifications/status/{userId}

Data:
- notifications
- notification_preferences
- delivery_logs

Tests:
- dedupe and throttle tests
- per-channel delivery tests

Release gate:
- dedupe and throttling verified
- delivery success rates meet targets

## Module 12: Messaging (DM and Channels)
Title: Implement Messaging Core (DM and Channels)

Owner: @messaging
Files:
- backend/messaging/thread_service.dart
- backend/messaging/message_service.dart
- backend/messaging/moderation_hooks.dart

APIs:
- POST /messages/send
- GET /threads/{userId}
- POST /messages/report

Data:
- threads
- messages
- read_receipts
- message_flags

Tests:
- ordering and concurrency tests
- report and moderation hook tests
- throughput load tests

Release gate:
- ordering correctness validated under load
- abuse reporting routed to moderation queue

## Module 13: Live Event Orchestration
Title: Implement Live Event Orchestration

Owner: @live-ops
Files:
- backend/live/scheduler.dart
- backend/live/session_manager.dart
- infra/live/failover_worker.ps1

APIs:
- POST /live/schedule
- POST /live/start
- POST /live/stop
- GET /live/status/{eventId}

Data:
- live_events
- stream_sessions
- stream_health

Tests:
- failover chaos tests
- reconnect and recovery tests

Release gate:
- automatic failover and recovery within thresholds

## Module 14: Creator Monetization Core
Title: Implement Creator Monetization Core

Owner: @creator-monetization
Files:
- backend/creator/monetization_service.dart
- backend/creator/subscription_worker.dart

APIs:
- POST /creator/subscribe
- POST /creator/tip
- POST /creator/bundle
- GET /creator/earnings/{creatorId}

Data:
- subscriptions
- tips
- bundles
- creator_offers

Tests:
- recurring billing tests
- cancellation and refund tests
- earnings reconciliation tests

Release gate:
- monetization lifecycle validated end-to-end
- earnings reconciliation green daily

## Module 15: Ledger and Payouts
Title: Implement Ledger and Payouts

Owner: @finance
Files:
- backend/finance/ledger_service.dart
- backend/finance/payout_worker.dart

APIs:
- POST /ledger/entry
- POST /payouts/create
- GET /payouts/status/{batchId}

Data:
- ledger_entries
- payout_batches
- payout_attempts
- disputes

Tests:
- accounting invariant tests
- payout retry/failure tests
- reconciliation tests

Release gate:
- balanced ledger on staging ledger replay
- payout retries and failures handled correctly
