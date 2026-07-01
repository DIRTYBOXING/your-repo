# DFC PPV One-Click Rollback

## Purpose

Fast operational rollback for DFC commerce surfaces when PPV trust is at risk.

Use this when any of the following occur:

- Posters missing or returning 404/403
- Entitlement latency breach
- Playback gate failing for paid users
- Commerce UI drift into non-professional styling

## Emergency Posture

Required feature posture:

- FEATURE_SHELL_V2=false
- FEATURE_PLAY_SKIN=false
- FEATURE_PPV_STORE=true

These values are now enforced by:

- scripts/run_with_env.ps1
- scripts/flutter_web_debug_state.ps1

## 5-Minute Rollback Sequence

### 1) Force emergency feature posture

Run app in real lane with emergency posture:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts/run_with_env.ps1 -Action run -Mode real
```

For F5 debug lane, regenerate debug state:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts/flutter_web_debug_state.ps1 -Action prepare -Mode real -DebugProfile web_real
```

### 2) Verify entitlement runtime

```powershell
node scripts/ppv_runtime_readiness_check.mjs
```

### 3) Verify Mux auth

```powershell
node scripts/smoke_mux_auth.mjs --base-url "https://australia-southeast1-datafightcentral.cloudfunctions.net"
```

### 4) Run poster + player smoke

```powershell
npm run test:visual -- test/visual/player-poster.spec.ts
```

### 5) Restore and prewarm posters if missing

```bash
gsutil cp ./poster.jpg gs://dfc-media-bucket/events/<event>/poster.jpg
gsutil setmeta -h "Cache-Control:public, max-age=31536000" gs://dfc-media-bucket/events/<event>/poster.jpg
```

```bash
curl -X POST "https://cdn-api.provider.com/purge" \
  -H "Authorization: Bearer $CDN_API_KEY" \
  -d '{"paths":["/events/<event>/*","/assets/posters/<event>/*"]}'
```

```bash
curl -s "https://edge.cdn.dfc.example.com/<event>/master.m3u8" > /dev/null
curl -s "https://edge.cdn.dfc.example.com/<event>/poster.jpg" > /dev/null
```

## Pass Criteria

Rollback lane is considered healthy when:

- Poster smoke returns at least one image 200
- No blocking console errors on event page
- Entitlement readiness check passes
- Mux auth smoke passes
- Player starts for entitled session

## How To Find The Failing Workflow Run

1. Open Actions for this repo: `https://github.com/<OWNER>/<REPO>/actions`
2. Click the `PPV Staging Gate` workflow.
3. Copy the failing run link.
4. Run URL pattern:

```text
https://github.com/<OWNER>/<REPO>/actions/runs/<RUN_ID>
```

5. Paste the run link into the incident thread and include the failing step logs.

## Manual-Approval Emergency Flag Flip

Use this only after human approval from the Event Commander.

```bash
curl -X POST "https://flags-api.dfc.example.com/flip" \
  -H "Authorization: Bearer ${FLAG_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"FEATURE_SHELL_V2":false,"FEATURE_PLAY_SKIN":false,"FEATURE_PPV_STORE":true}'
```

Record the API response and post it to the ops thread.

## Incident Message Templates

### Gate Started

```text
#ops PPV Gate started
Workflow: PPV Staging Gate
Commit: <COMMIT_SHA>
Triggered by: <USER>
Run URL: https://github.com/<OWNER>/<REPO>/actions/runs/<RUN_ID>
Checks: entitlement, mux, poster, playwright
```

### Gate Failed

```text
ALERT: PPV Gate FAILED
Run: https://github.com/<OWNER>/<REPO>/actions/runs/<RUN_ID>
Failing step: <step name>
Immediate actions:
1) Post failing logs here
2) Infra: check entitlement health and GCS access
3) Streaming: check mux auth and packager
4) Frontend: check poster URL and selectors
Pager: @sre-oncall @streaming-eng @frontend
```

### Gate Passed

```text
PPV Gate PASSED - staging is healthy for promotion
Run: https://github.com/<OWNER>/<REPO>/actions/runs/<RUN_ID>
Next: proceed with canary rollout or manual promotion
```

### Internal

```text
ALERT: [CRITICAL] DFC PPV rollback activated for <EVENT>
Cause: <one-line reason>
Actions: emergency flags enforced, entitlement check, mux auth smoke, poster restore lane
Next update: <time>
```

### Customer

```text
We identified and fixed a service issue affecting event visuals and playback reliability.
Purchases remain safe. If your access still appears incorrect, contact support with your purchase email.
```

## Ownership

- Event Commander: decision owner
- Streaming Operator: ingest/CDN/player
- Commerce Owner: checkout/entitlements
- SRE Owner: runtime readiness and rollback execution
