# Mux Deploy Runbook

## Purpose

This runbook keeps Mux secret rotation and Functions rollout serialized, retryable, and verifiable.

## Standard deploy path

1. Update Secret Manager versions for `MUX_TOKEN_ID`, `MUX_TOKEN_SECRET`, `MUX_SIGNING_KEY_ID`, `MUX_SIGNING_PRIVATE_KEY`, and `MUX_WEBHOOK_SECRET`.
2. Run the serialized wrapper:
   - Windows: `pwsh -ExecutionPolicy Bypass -File scripts/deploy_mux_streaming_core.ps1 -ProjectId datafightcentral`
   - POSIX/CI: `scripts/deploy_mux_streaming_core.sh --project datafightcentral`
3. Run verification:
   - `pwsh -ExecutionPolicy Bypass -File scripts/verify_mux_streaming_core.ps1 -ProjectId datafightcentral -Region australia-southeast1 -MuxBaseUrl https://australia-southeast1-datafightcentral.cloudfunctions.net`
4. Promote only if verification reports all functions `ACTIVE` and the Mux auth smoke returns `"ok": true`.

## What matters operationally

- Deploys must be serialized. The wrapper uses a local lock and retries transient `409` queue conflicts with backoff.
- The correct fix for the observed `409` errors is orchestration, not secret rewriting.
- Verification must check both function state and exact secret version bindings before calling the rollout complete.

## CI/CD contract

- Use `.github/workflows/mux-serial-deploy.yml` for manual or controlled Mux rollouts.
- Keep GitHub Actions `concurrency` enabled so only one Mux deploy runs per project.
- Do not run ad hoc comma-separated `firebase deploy --only functions:...,...` commands. That path was the brittle one.

## Preflight checklist

- `FIREBASE_TOKEN` and `GCP_SA_KEY` are present in GitHub Actions.
- Secret Manager contains the intended latest versions.
- The operator knows the target `project_id`, `region`, and `mux_base_url`.

## Postflight checklist

- `testMuxAuth`, `createMuxLiveStream`, `resendMuxCredentialPack`, `getMuxPlaybackUrl`, `disableMuxStream`, `getMuxStreamStatus`, `getMuxVodReplay`, and `muxWebhook` are all `ACTIVE`.
- Each function is bound to the expected secret versions.
- `scripts/smoke_mux_auth.mjs` returns `"ok": true`.

## Incident response

### Deploy collision or repeated `409`

1. Stop starting new deploys.
2. Check current state with:
   - `gcloud functions describe FUNCTION_NAME --gen2 --region australia-southeast1 --project datafightcentral --format="json(serviceConfig.secretEnvironmentVariables,state,updateTime)"`
3. If the function is already `DEPLOYING`, wait for the control plane to finish before retrying.
4. If the function becomes `ACTIVE` with expected secret bindings, do not redeploy it again.

### Secret exposure

1. Revoke the exposed secret at the upstream provider.
2. Create a new Secret Manager version.
3. Run the serialized deploy workflow.
4. Run verification and record the bound versions.
5. Remove any old secret material from local files and operator notes.

## Recommended alerts

- Alert on Cloud Functions deploy failures.
- Alert on repeated `409` spikes during deploy windows.
- Alert if any Mux function remains non-`ACTIVE` past the expected rollout window.
- Alert if post-deploy verification detects stale secret bindings.
