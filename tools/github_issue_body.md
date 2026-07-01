**Summary**
Chukya 3.0 (Pink Shield Proximity Radar) is ready for controlled pilot. This issue requests legal sign-off, police partner confirmation, and budget approval.

**One-page sign-off bundle**
File: docs/pilot_signoffs/Chukya3_SignOff_Bundle_OnePage.txt (attached to this issue)

**Artifacts**

- Repo commit: `d6fdf3d2` (branch `maps/precompute-cluster-icons`)
- Nightly CI: `.github/workflows/chukya-nightly-admin.yml` (Workload Identity)
- Staging CI: `.github/workflows/deploy-chukya-staging.yml`
- Incident runbook: `ops/incident-runbook-chukya.md`
- Smoke tests: `tools/smoke_all.sh`
- Asserting tests: `tools/inject_chukya_assert_admin.js`

**Acceptance criteria**

1. Legal Counsel sign-off added as a comment.
2. Police partner confirms service account and test call success.
3. Budget approved and recorded.
4. Nightly asserting tests green for 3 consecutive runs.
5. Feature flag `settings/feature_flags.chukya_enabled` remains false until joint test.

**Checklist**

- [ ] Legal sign-off attached
- [ ] Police partner confirmation attached
- [ ] Budget approved
- [ ] SRE readiness confirmed
- [ ] Nightly tests passing (3 runs)
- [ ] Pilot SOP accepted by police liaison

**Reviewers**
@legal @police-liaison @sre-lead @mobile-lead @backend-lead @product-lead

**Requested start date**
[proposed pilot start date]

**Approval comment format**
`Approved — [Name] [Date]`
