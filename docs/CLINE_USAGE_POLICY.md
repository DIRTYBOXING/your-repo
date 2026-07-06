# DFC Cline Usage Policy

This policy defines how Cline is used in DFC.

## Scope

Cline is a **local developer assistant** only.

Cline is **not** part of:

- GitHub Actions CI
- Sonar quality gates
- Firebase runtime security rules
- Production runtime architecture
- Branch protection enforcement

## Non-negotiable boundaries

- Do not add Cline-specific requirements to CI workflows.
- Do not declare Cline as a production dependency.
- Do not gate merges on Cline availability.
- Do not treat Cline credits/model access as a deployment dependency.

## Model policy (stability-first)

To avoid workflow interruption, configure Cline with free/fallback model options when needed:

- Groq-backed free models
- DeepSeek free models
- Gemini Flash free tier (where available)
- Local models

Principle: **Cline availability must never block DFC engineering or release flow.**

## Required repo integrations (tool-agnostic)

Engineering quality is enforced by repository-native controls:

- CI checks in `.github/workflows/*.yml`
- Sonar quality gate workflow
- Routing spine workflow checks
- Firebase security checks
- Rule-pack checks
- PR template process

These controls remain valid regardless of local assistant choice.

## Team workflow expectations

- Use Cline to accelerate edits, sweeps, and refactors.
- Validate with analyzer/tests and required GitHub checks.
- Follow `docs/DFC_SONAR_RULE_PACK.md` and `docs/DFC_MODULE_SWEEP_CHECKLIST.md`.
- Treat local assistant output as draft until repository checks pass.

## Incident behavior

If Cline/model access is unavailable:

1. Continue development with standard IDE + terminal workflow.
2. Run analyzer/tests locally.
3. Open PR and rely on required CI checks.
4. Merge only when all required checks pass.

No emergency architecture changes are permitted solely due to assistant availability.
