# DFC Private Repository Bootstrap

**Classification: CONFIDENTIAL**

---

## 1. Purpose

This private repository, `dfc-private`, is the secure vault for all non-public assets of the Data Fight Central (DFC) project. Its purpose is to house sensitive materials that **must not** be exposed in the public-facing open-source repository.

This includes:
- Infrastructure as Code (IaC) with private configurations.
- Deployment scripts and operational runbooks.
- Raw legal documents, contracts, and IP strategy files.
- Private sponsor and investor materials.
- Secrets management pointers and emergency procedures.

**The public repository is for code. This private repository is for operations.**

---

## 2. Access Control

- **Access:** Granted on a strict need-to-know basis to core maintainers, SRE/DevOps leads, and legal/executive personnel only.
- **Branch Protection:** The `main` branch is protected. All changes must be made via Pull Request with at least one reviewer.
- **Authentication:** Multi-Factor Authentication (MFA) is mandatory for all members with access to this repository.

---

## 3. Recommended Folder Structure

```
/
├── 📂 infra/                # Terraform, Helm charts, Kubernetes manifests
├── 📂 deploy/               # Deployment scripts, CI/CD helpers with private values
├── 📂 secrets/              # Pointers to secrets in a vault (e.g., Vault, AWS Secrets Manager). NO RAW SECRETS.
├── 📂 legal/                # Signed contracts, IP plans, NDAs, corporate documents.
│   ├── ip_protection_plan.txt
│   └── ...
├── 📂 runbooks/             # Operational guides, emergency procedures.
│   └── secrets_rotation_runbook.txt
├── 📂 sponsor/              # Private sponsor decks, contracts, and communications.
├── 📂 pilot_docs/           # Sensitive pilot materials (e.g., Chukya sign-offs).
│   └── Chukya3_SignOff_Bundle_Full.txt
├── 📂 marketing/            # Internal marketing strategy and playbooks.
│   └── content_marketing_playbook.txt
└── README.md                # This file.
```

---

## 4. Secrets Handling Policy

**Golden Rule: No raw secrets are ever to be committed to this repository.**

1.  **Vaulting:** All secrets (API keys, service account JSON, private keys, certificates) must be stored in a dedicated secrets manager like HashiCorp Vault, AWS Secrets Manager, or 1Password.
2.  **Repository Content:** This repository should only contain *references* to secrets (e.g., `vault://secret/dfc/stripe-api-key`) or templated configuration files (e.g., `secrets.example.yaml`).
3.  **Rotation:** Follow the schedule and procedures outlined in `runbooks/secrets_rotation_runbook.txt`. Any secret accidentally exposed must be rotated immediately.
4.  **CI/CD Integration:** Workflows in the public repository should pull secrets at runtime from the vault using secure mechanisms like Workload Identity Federation, referencing secrets stored by the infrastructure in this private repo.

---

## 5. Onboarding for New Maintainers

1.  **Request Access:** Be invited by a repository owner.
2.  **Enable MFA:** Ensure MFA is enabled on your GitHub account.
3.  **Sign Agreements:** Sign the necessary NDA and IP assignment agreements, which are stored in the `legal/` directory.
4.  **Get Vault Access:** Request least-privilege access to the secrets manager from the SRE lead.
5.  **Review Key Documents:**
    - Read this `README.md` in its entirety.
    - Review the `runbooks/secrets_rotation_runbook.txt`.
    - Understand the `legal/ip_protection_plan.txt`.

---

## 6. Emergency Procedures

### If a Secret is Leaked in a Commit:

1.  **IMMEDIATELY** rotate the exposed credential in its respective service (e.g., generate a new API key in Stripe).
2.  Follow the history purging guide in `runbooks/secrets_rotation_runbook.txt` using a tool like BFG Repo-Cleaner to remove the secret from Git history.
3.  Force-push the cleaned history to the repository.
4.  Notify the team that the history has been rewritten and credentials have been rotated.

### If CI/CD Logs Expose a Secret:

1.  **IMMEDIATELY** rotate the exposed credential.
2.  Identify and fix the workflow step that is printing the secret.
3.  Purge the logs from the CI/CD provider if possible.

---

## 7. Governance and IP

- **IP Ownership:** As per the `LICENSE` file in the public repo and the `legal/ip_protection_plan.txt`, all Intellectual Property is owned by the designated Trust, not the operating company. This repository contains the operational details of that IP.
- **Review Cadence:** A quarterly review of repository access and secrets policies will be conducted.
- **Change Control:** All infrastructure and deployment changes must go through a PR and be approved by the SRE lead or a designated alternate.

---

## 8. Contact

- **Primary Owner / DevOps Lead:** [Name/Email]
- **Security Lead:** [Name/Email]
- **Legal Counsel:** [Name/Email]

---

This document is the source of truth for the structure and operation of the DFC private repository. Keep it updated as processes evolve.
