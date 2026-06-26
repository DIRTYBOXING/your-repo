---
name: Deletion / Removal Review
about: Use this template when your PR removes files, directories, or significant blocks of code.
title: "chore(delete): "
labels: deletion-review
---

## What is being deleted

<!-- List every file, directory, or code block that is being removed. Be specific. -->

| Path / Symbol | Reason for removal |
|---|---|
|   |   |

---

## Verification that nothing depends on it

- [ ] Searched all imports and references — zero hits
- [ ] `bash scripts/cleanup_scan.sh` ran — potential-unused list reviewed
- [ ] Checked Firestore rules, Cloud Functions, and CI configs for any reference
- [ ] Verified no external package or service consumes this code

---

## Data impact

- [ ] No Firestore collection, document, or field is dropped (or migration doc linked below)
- [ ] No user-facing API or route is removed without a deprecation notice

Migration doc / issue: <!-- link or N/A -->

---

## Rollback plan

<!-- How would we restore this code if something breaks post-merge? -->

---

## Owner approvals required

> **Deletion PRs require at least one explicit owner approval before merge.**

- [ ] Owner of the affected domain has reviewed and approved
- [ ] SRE / infra sign-off (if deleting infra scripts, CI jobs, or deployment configs)
