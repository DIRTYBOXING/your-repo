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

echo "Building $FULL from local folder ./$NAME"
if [ ! -d "$NAME" ]; then
  echo "Directory ./$NAME not found. Build from current folder instead."
  docker build -t $FULL .
else
  docker build -t $FULL ./$NAME
fi

echo "Built $FULL"
echo "$FULL"
