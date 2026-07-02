# GitHub Sponsors & Open Source Strategy

## 1. Vision & Core Philosophy

Data Fight Central (DFC) believes in a **Hybrid Open Core** model. While our proprietary, high-concurrency stream processors, custom video rendering engines (Octane), and closed matching algorithms remain securely compiled as part of block platform operations, we are committed to open-sourcing our core security, idempotency, and experimentation primitives.

By publishing these elements to GitHub, we aim to establish the global software standard for creator monetisation, progressive rollout gating, and athlete wellness tracking. In turn, we seek to leverage **GitHub Sponsors** and corporate sponsorship to support our open-source maintainers and accelerate software engineering efforts.

---

## 2. Open-Source Repositories Plan

We will decouple the following isolated modules from our staging branch (`hardening/release-2026-07-02`) and publish them as verified stand-alone repositories:

### Repository A: `dfc-idempotency-mesh` (Node.js/Express)
* **What it is**: The high-performance payments webhook pipeline from our `backend/payments` directory.
* **Why it matters**: It provides a highly portable, Express-compatible middleware solution capable of persisting raw webhooks, locking duplicate sessions natively, and executing multi-statement operations inside a single PostgreSQL transaction pool.
* **Key Features**: Fallback fetch injections, idempotent order checking, and verified payload normalizations.

### Repository B: `dfc-deterministic-experiments` (Dart / Flutter)
* **What it is**: The core experimentation engine verified in `backend/experiments`.
* **Why it matters**: It is a framework-agnostic, memory-safe Dart library that provides deterministic user-to-variant hashing stable across app restarts.
* **Key Features**: Seeded RNG weighting, config versioning controls, exposure logging triggers, and microsecond-level execution bounds.

### Repository C: `dfc-canary-guard` (DevOps YAML / Bash)
* **What it is**: Our progressive rollout gating and CI pipeline rules from `.github/workflows/payments-ci.yml`.
* **Why it matters**: A highly reproducible, security-focused pipeline template designed to run Dockerized DB bootstraps, analyze files, scan production dependencies, and execute deep rollback-empty test sweeps securely.

---

## 3. GitHub Sponsors Tiers & Incentives

We will launch a formal **GitHub Sponsors Campaign** structured across individual and corporate contribution tiers:

| Sponsor Tier | Monthly Contribution | Primary Benefit |
|---|---|---|
| **Supporter** | $5 / month | Public badge on profile; inclusion in `CONTRIBUTORS.md`. |
| **Elite Developer** | $50 / month | Direct access to DFC core Discord, early beta feature flags access, and input into our feature prioritisation boards. |
| **Pink Shield Gym Sponsor**| $250 / month | Sponsors 1 certified "Gym Not Jail" youth diversion scholarship at a local combat sports gym. Includes branding on global map nodes. |
| **Corporate Sponsor** | $1,000 / month | 2 hours/month of dedicated technical support for setting up the idempotent payments mesh; branding on GitHub README pages. |
| **Enterprise Sovereign** | $5,000 / month | Dedicated SRE setup consulting for GKE pipelines; prime sponsorship spot on the central DFC landing page and partner decks. |

---

## 4. Immediate Outbox outreach Cadence

When presenting this open-source blueprint to GitHub Partner Managers, use the following messaging template to pitch collaboration:

### GitHub sponsors Program Pitch Template
```markdown
Subject: Technical Pilot Proposal - Open Core Idempotency Systems for Social Impact

Hi [Name],

I am the Platform Lead of Data Fight Central (DFC). We have built Hybrid Meta 5: a modular creator monetisation and athlete protection platform (preview available under `docs/pages/dfc_reality_portal.html`).

We are preparing to open-source our underlying core security primitives as stand-alone packages under the DFC Open Core Initiative:
- `dfc-idempotency-mesh` (High-performance transaction locking for Postgres)
- `dfc-deterministic-experiments` (Deterministic user variant allocator for Flutter)

Given GitHub's deep support for open-source sustainability and social impact, we would love to schedule a brief 15-minute call to discuss:
1. Integration with the GitHub Sponsors program to fuel our Queensland "Gym Not Jail" at-risk youth scholarships.
2. Technical review of our advanced pre-commit security gates and dependency scanners.
3. Feature on the GitHub Open Source Blog highlighting technology-backed social redirection.

Would you be available for a brief discussion this Thursday or Friday? I can share a one-page tech schematic and our cohorted rollout roadmap.

Best regards,  
DFC Platform Lead  
https://github.com/DIRTYBOXING/your-repo
```
