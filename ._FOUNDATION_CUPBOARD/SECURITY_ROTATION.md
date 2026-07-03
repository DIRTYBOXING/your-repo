# Security Rotation Runbook

## Scope

Use this runbook when gitleaks or incident analysis indicates credentials were committed or exposed.

## Priority order

1. Revoke and rotate payment credentials (Stripe, PayPal).
2. Rotate infrastructure/database credentials.
3. Rotate CI/CD and automation tokens.
4. Rotate any service account keys and webhook secrets.

## Rotation checklist

- [ ] Stripe secret key rotated and old key revoked.
- [ ] Stripe webhook signing secret rotated.
- [ ] PayPal client secret rotated.
- [ ] Database credentials rotated.
- [ ] Firebase/service account credentials rotated.
- [ ] GitHub Actions/CI tokens rotated.
- [ ] Environment stores updated (GitHub Secrets, cloud secret manager, runtime env).
- [ ] Runtime restarted/redeployed to pick up new credentials.

## History purge workflow

1. Confirm all exposed keys are rotated before history rewrite.
2. Remove leaked material using git-filter-repo or BFG.
3. Force-push cleaned refs.
4. Instruct contributors to re-clone or hard-reset to cleaned refs.

## Validation

1. Run branch-delta gitleaks scan and confirm zero findings.
2. Run full-history gitleaks scan and confirm historical leak signatures are removed.
3. Validate payment/webhook integrations with smoke tests.

## Incident communication template

INCIDENT: credential exposure remediation in progress

- Detection time: <timestamp>
- Exposed systems: <stripe/paypal/db/ci>
- Rotation owner: <name>
- Keys rotated: <list>
- History purge status: <pending/in-progress/completed>
- Validation status: <pending/passed>
