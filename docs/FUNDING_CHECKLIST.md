# FUNDING CHECKLIST — Data Fight Central

## Purpose
Checklist and artifacts to prepare when applying for cloud credits, hardware grants, ecosystem programs, and sponsor-backed campaigns.

## Core artifacts
- [ ] One-page project summary (PDF plus markdown)
- [ ] Technical architecture diagram (PNG plus editable source)
- [ ] Resource needs statement (monthly GCP plus GPU estimate)
- [ ] 3 to 6 month roadmap with milestones
- [ ] Demo runbook for local and Cloud Run usage
- [ ] Public demo subset with mocked secrets
- [ ] License, contribution, and security policy docs
- [ ] CI/CD explainer for [.github/workflows/dfc-backend-deploy.yml](c:/Data-Fight-Central-safe-bridge/.github/workflows/dfc-backend-deploy.yml)
- [ ] Secret inventory and redaction checklist

## Repo readiness
- [ ] No embedded secrets in code, docs, or workflow examples
- [ ] No proprietary datasets or customer data in public artifacts
- [ ] Reproducible local run path with mocked configuration
- [ ] Clear setup instructions and smoke-test commands
- [ ] Basic tests for public modules
- [ ] Architecture diagram and current screenshots

## Program-specific requirements

### NVIDIA
- [ ] One-page GPU use case describing inference and benchmark targets
- [ ] Model size, throughput, latency, and utilization targets
- [ ] CPU baseline versus GPU benchmark plan
- [ ] Containerized inference demo plan

### Google Cloud
- [ ] Monthly spend estimate and credit burn plan
- [ ] Service-by-service usage plan for Cloud Run, Artifact Registry, Firestore, Storage, and AI APIs
- [ ] Production readiness summary with uptime and deploy flow
- [ ] Team background and contact details

### GitHub Sponsors and ecosystem support
- [ ] Public roadmap with sponsor-friendly milestones
- [ ] Open-source subset and maintenance boundaries
- [ ] Sponsor tiers, benefits, and use-of-funds statement
- [ ] Security disclosure contact and response policy

## Outreach artifacts
- [ ] Outreach email templates for NVIDIA, Google, and GitHub ecosystem contacts
- [ ] One-page PDF attachment
- [ ] Public demo link or sandbox environment
- [ ] Campaign calendar and owner list

## Recommended timeline
- Day 0 to 3: finalize one-pager, architecture, resource-needs statement
- Day 3 to 7: publish public subset, security policy, and CI/CD explainer
- Day 7 to 14: submit NVIDIA and Google applications, launch sponsor campaign
- Week 3 to 4: run follow-up outreach and demos

## Owners
- Technical lead: DFC
- Outreach owner: assign named contact
- OSS packaging owner: assign named contact
- Campaign owner: assign named contact
