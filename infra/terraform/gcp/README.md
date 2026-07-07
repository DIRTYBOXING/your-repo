# DFC GCP Control Plane — Terraform (UNPROVISIONED)

## ⚠️ STATUS: Not Applied

This Terraform configuration has **never been applied** to the `datafightcentral` project. It exists as an aspirational design for:

- GKE Autopilot cluster (`dfc-autopilot`)
- Pub/Sub telemetry topics (`dfc-wearable-telemetry`, `dfc-overlay-commands`)
- Cloud Run overlay service (`dfc-overlay-service`)
- Service account (`dfc-cloud-run-sa`)

## Decision Required

| Option | Action |
|--------|--------|
| **Provision** | `terraform init && terraform apply -var="project_id=datafightcentral"` |
| **Deprecate** | Delete this directory or move to `archive/` |
| **Keep as reference** | Document as design-only (current state) |

## Prerequisites (if provisioning)

- GCP project: `datafightcentral`
- Billing enabled
- APIs: compute, container, run, pubsub, cloudbuild, artifactregistry, monitoring, logging, dataflow, aiplatform
- Terraform state bucket: `gs://dfc-terraform-state/mcp-control-plane`

## Cost Estimate

| Resource | Est Monthly Cost |
|----------|-----------------|
| GKE Autopilot (minimal) | ~$73 |
| Cloud Run (1-10 instances) | ~$10-50 |
| Pub/Sub (light telemetry) | ~$5 |
| Artifact Registry | ~$2 |
| **Total** | **~$90-130/month** |

## Owners

See CODEOWNERS for review requirements.
