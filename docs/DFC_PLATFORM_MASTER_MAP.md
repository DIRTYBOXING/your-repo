# DFC Platform Master Map

Canonical blueprint for how Google, GitHub, NVIDIA, MCP, and DFC core controls fit together.

## Executive model

- **Google** = production backend + cloud platform + AI services
- **GitHub** = source of truth + CI/CD + quality governance
- **NVIDIA** = advanced compute/simulation acceleration tier (current/future)
- **MCP** = local AI tooling interface (non-production)

## Layered architecture

```mermaid
flowchart TB
    UI[DFC Flutter Platform\nPPV / Admin / Promoter / Creator / SmartCoach / Media]

    subgraph G[Google Pillar (Production Runtime)]
      FB[Firebase\nFirestore / Storage / Auth / Functions / Rules / App Check]
      GCP[GCP\nCloud Run / Cloud Build / Secret Manager / IAM / BigQuery / Vertex AI]
      GAI[Google AI\nGemini testing + prompt workflows]
    end

    subgraph GH[GitHub Pillar (Engineering Runtime)]
      REPO[Repository Source of Truth]
      CI[GitHub Actions\nCI + quality gates]
      GOV[Branch Protection + PR process]
      SEC[Security\nSecret scan / dependency scanning]
    end

    subgraph NV[NVIDIA Pillar (Acceleration Tier)]
      OMNI[Omniverse / simulation]
      CUDA[CUDA + TensorRT acceleration]
      NVAI[Heavy model training / advanced inference]
    end

    subgraph LOCAL[Local Tooling Plane]
      CLINE[Cline / AI Assistant]
      MCP[MCP Servers\nFilesystem / Git / Firebase Admin / Terminal / Custom]
    end

    UI --> FB
    UI --> GCP
    FB --> GCP
    GAI --> GCP

    REPO --> CI
    CI --> GOV
    CI --> SEC

    CLINE --> MCP
    MCP --> REPO
    MCP --> FB

    GCP --> NV
```

## Pillar responsibilities

### 1) Google pillar (production)

Primary responsibilities:
- App backend and data plane
- Identity, rules, storage, serverless execution
- Analytics and scalable cloud services
- AI service integration at runtime where needed

Core services in DFC context:
- Firebase Auth, Firestore, Storage, Functions, App Check, Remote Config
- Cloud Run, BigQuery, Vertex AI, Secret Manager, IAM

### 2) GitHub pillar (engineering + governance)

Primary responsibilities:
- Repository source of truth
- Automation, CI/CD, quality enforcement
- Change governance and release safety

Required DFC checks:
- `DFC CI / analyze + tests`
- `DFC Sonar Quality Gate / sonar scan + quality gate`
- `DFC Routing Spine Check / forbid literal navigation routes`
- `DFC Firebase Security Check / firestore/storage policy checks`
- `DFC Rule Pack Check / rule pack + routing discipline`

### 3) NVIDIA pillar (acceleration)

Primary responsibilities:
- High-performance compute and simulation workloads
- Advanced model acceleration and future realtime analytics

Typical DFC-aligned capabilities:
- Simulation (training/fight analysis scenarios)
- GPU-accelerated inference and model optimization
- Heavy-duty future ML pipelines

## MCP placement (important boundary)

MCP belongs to the **local tooling plane** only.

MCP does:
- Assist local engineering workflows
- Connect AI assistants to repo/files/git/terminal/Firebase-admin actions

MCP does **not**:
- Host DFC backend
- Replace Firebase or GCP
- Replace CI/Sonar/routing/rulepack enforcement
- Run production traffic

## Control hierarchy (authoritative order)

1. Branch protection and required checks
2. CI workflows and quality/security gates
3. Rule pack + routing spine constraints
4. Code review and PR checklist discipline
5. Local tooling assistance (MCP/Cline)

If local tooling fails, platform correctness is still enforced by items 1-4.

## Decision statements

- Firebase/GCP remain DFC’s real backend and cloud runtime.
- GitHub remains DFC’s engineering truth and release governor.
- NVIDIA remains DFC’s acceleration and simulation partner tier.
- MCP remains optional local plumbing to improve engineering speed.

This separation is intentional and required for a resilient, professional-grade platform.
