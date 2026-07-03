# DFC Runtime Verification

Purpose: give operators and developers one repeatable lane for validating the local PPV runtime before running a rehearsal, touching production config, or claiming the entitlement proxy is ready.

## What this covers

- local entitlement proxy startup
- local runtime readiness evaluation
- entitlement proxy smoke validation
- protection against accidentally falling through to the production Functions URL during local checks

## Local verification sequence

Run these from the repo root:

```powershell
npm --prefix entitlements-service start
node scripts/ppv_runtime_readiness_check.mjs
npm --prefix entitlements-service run test:smoke
```

## Expected results

- `node scripts/ppv_runtime_readiness_check.mjs` exits `0` only when:
  - the local entitlement env vars are present
  - `PPV_FUNCTIONS_BASE_URL` is set or Firebase emulator env vars are active
  - the configured entitlement proxy responds with `status = ready`
- `npm --prefix entitlements-service run test:smoke` prints `compat proxy smoke passed`

## Required local env vars

These names are used by the standalone entitlement proxy and by the readiness check:

- `STRIPE_SECRET`
- `STRIPE_WEBHOOK_SECRET`
- `JWT_PRIVATE_KEY`
- `JWT_PUBLIC_KEY`
- `DRM_LICENSE_URL`

These transport values keep local verification off the production Functions URL:

- `PPV_FUNCTIONS_BASE_URL`
- `PPV_PROJECT_ID`
- `PPV_REGION`
- `ENTITLEMENTS_SERVICE_BASE_URL`

## Redis boundary

The smoke lane does not require a live Redis install. The local compatibility smoke uses the app factory and test doubles where appropriate.

If you boot the standalone entitlement service directly, the service may still expect installed runtime dependencies such as `ioredis`. That is an environment issue, not a readiness-script failure.

## VS Code tasks

These tasks are now the canonical local verification lane:

- `PPV: Start Entitlement Proxy`
- `PPV: Smoke Entitlement Proxy`
- `PPV: Runtime Readiness Check`
- `PPV: Runtime Readiness Success Harness`
- `PPV: Verify Entitlement + Mux Runtime`
- `PPV: Priority 1 Verification Lane`

## Success-path harness

Use the harness when you need to prove the readiness script can go green locally without booting the full standalone entitlement CLI path.

```powershell
node scripts/ppv_runtime_readiness_success_harness.mjs
```

The harness starts the entitlement proxy app factory in-process, injects the JTI-store test double, runs the readiness check in the same event loop, then shuts the server down cleanly.

## Failure interpretation

- `defaultsToProduction = true`
  - local verification is about to target the deployed Functions URL
  - set `PPV_FUNCTIONS_BASE_URL` or enable Firebase emulator env vars first
- `requestError = fetch failed`
  - the local entitlement proxy is not reachable at the configured base URL
- `localMissing` contains values
  - the local entitlement env is incomplete
- `/ready` returns `not_ready`
  - the entitlement proxy is up but the configured runtime inputs are incomplete
