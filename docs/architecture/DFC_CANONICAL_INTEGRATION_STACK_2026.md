# DFC Canonical Integration Stack 2026

Status: Required integration standard for Social + PPV delivery lanes.

## Decision

Use one canonical stack per integration:

Ingest -> Transcode -> Origin -> CDN -> Player and Entitlement -> Payments -> Social and Clips -> AI and Analytics -> Ops and Security.

Primary cloud: GCP (Media CDN + Live Streaming API + Cloud Storage).

AWS equivalents are allowed as alternatives where explicitly noted.

## Canonical matrix

| Layer                  | Primary role                 | GCP canonical                                              | AWS alternative                         | Notes                                            |
| ---------------------- | ---------------------------- | ---------------------------------------------------------- | --------------------------------------- | ------------------------------------------------ |
| Ingest                 | Venue contribution           | SRT or RTMP input to Live Streaming API                    | MediaLive Input                         | Prefer dual-path ingest for premium events       |
| Transcode and packager | ABR renditions and manifests | Live Streaming Channel outputting HLS and DASH to GCS      | MediaLive + MediaPackage                | Keep manifest and segment naming deterministic   |
| Origin and CDN         | Global delivery              | GCS event path + Media CDN endpoint                        | MediaPackage or MediaStore + CloudFront | Start single-CDN; add multi-CDN after rehearsals |
| Player and entitlement | Controlled playback access   | Shaka or platform player + server entitlement token checks | Same                                    | No client-side entitlement authority             |
| Payments               | Purchase and receipt         | Stripe Checkout Sessions + server reconciliation           | Stripe or Adyen + server reconciliation | Idempotent grants only                           |
| Social and clips       | Growth and highlights        | Clip markers -> transcode -> GCS -> CDN + moderation       | Same                                    | Clips isolated from PPV manifest paths           |
| AI and analytics       | Telemetry and ranking        | BigQuery + model serving endpoint                          | Athena or Redshift alternatives         | Do not log secrets or full tokens                |
| Ops and security       | Reliability and trust        | PPV gate + weekly sweep + rollback runbook                 | Same discipline                         | Fail closed on uncertainty                       |

## Interface contract standards

1. Canonical page truth endpoint:
   - `GET /api/events/{id}`
   - Returns only one backend truth payload for poster, price, entitlement requirement, and venue metadata.
2. Token and URL standards:
   - Signed playback URLs and short-lived entitlement tokens.
   - Server-side validation required before unlock.
3. CI standards:
   - Staging promotion blocked unless PPV gate passes.
   - Weekly sweep required during active event windows.

## Required enforcement in this repo

- Gate workflow: `.github/workflows/ppv-staging-gate.yml`
- Weekly sweep: `ops/weekly_sweep.sh`
- Poster checks: `ops/check_posters.sh`
- Mux smoke: `ops/mux_smoke.sh`
- Player smoke: `tests/playwright/player-poster.spec.ts`
- Rollback runbook: `docs/runbooks/DFC_PPV_ONE_CLICK_ROLLBACK.md`

## Promotion evidence

Do not promote unless all evidence exists:

1. Passing gate run URL.
2. Passing weekly sweep output.
3. Entitlement readiness payload with ready true.
4. Poster and CDN checks output with HTTP 200.
5. Playwright smoke output.
