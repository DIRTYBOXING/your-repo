# DFC Developer Onboarding

Purpose: get a new developer productive in the DFC workspace without rediscovering the PPV runtime lane, local verification expectations, or the repo's split between Flutter, Functions, and the standalone entitlement proxy.

## First-day setup

1. Install the core tooling:
   - VS Code
   - Flutter and Dart SDKs
   - Node.js
   - Firebase CLI
2. Open the repo root in VS Code.
3. Copy `.env.example` into a local `.env` and populate only the values you actually need for the lane you are working on.
4. Use the existing multi-surface workspace setup rather than opening subfolders in isolation.

## Priority 1 local PPV lane

Before changing entitlement, playback, settlement, or monetization code, run the local PPV verification lane.

### Commands

```powershell
npm --prefix entitlements-service start
node scripts/ppv_runtime_readiness_check.mjs
npm --prefix entitlements-service run test:smoke
```

### VS Code tasks

Run these from the task picker:

- `PPV: Start Entitlement Proxy`
- `PPV: Runtime Readiness Check`
- `PPV: Runtime Readiness Success Harness`
- `PPV: Smoke Entitlement Proxy`
- `PPV: Priority 1 Verification Lane`

## What the readiness check protects

The readiness script is intentionally strict about local transport configuration.

It fails when:

- the local entitlement env is incomplete
- the entitlement proxy is not reachable
- the Functions transport would fall through to the deployed production base URL by default

That guard exists so local PPV verification never silently mutates or depends on deployed infrastructure.

## Redis and local verification

The standalone entitlement service may expect installed runtime dependencies such as `ioredis` when started directly.

The smoke lane itself does not require a live Redis service. Use the existing smoke test and app-factory test doubles for verification instead of widening the local dependency footprint unless you are explicitly working on the Redis-backed JTI path.

If you need to prove the success path locally without the full CLI boot path, run:

```powershell
node scripts/ppv_runtime_readiness_success_harness.mjs
```

That harness keeps startup, `/ready`, and shutdown in one event loop and avoids the Redis boundary by using the existing app-factory test seam.

## Files that matter most for Priority 1

- `entitlements-service/server.js`
- `entitlements-service/tests/smokeCompatProxy.js`
- `scripts/ppv_runtime_readiness_check.mjs`
- `.vscode/tasks.json`
- `docs/DFC_PPV_PUBLIC_READINESS_PLAN.md`
- `docs/DFCalive_OPS_RUNBOOK.md`

## Daily baseline

If you are not changing the backend runtime, the fastest daily loop remains:

1. run the app in demo mode
2. keep touched Flutter files analyzer-clean
3. use the PPV verification lane before claiming any monetization or entitlement change is ready

## Mission Control and storefront runtime wiring

The new flagship Mission Control and PPV storefront surfaces are only fully live
when their Flutter runtime variables are present.

What the app expects:

- `DFC_OPERATOR_FUNCTION_URL`
- `DFC_OPERATOR_ID`
- `DFC_OPERATOR_SECRET`
- `DFC_PPV_STOREFRONT_BASE`
- `DFC_PPV_AUTO_CONFIRM_SANDBOX`

Important safety rule:

- `DFC_OPERATOR_SECRET` is for trusted internal operator builds only
- do not ship that value in a public consumer web build

Recommended local operator run command:

```powershell
flutter run -d windows `
   --dart-define=DFC_OPERATOR_FUNCTION_URL="https://australia-southeast1-datafightcentral.cloudfunctions.net/operatorAction" `
   --dart-define=DFC_OPERATOR_ID="ops_alpha" `
   --dart-define=DFC_OPERATOR_SECRET="replace-with-internal-operator-secret" `
   --dart-define=DFC_PPV_STOREFRONT_BASE="https://australia-southeast1-datafightcentral.cloudfunctions.net" `
   --dart-define=DFC_PPV_AUTO_CONFIRM_SANDBOX=true
```

Recommended public storefront web run/build shape:

```powershell
flutter run -d chrome `
   --dart-define=DFC_PPV_STOREFRONT_BASE="https://australia-southeast1-datafightcentral.cloudfunctions.net" `
   --dart-define=DFC_PPV_AUTO_CONFIRM_SANDBOX=false
```

Why this matters:

- the app checks compile-time defines first
- local `assets/.env` is only a fallback path and may be skipped on web/release
- if the base URLs are missing, Mission Control falls back to demo behavior and the storefront cannot hit the live payment endpoints
