# Claude Opus Cost Control & Governance Checklist

## Budget & Monitoring
- [ ] Set **monthly usage cap** in Claude API billing console (recommend: $200-500/month for DFC)
- [ ] Enable **billing alerts** at 50%, 75%, 90% of cap
- [ ] Review **weekly usage reports** to identify runaway calls
- [ ] If budget exceeded: **revoke API key immediately** until root cause is found

## Scope Restrictions
- [ ] **ALLOW**: Infra automation (Terraform, IAM, GCP commands)
- [ ] **ALLOW**: CI/CD pipeline fixes and workflow edits
- [ ] **ALLOW**: Bulk repo safety scans (gitleaks, corruption scans)
- [ ] **DENY**: Direct code edits to `lib/`, `dfc_frontend/`, UI files
- [ ] **DENY**: Merge commits without human review
- [ ] **DENY**: IAM or security-critical changes without second approver

## PR Automation Policy
- [ ] All Opus-created PRs must be labeled `automation`
- [ ] Require **1 non-author approver** for automation PRs
- [ ] CI must pass **AI Corruption Guard** + **flutter analyze** before merge
- [ ] Never auto-merge automation PRs

## Cost Reduction Options
| Option | Est Savings | Effort |
|--------|-------------|--------|
| **Batch tasks** — combine multiple runs into one session | 30-50% | Low |
| **Use smaller models** (e.g., Claude Haiku, GPT-4o-mini) for simple tasks | 70-90% | Low |
| **Self-hosted LLM** (Ollama + Llama 3) for templated infra | 95%+ | Medium |
| **Replace Opus with scripts** for repetitive tasks (bash/Python) | 100% | Medium |
| **Terraform modules** — pre-built, no LLM needed per deployment | 100% | High (one-time) |

## Fallback Stack (if Opus budget exhausted)
```bash
# Self-hosted LLM for infra templating
ollama pull llama3:70b
ollama run llama3:70b "Generate Terraform for GKE Autopilot cluster"

# Scripted alternatives
./scripts/rotate_keys.sh          # Key rotation (pre-written)
./scripts/detect_ai_corruption.sh # AI corruption scan (pre-written)
./scripts/supply_chain_fix.sh     # Lockfile + SBOM regeneration
```

## Monthly Audit Checklist
- [ ] Review all Opus-created PRs for quality
- [ ] Check billing dashboard for anomalies
- [ ] Rotate API key if any concern
- [ ] Review `.gitleaks.toml` false-positive annotations
- [ ] Confirm branch protection rules still active
