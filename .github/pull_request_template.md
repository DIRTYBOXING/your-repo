## DFC PR Checklist

### Code and tests
- [ ] Lint passes (`./scripts/lint.sh` or equivalent)
- [ ] Unit tests added/updated and green (`pytest`)
- [ ] Integration/smoke tests added/updated (if affecting APIs, schemas, or flows)
- [ ] Tests run locally and in CI pass

### Observability and alerts
- [ ] If adding/changing endpoints: metrics labels include `service` and `route`
- [ ] If adding alert rules: `PrometheusRule` added under `monitoring/k8s/` with owner labels
- [ ] If adding dashboards: JSON placed under `monitoring/grafana/dashboards/` with `grafana_dashboard` label
- [ ] Alertmanager config updated only with non-secret content

### Security and secrets
- [ ] No secrets committed (use GitHub Secrets and k8s secrets)
- [ ] Webhook endpoints verify signatures (Stripe, etc.)
- [ ] K8s network policies reviewed for new services

### Deployment and rollback
- [ ] `deploy-gke.sh` updated if new services or manifests added
- [ ] Smoke checks updated if query/endpoint changes affect health
- [ ] Rollback plan documented (how to undo if deploy fails)

### Documentation
- [ ] API contracts updated under `docs/architecture/api-contracts.yaml`
- [ ] Service map updated under `docs/architecture/service-map.md`
- [ ] Runbook added in `monitoring/runbooks/` if a new alert or critical path is introduced

### Reviewers
- [ ] Platform engineer approved
- [ ] Service owner approved

### Staging validation
- [ ] Deployed to staging via `workflow_dispatch`
- [ ] Smoke checks passed in Actions logs
- [ ] Metrics/dashboards verified in Grafana
