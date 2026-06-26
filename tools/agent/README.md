# DFC Observability Agent

## Purpose

Deploys or dry-runs manifests, runs the Dart example to emit telemetry, posts a CI test alert, verifies Alertmanager and Prometheus, and cleans up.

## Quick start

1. Install Dart SDK.
2. From repo root:
   ```
   cd tools/agent
   dart pub get
   dart run bin/agent.dart --alertmanager alertmanager.observability.svc.cluster.local:9093
   ```
3. Use CI to call this agent in staging before production promotion.
