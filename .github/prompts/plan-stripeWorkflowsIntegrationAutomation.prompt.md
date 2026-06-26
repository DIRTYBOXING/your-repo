---
mode: ask
description: Plan Stripe workflow integration and automation for Data Fight Central
---

# Stripe Workflow Integration Automation

Use this prompt to produce a practical plan for DFC Stripe workflow wiring.

Return these sections:

1. `currentStripeSurface`
2. `requiredSecrets`
3. `workflowMap`
4. `webhookFlow`
5. `verificationLane`
6. `riskFlags`

Guardrails:

- Treat Stripe as the money plane.
- Keep Firebase and GCP as the control plane.
- Prefer repeatable local testing over one-off manual steps.
- Call out any workflow that depends on missing secrets, webhooks, or redirect URLs.
