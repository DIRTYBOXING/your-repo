#!/usr/bin/env bash
# Generate a SHA256 manifest for all files in an incident directory.
# Usage: ./generate_manifest.sh <incident_dir>
set -euo pipefail

INCIDENT_DIR="$1"
if [ -z "$INCIDENT_DIR" ]; then
  echo "Usage: $0 <incident_dir>"
  exit 1
fi

if [ ! -d "$INCIDENT_DIR" ]; then
  echo "Error: $INCIDENT_DIR is not a directory"
  exit 1
fi

MANIFEST="$INCIDENT_DIR/manifest.sha256"
echo "# SHA256 Manifest — $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$MANIFEST"
echo "# Directory: $INCIDENT_DIR" >> "$MANIFEST"
echo "" >> "$MANIFEST"

for f in "$INCIDENT_DIR"/*; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "manifest.sha256" ] && continue
  sha256sum "$f" >> "$MANIFEST"
done

echo "Manifest written to $MANIFEST"
cat "$MANIFEST"
