#!/usr/bin/env bash
set -euo pipefail

ORIGIN="srt://ORIGIN_IP:9999?pkt_size=1316"
INPUT="${1:-test-source.mp4}"

if [ ! -f "${INPUT}" ]; then
  echo "Input file ${INPUT} not found. Please provide a local mp4 file or record one."
  exit 1
fi

ffmpeg -re -i "${INPUT}" \
  -c:v libx264 -preset veryfast -tune zerolatency -g 60 -keyint_min 60 -sc_threshold 0 -bf 0 \
  -b:v 3500k -maxrate 4000k -bufsize 8000k \
  -c:a aac -b:a 128k \
  -f mpegts "${ORIGIN}"
