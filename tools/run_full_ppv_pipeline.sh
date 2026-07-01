#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# DFC PPV Master Pipeline
# ═══════════════════════════════════════════════════════════════════════════
# One-shot script that:
#   1. Verifies event JSONs exist
#   2. Generates typographic posters (safe to publish without permissions)
#   3. Optionally uploads to CDN
#   4. Updates event JSON asset URLs if CDN configured
#   5. Generates promoter outreach emails
#   6. Commits and pushes everything
#
# Usage:
#   chmod +x tools/run_full_ppv_pipeline.sh
#   ./tools/run_full_ppv_pipeline.sh
#
# Prerequisites: bash, jq, ImageMagick (convert), git
# ═══════════════════════════════════════════════════════════════════════════

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ── CONFIGURE THESE BEFORE RUNNING ──────────────────────────────────────
GIT_REMOTE_BRANCH="maps/precompute-cluster-icons"
CDN_UPLOAD_CMD=""                # e.g. "aws s3 cp --acl public-read" or "rclone copy"
CDN_BASE_URL=""                  # e.g. "https://cdn.datafightcentral.com/ppv"
GITHUB_USER_NAME="dfc-bot"
GITHUB_USER_EMAIL="bot@datafightcentral.com"
# ────────────────────────────────────────────────────────────────────────

EVENTS_DIR="data/events"
GENERATOR="tools/generate_ppv_posters_gritty.sh"
EMAILS_DIR="tools/promoter_emails"
ASSETS_DIR="assets/ppv"

echo "═══════════════════════════════════════════════════════"
echo "  DFC PPV MASTER PIPELINE"
echo "═══════════════════════════════════════════════════════"
echo ""

# ── Step 1: Verify prerequisites ────────────────────────────────────────
echo "Step 1: Checking prerequisites..."
for cmd in jq convert git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' not found. Install it before running."
    exit 1
  fi
done

if [ ! -f "$GENERATOR" ]; then
  echo "ERROR: Generator script not found at $GENERATOR"
  exit 1
fi
chmod +x "$GENERATOR"

# ── Step 2: Verify event JSONs ──────────────────────────────────────────
echo "Step 2: Checking event JSONs in $EVENTS_DIR ..."
EVENT_COUNT=$(find "$EVENTS_DIR" -name '*.json' | wc -l)
echo "  Found $EVENT_COUNT event JSON files."

if [ "$EVENT_COUNT" -eq 0 ]; then
  echo "ERROR: No event JSONs found in $EVENTS_DIR"
  exit 1
fi

# ── Step 3: Generate posters ────────────────────────────────────────────
echo ""
echo "Step 3: Generating posters for all events..."
mkdir -p "$ASSETS_DIR"

