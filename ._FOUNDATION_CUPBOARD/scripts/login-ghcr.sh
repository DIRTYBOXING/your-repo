#!/usr/bin/env bash
set -euo pipefail

# Login to GitHub Container Registry using GHCR_TOKEN or interactive input.
if [ -z "${GHCR_TOKEN:-}" ]; then
  echo "GHCR_TOKEN environment variable not set."
  read -p "Enter GHCR token (will not be saved to disk): " -s INPUT_TOKEN
  echo
  TOKEN="$INPUT_TOKEN"
else
  TOKEN="$GHCR_TOKEN"
fi

if [ -z "${GITHUB_USERNAME:-}" ]; then
  read -p "Enter your GitHub username: " USERNAME
else
  USERNAME="$GITHUB_USERNAME"
fi

echo "Logging into ghcr.io as $USERNAME..."
echo "$TOKEN" | docker login ghcr.io -u "$USERNAME" --password-stdin
echo "Login successful."
