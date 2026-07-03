#!/usr/bin/env bash
# ops/create-cloudbuild-trigger.sh
# ─────────────────────────────────────────────────────────────────────────────
# Creates two Cloud Build triggers for the DFC repo:
#   1. dfc-pr-check  — runs cloudbuild-pr-check.yaml on every PR targeting master
#   2. dfc-deploy    — runs cloudbuild.yaml on every push to master
#
# Then sets the required status check on the master branch via GitHub API.
#
# Prerequisites:
#   - gcloud CLI authenticated (gcloud auth login / ADC)
#   - GITHUB_TOKEN env var with repo + admin:repo_hook scopes
#   - Cloud Build GitHub App installed on the repo
#   - PROJECT_ID, GITHUB_ORG, GITHUB_REPO env vars (or edit defaults below)
#
# Usage:
#   export PROJECT_ID=your-gcp-project
#   export GITHUB_ORG=DIRTYBOXING
#   export GITHUB_REPO=Data-Fight-Central
#   export GITHUB_TOKEN=ghp_...
#   bash ops/create-cloudbuild-trigger.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ID="${PROJECT_ID:?Set PROJECT_ID}"
GITHUB_ORG="${GITHUB_ORG:-DIRTYBOXING}"
GITHUB_REPO="${GITHUB_REPO:-Data-Fight-Central}"
GITHUB_TOKEN="${GITHUB_TOKEN:?Set GITHUB_TOKEN}"
REGION="${REGION:-global}"

INCLUDED_SERVICE_FILES="poster-worker/**,promotion-worker/**,entitlements-service/**,libs/**,cloudbuild.yaml"

echo "── Creating PR check trigger (dfc-pr-check) ──────────────────────────────"
gcloud beta builds triggers create github \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --name="dfc-pr-check" \
  --repo-owner="${GITHUB_ORG}" \
  --repo-name="${GITHUB_REPO}" \
  --pull-request-pattern="^master$" \
  --build-config="ops/cloudbuild-pr-check.yaml" \
  --included-files="${INCLUDED_SERVICE_FILES}" \
  --comment-control=COMMENTS_ENABLED || echo "  ↳ trigger may already exist — skipping"

echo ""
echo "── Creating master deploy trigger (dfc-deploy) ───────────────────────────"
gcloud beta builds triggers create github \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --name="dfc-deploy" \
  --repo-owner="${GITHUB_ORG}" \
  --repo-name="${GITHUB_REPO}" \
  --branch-pattern="^master$" \
  --build-config="cloudbuild.yaml" \
  --included-files="${INCLUDED_SERVICE_FILES}" || echo "  ↳ trigger may already exist — skipping"

echo ""
echo "── Setting GitHub branch protection on master ────────────────────────────"
# Requires: repo admin token
curl -s -X PUT \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/branches/master/protection" \
  -d @- <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "dfc-ci:ent-audit",
      "dfc-ci:tsc-poster",
      "dfc-ci:tsc-promotion",
      "dfc-ci:flutter",
      "dfc-ci:docker-entitlements",
      "dfc-ci:docker-poster-worker",
      "dfc-ci:docker-promotion-worker"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

echo ""
echo "── Verifying protection ──────────────────────────────────────────────────"
curl -s \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/branches/master/protection" \
  | python3 -c "
import json, sys
p = json.load(sys.stdin)
rsc = p.get('required_status_checks', {})
print('  required_status_checks.strict:', rsc.get('strict'))
print('  contexts:', rsc.get('contexts', []))
reviews = p.get('required_pull_request_reviews', {})
print('  required_approving_review_count:', reviews.get('required_approving_review_count'))
print('  enforce_admins:', p.get('enforce_admins', {}).get('enabled'))
"

echo ""
echo "Done. Open a PR touching poster-worker/ to test the gate."
