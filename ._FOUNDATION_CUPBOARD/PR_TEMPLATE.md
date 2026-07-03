## Summary

- What: Nightly wallet reconciliation job, admin endpoints, metrics, alerts, and deploy assets.
- Why: Ensure wallet ledger integrity and automated reconciliation with alerting.
- How: Node job + Redis lock, systemd and k8s manifests, Prometheus rules, and dashboards.

## PR Readiness Checklist

- [ ] Tests: all unit and integration tests pass locally and in CI.
- [ ] Playwright: smoke suite passes in CI across at least Chromium and one other browser.
- [ ] Secrets: gitleaks reports zero findings for this branch.
- [ ] Dependency health: npm audit has no critical vulnerabilities in runtime paths.
- [ ] CI status checks: required checks pass (unit tests, lint, Playwright smoke, gitleaks, dependency scan).
- [ ] Branch protection: master requires PR review and passing checks.
- [ ] Code review: at least one reviewer approved critical files (payments, webhooks, reconciliation, metrics, deploy manifests).
- [ ] Changelog: added entry describing reconciliation job and operational assets.
- [ ] Release tag: release tag prepared after merge (example: v1.12.0).
