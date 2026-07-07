## Strategic and Operator Docs

- [docs/DFC_SPINE.md](docs/DFC_SPINE.md): Canonical founder and operator description of the platform spine, service boundaries, and 12-week priorities.
- [docs/ARCHITECTURE_ONE_PAGER.md](docs/ARCHITECTURE_ONE_PAGER.md): One-page deployment and architecture summary for partners, grants, and reviewers.
- [docs/ARCHITECTURE_DIAGRAM.mmd](docs/ARCHITECTURE_DIAGRAM.mmd): Mermaid source for the system diagram.
- [docs/REPO_VS_SPINE_AUDIT.md](docs/REPO_VS_SPINE_AUDIT.md): Prioritized mismatch list between declared platform spine and current code and ops state.
- [docs/FUNDING_CHECKLIST.md](docs/FUNDING_CHECKLIST.md): Funding and application readiness checklist.
- [docs/OPEN_SOURCE_PLAN.md](docs/OPEN_SOURCE_PLAN.md): Public-subset release plan and sponsor-friendly packaging boundary.
- [docs/CAMPAIGNS_PLAN.md](docs/CAMPAIGNS_PLAN.md): Outreach and campaigns execution plan for Google, NVIDIA, and GitHub ecosystem support.

### Diagram rendering

```bash
npm i -g @mermaid-js/mermaid-cli
mmdc -i docs/ARCHITECTURE_DIAGRAM.mmd -o docs/ARCHITECTURE_DIAGRAM.png
```
