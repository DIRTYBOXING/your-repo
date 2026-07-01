# Deprecation Plan

## Pending Deprecation Targets

### 1. `entitlements-service/server.js`

Reason:

- duplicates checkout, order, and entitlement behavior already covered elsewhere

Condition for removal:

- canonical runtime validated in staging and production

### 2. `web/src/ppv.js`

Reason:

- assumes a separate bespoke purchase and entitlement API flow

Condition for removal:

- all web purchase flows routed through the canonical PPV stack

### 3. `lib/services/dfc_payment_client.dart`

Reason:

- assumes a bespoke PPV payments API that is not the canonical runtime

Condition for removal:

- all app callers confirmed on the canonical Firebase Functions path

### 4. PPV checkout path in `dfc-content-pipeline/live-publisher/src/index.js`

Reason:

- should remain a live update publisher, not a second commerce source of truth

Condition for removal:

- canonical purchase path fully verified and no production clients depend on this route

## Removal Rule

No deprecation target should be removed until:

1. staging smoke tests pass against the canonical runtime
2. production telemetry is stable for at least one observation window
3. rollback instructions are documented and tested
