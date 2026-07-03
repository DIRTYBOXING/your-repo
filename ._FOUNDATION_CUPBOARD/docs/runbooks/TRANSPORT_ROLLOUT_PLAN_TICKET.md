# Transport Rollout Plan Ticket

## Title

TRANSPORT-001 Phase 1 to Phase 3 Realtime Transport Rollout

## Owner Matrix

- Primary owner: Platform Engineering
- Supporting owners: Frontend, SRE, Streaming Engineering
- Stakeholders: Product, QA

## Timeline

- Phase 1 (WebSocket baseline): 2026-04-22 to 2026-05-10
- Phase 2 (WebTransport pilot cohort): 2026-05-13 to 2026-06-10
- Phase 3 (Regional expansion): 2026-06-12 to 2026-07-15

## Scope

- Keep WebSocket as default production transport.
- Ship transport abstraction for client and gateway routing.
- Run WebTransport only under feature flag for selected cohorts.
- Enforce automatic fallback to WebSocket.

## Acceptance Criteria

1. Transport abstraction merged and used by realtime client path.
2. WebSocket gateway exposes /health and /ready endpoints with telemetry fields.
3. Transport smoke CI job passes on staging gate workflow.
4. Playwright fallback smoke validates readiness and WebSocket ping/pong path.
5. Rollout dashboards include fallback rate and latency percentiles by transport.

## Required Metrics

- Connection success rate by transport >= 99.5%
- Message roundtrip p95 <= 300ms
- Reconnect frequency <= 2 per user-hour
- Fallback rate from WebTransport to WebSocket <= 1%
- Gateway error rate <= 0.5%

## Exit Criteria By Phase

### Phase 1 Exit

- WebSocket baseline SLOs stable for 7 consecutive days.
- Transport abstraction deployed without user-facing regressions.

### Phase 2 Exit

- WebTransport pilot enabled for <= 5% cohort.
- Pilot meets connection and latency SLOs for 14 consecutive days.
- Automatic fallback verified across at least two network conditions.

### Phase 3 Exit

- WebTransport cohort expansion completed region-by-region.
- Alerting and rollback automation verified in staging and production.

## Risks and Mitigations

- Risk: Browser incompatibility in pilot cohorts.
  - Mitigation: strict capability detection and server-side feature flags.
- Risk: Higher handshake failures on HTTP/3 path.
  - Mitigation: fallback threshold and per-region rollout gates.
- Risk: Observability gaps for datagram behavior.
  - Mitigation: dedicated transport dashboards and failure sampling.

## Deliverables

- Runtime abstraction in packages/transport
- ws-gateway production stub with health/readiness
- transport-smoke CI lane
- Playwright transport-fallback smoke
- Rollout dashboard and alert bindings