GENERATED=0
FAILED=0
for f in "$EVENTS_DIR"/*.json; do
  eventId=$(jq -r '.eventId' "$f")
  hero="$ASSETS_DIR/${eventId}_hero.jpg"

  if [ -f "$hero" ]; then
    echo "  SKIP: $eventId (hero already exists)"
    continue
  fi

  echo "  GENERATING: $eventId"
  if "$GENERATOR" "$f"; then
    GENERATED=$((GENERATED + 1))
  else
    echo "  WARN: Failed to generate for $eventId"
    FAILED=$((FAILED + 1))
  fi
done
echo "  Generated: $GENERATED  Skipped existing  Failed: $FAILED"

# ── Step 4: CDN upload (optional) ───────────────────────────────────────
echo ""
if [ -n "$CDN_UPLOAD_CMD" ] && [ -n "$CDN_BASE_URL" ]; then
  echo "Step 4: Uploading to CDN..."
  for img in "$ASSETS_DIR"/*.jpg "$ASSETS_DIR"/*.png "$ASSETS_DIR"/*.webp; do
    [ -f "$img" ] || continue
    echo "  Uploading $(basename "$img")"
    $CDN_UPLOAD_CMD "$img" "$CDN_BASE_URL/$(basename "$img")"
  done

  echo "  Updating event JSONs with CDN URLs..."
  for f in "$EVENTS_DIR"/*.json; do
    id=$(jq -r '.eventId' "$f")
    jq --arg base "$CDN_BASE_URL" --arg id "$id" \
      '.assets.heroUrl = ($base + "/" + $id + "_hero.jpg") |
       .assets.thumbUrl = ($base + "/" + $id + "_thumb.jpg") |
       .assets.bannerUrl = ($base + "/" + $id + "_banner.jpg") |
       .assets.portraitUrl = ($base + "/" + $id + "_portrait.jpg") |
       .assets.previewUrl = ($base + "/" + $id + "_preview.jpg")' \
      "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  done
else
  echo "Step 4: SKIP — CDN_UPLOAD_CMD not configured. Posters stay in $ASSETS_DIR/"
fi

# ── Step 5: Generate promoter outreach emails ───────────────────────────
echo ""
echo "Step 5: Generating promoter outreach emails..."
mkdir -p "$EMAILS_DIR"

for f in "$EVENTS_DIR"/*.json; do
  eventId=$(jq -r '.eventId' "$f")
  title=$(jq -r '.title' "$f")
  promoter=$(jq -r '.promoter // "Promoter"' "$f")
  contact=$(jq -r '.contact // "unknown"' "$f")
  price=$(jq -r '.price // "TBD"' "$f")

  email_file="$EMAILS_DIR/${eventId}_email.txt"

  if [ -f "$email_file" ]; then
    echo "  SKIP: $eventId (email already exists)"
    continue
  fi

  cat > "$email_file" <<EOF
To: ${contact}
Subject: Asset & Event Key Request — ${title} — DFC Pink Shield

Hi ${promoter},

I'm Heath from DataFight Central (DFC) / Pink Shield. We're preparing a Pay-Per-View listing for ${title} and would love to promote and sell the event on our platform.

Could you please provide:
- Official high-res hero poster and portrait poster (min 1600x2400)
- Fighter headshots (high resolution)
- Sponsor logos (transparent PNG)
- Official event copy, venue, start time, and approved legal text
- Written license or confirmation that DFC may distribute and sell the PPV digitally
- Event key or API token (if you use one) and any required metadata fields

We'll credit ${promoter} and can send a draft poster for approval before publishing. Please send assets and license to legal@datafightcentral.com.

Thanks for partnering — we'll promote across our app and social channels with respectful, non-trolling community guidelines.

Regards,
Heath
Product Lead, DFC Pink Shield
EOF
  echo "  CREATED: $email_file"
done

# ── Step 6: Verify generated assets ────────────────────────────────────
echo ""
echo "Step 6: Asset inventory..."
HERO_COUNT=$(find "$ASSETS_DIR" -name '*_hero.jpg' 2>/dev/null | wc -l)
THUMB_COUNT=$(find "$ASSETS_DIR" -name '*_thumb.jpg' 2>/dev/null | wc -l)
EMAIL_COUNT=$(find "$EMAILS_DIR" -name '*_email.txt' 2>/dev/null | wc -l)
echo "  Hero posters:  $HERO_COUNT"
echo "  Thumbnails:    $THUMB_COUNT"
echo "  Email drafts:  $EMAIL_COUNT"

# ── Step 7: Commit and push ─────────────────────────────────────────────
echo ""
echo "Step 7: Committing and pushing..."
git config user.name "$GITHUB_USER_NAME"
git config user.email "$GITHUB_USER_EMAIL"

git add "$EVENTS_DIR"/*.json \
        "$ASSETS_DIR"/* \
        "$EMAILS_DIR"/* \
        docs/legal/* \
        .github/workflows/* \
        functions/* \
        2>/dev/null || true

if git diff --cached --quiet; then
  echo "  No new changes to commit."
else
  git commit -m "Pipeline: add PPV posters, promoter emails, legal templates, and CI actions"
  git push origin "$GIT_REMOTE_BRANCH"
  echo "  Committed and pushed."
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  PIPELINE COMPLETE"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Review generated posters in $ASSETS_DIR/"
echo "  2. Set CDN_UPLOAD_CMD + CDN_BASE_URL and re-run for CDN upload"
echo "  3. Deploy functions/sendPromoterEmail.js to your cloud provider"
echo "  4. Send promoter emails from $EMAILS_DIR/ (or let serverless handle it)"
echo "  5. Store signed licenses in docs/legal/"
echo "  6. Test PPV purchase flow in staging"
