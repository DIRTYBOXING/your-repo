#!/usr/bin/env bash
# scripts/run_data_bank_smoke.sh
# Cross-platform (macOS / Linux / WSL) equivalent of run_data_bank_smoke.ps1.
# Usage:
#   ./scripts/run_data_bank_smoke.sh [--no-playwright] [--keep-servers]
#   DATA_BANK=/custom/path ./scripts/run_data_bank_smoke.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

DATA_BANK="${DATA_BANK:-${HOME}/dfc-data-bank}"
FIXTURE_SOURCE="${FIXTURE_SOURCE:-${REPO_ROOT}/test/fixtures/smoke.mp4}"
FIXTURE_PORT="${FIXTURE_PORT:-9000}"
WEB_PORT="${WEB_PORT:-8088}"
NO_PLAYWRIGHT=false
KEEP_SERVERS=false

for arg in "$@"; do
  case "$arg" in
    --no-playwright) NO_PLAYWRIGHT=true ;;
    --keep-servers)  KEEP_SERVERS=true ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

FIXTURES_DIR="${DATA_BANK}/fixtures"
REPORTS_DIR="${DATA_BANK}/reports"
LOGS_DIR="${DATA_BANK}/logs"

mkdir -p "$FIXTURES_DIR" "$REPORTS_DIR" "$LOGS_DIR"

FIXTURE_TARGET="${FIXTURES_DIR}/smoke.mp4"

ensure_fixture() {
  if [[ -f "$FIXTURE_SOURCE" ]]; then
    cp -f "$FIXTURE_SOURCE" "$FIXTURE_TARGET"
    log "Fixture copied from repo: $FIXTURE_SOURCE"
  elif command -v ffmpeg &>/dev/null; then
    log "Fixture not found in repo; generating tiny MP4 with ffmpeg"
    ffmpeg -f lavfi -i "testsrc=duration=1:size=320x240:rate=5" \
           -c:v libx264 -pix_fmt yuv420p -t 1 -y "$FIXTURE_TARGET" &>/dev/null
  else
    log "Fixture missing and ffmpeg unavailable; writing placeholder file"
    printf 'dfc-media-smoke-placeholder' > "$FIXTURE_TARGET"
  fi
}

ensure_fixture

sha256sum "$FIXTURE_TARGET" > "${FIXTURE_TARGET}.sha256"
log "Fixture checksum written: ${FIXTURE_TARGET}.sha256"

FIXTURE_SERVER_PID=""
WEB_SERVER_PID=""

cleanup() {
  if [[ "$KEEP_SERVERS" == "false" ]]; then
    [[ -n "$FIXTURE_SERVER_PID" ]] && kill "$FIXTURE_SERVER_PID" 2>/dev/null || true
    [[ -n "$WEB_SERVER_PID"   ]] && kill "$WEB_SERVER_PID"   2>/dev/null || true
    log "Local servers stopped"
  else
    log "Servers kept running: fixture PID=${FIXTURE_SERVER_PID} web PID=${WEB_SERVER_PID}"
  fi
}
trap cleanup EXIT

wait_for_port() {
  local host="$1" port="$2" timeout="${3:-20}"
  local start
  start=$(date +%s)
  while true; do
    if bash -c ">/dev/tcp/${host}/${port}" 2>/dev/null; then
      return 0
    fi
    if (( $(date +%s) - start >= timeout )); then
      return 1
    fi
    sleep 0.3
  done
}

log "Starting fixture server: http://127.0.0.1:${FIXTURE_PORT}"
python3 -m http.server "$FIXTURE_PORT" --directory "$FIXTURES_DIR" \
  >"${LOGS_DIR}/fixture-server.out.log" 2>"${LOGS_DIR}/fixture-server.err.log" &
FIXTURE_SERVER_PID=$!

wait_for_port 127.0.0.1 "$FIXTURE_PORT" 20 \
  || { log "ERROR: Fixture server failed to start on port ${FIXTURE_PORT}"; exit 1; }

WEB_DIR="${REPO_ROOT}/web"
log "Starting web server: http://127.0.0.1:${WEB_PORT}"
python3 -m http.server "$WEB_PORT" --directory "$WEB_DIR" \
  >"${LOGS_DIR}/web-server.out.log" 2>"${LOGS_DIR}/web-server.err.log" &
WEB_SERVER_PID=$!

wait_for_port 127.0.0.1 "$WEB_PORT" 20 \
  || { log "ERROR: Web server failed to start on port ${WEB_PORT}"; exit 1; }

PLAYWRIGHT_EXIT=0

if [[ "$NO_PLAYWRIGHT" == "false" ]]; then
  log "Running promoter Playwright smoke against local web server"
  export PLAYWRIGHT_BASE_URL="http://127.0.0.1:${WEB_PORT}"
  node "${REPO_ROOT}/node_modules/playwright/cli.js" \
    test test/visual/promoter_how_we_work.spec.ts --project=desktop || PLAYWRIGHT_EXIT=$?
fi

STAMP="$(date -u +%Y%m%d-%H%M%S)"

if [[ -d "${REPO_ROOT}/playwright-report" ]]; then
  REPORT_ZIP="${REPORTS_DIR}/promoter-playwright-report-${STAMP}.zip"
  (cd "${REPO_ROOT}" && zip -qr "$REPORT_ZIP" playwright-report/)
  log "Archived report: $REPORT_ZIP"
fi

if [[ -d "${REPO_ROOT}/test-results" ]]; then
  RESULTS_ZIP="${REPORTS_DIR}/promoter-test-results-${STAMP}.zip"
  (cd "${REPO_ROOT}" && zip -qr "$RESULTS_ZIP" test-results/)
  log "Archived results: $RESULTS_ZIP"
fi

FIXTURE_HASH="$(sha256sum "$FIXTURE_TARGET" | awk '{print $1}')"
SUMMARY_PATH="${REPORTS_DIR}/local-smoke-summary-${STAMP}.json"
cat >"$SUMMARY_PATH" <<JSON
{
  "generatedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "fixtureUrl": "http://127.0.0.1:${FIXTURE_PORT}/smoke.mp4",
  "baseUrl": "http://127.0.0.1:${WEB_PORT}",
  "fixtureSha256": "${FIXTURE_HASH}",
  "playwrightRun": $([ "$NO_PLAYWRIGHT" == "false" ] && echo "true" || echo "false")
}
JSON
log "Summary written: $SUMMARY_PATH"
log "Data-bank smoke run complete"

exit "$PLAYWRIGHT_EXIT"
