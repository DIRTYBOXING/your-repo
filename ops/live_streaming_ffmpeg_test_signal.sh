#!/usr/bin/env bash
set -euo pipefail

# Pushes a synthetic test signal to RTMP ingest.
# Usage:
#   bash ops/live_streaming_ffmpeg_test_signal.sh rtmp://<input-host>/<stream-key>

RTMP_URL="${1:-${FFMPEG_RTMP_URL:-}}"

if [[ -z "$RTMP_URL" ]]; then
  echo "Usage: bash ops/live_streaming_ffmpeg_test_signal.sh <rtmp-url>" >&2
  echo "Or set FFMPEG_RTMP_URL env var." >&2
  exit 2
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ERROR: ffmpeg not found" >&2
  exit 2
fi

echo "Starting FFmpeg synthetic feed to: $RTMP_URL"
ffmpeg -re \
  -f lavfi -i testsrc=size=1280x720:rate=30 \
  -f lavfi -i sine=frequency=1000:sample_rate=44100 \
  -c:v libx264 -preset veryfast -b:v 2500k \
  -c:a aac -b:a 128k \
  -f flv "$RTMP_URL"
