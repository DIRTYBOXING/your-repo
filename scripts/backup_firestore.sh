#!/usr/bin/env bash
# scripts/backup_firestore.sh — Export Firestore to GCS bucket
# Usage:
#   export PROJECT_ID=datafightcentral
#   bash scripts/backup_firestore.sh
set -euo pipefail

PROJECT_ID="${PROJECT_ID:?PROJECT_ID env var required}"
BUCKET="${BACKUP_BUCKET:-gs://${PROJECT_ID}-firestore-backups}"
DATE=$(date +"%Y-%m-%d-%H%M")
DEST="${BUCKET}/${DATE}"

echo "═══════════════════════════════════════════════════"
echo "  DFC Firestore Backup → $DEST"
echo "═══════════════════════════════════════════════════"

# Ensure bucket exists
gsutil ls "$BUCKET" &>/dev/null || gsutil mb -l australia-southeast1 "$BUCKET"

gcloud firestore export "$DEST" --project="$PROJECT_ID"

echo ""
echo "✓ Backup complete: $DEST"
echo "  Restore with: gcloud firestore import $DEST --project=$PROJECT_ID"
