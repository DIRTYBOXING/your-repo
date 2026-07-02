# Experiment Page

## Purpose
Create, version, and audit experiments; deterministic assignment and exposure logging; analysis plan.

## Experiment Template
- `experiment_id`: `exp-<short>`
- `config_version`: integer
- `variants`: JSON with weights
- `start_date`, `end_date`, `primary_metric`, `sample_size`

## Assignment Contract
- Deterministic assignment: `variant = hash(userId|experimentId|configVersion) % 100 < weight`
- Endpoint: `POST /experiments/assign` returns `{variant, configVersion, assignedAt}`

## Exposure Logging
- Endpoint: `POST /experiments/exposure` with `{userId, experimentId, variant, context}`
- Emit `exposure.logged` to event stream after DB commit

## Analysis Plan (Pre-Registered)
- Primary metric: `trial_to_paid_30d`
- Alpha: `0.05`, one primary test
- Minimum sample: computed via formula; default 5k per arm for 10% baseline and 15% relative uplift

## Run Commands

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"experimentId":"exp-1","configVersion":1,"variants":[{"name":"A","weight":50},{"name":"B","weight":50}],"primaryMetric":"trial_to_paid_30d"}' \
  https://platform.internal/experiments

node scripts/assignment_smoke.js --users=10000 --experiment=exp-1
```

## Audit
All changes written to `experiment_audit` with actor and timestamp.

## Owners
- Experiment owner: @growth
- Data analyst: @data

## Acceptance Criteria
- Deterministic assignment stable across restarts for sample set.
- Exposures emitted and visible in analytics pipeline.
