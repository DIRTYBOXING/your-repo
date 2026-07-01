#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <image>  (e.g. entitlements-service:latest)"
  exit 1
fi

IMAGE_IN="$1"
NAME="$(echo "$IMAGE_IN" | sed 's/:.*//')"
TAG="$(echo "$IMAGE_IN" | sed -n 's/.*:\(.*\)/\1/p')"
if [ -z "$TAG" ]; then TAG=latest; fi

OWNER="${GHCR_OWNER:-$(git config --get github.user || echo "${GITHUB_ACTOR:-owner}") }"
FULL=ghcr.io/${OWNER}/${NAME}:$TAG

if ! docker info >/dev/null 2>&1; then
  echo "Docker not running or not accessible"
  exit 1
fi

if ! docker pull "$FULL" >/dev/null 2>&1; then
  echo "Local image not found as $FULL. Attempting to find local tag $IMAGE_IN"
fi

if [ -z "${GHCR_TOKEN:-}" ]; then
  echo "GHCR_TOKEN not set; will prompt for token to login (not saved)."
  read -p "GitHub username: " USER
  read -s -p "GHCR token: " TOKEN && echo
  echo "$TOKEN" | docker login ghcr.io -u "$USER" --password-stdin
else
  echo "Logging using GHCR_TOKEN from environment"
  USER="${GHCR_USER:-${GITHUB_ACTOR:-$(git config --get github.user || echo "owner")}}"
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$USER" --password-stdin
fi

echo "Pushing $FULL"
docker push $FULL

echo "Push complete"
