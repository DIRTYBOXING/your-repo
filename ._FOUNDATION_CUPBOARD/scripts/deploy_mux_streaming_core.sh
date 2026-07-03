#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-datafightcentral}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-4}"
INITIAL_BACKOFF_SECONDS="${INITIAL_BACKOFF_SECONDS:-2}"
LOCK_NAME="${LOCK_NAME:-dfc-mux-deploy-lock}"
DEFAULT_FUNCTIONS=(
  testMuxAuth
  createMuxLiveStream
  resendMuxCredentialPack
  getMuxPlaybackUrl
  disableMuxStream
  getMuxStreamStatus
  getMuxVodReplay
  muxWebhook
)

usage() {
  cat <<'EOF'
Usage: scripts/deploy_mux_streaming_core.sh [--project PROJECT_ID] [--max-attempts N] [--initial-backoff-seconds N] [function ...]

Environment variables:
  PROJECT_ID
  MAX_ATTEMPTS
  INITIAL_BACKOFF_SECONDS
  LOCK_NAME
EOF
}

is_transient_conflict() {
  local output="$1"
  [[ "$output" == *"HTTP Error: 409"* ]] || [[ "$output" == *"unable to queue the operation"* ]] || [[ "$output" == *"resource is being created"* ]]
}

backoff_delay() {
  local attempt="$1"
  local delay="$INITIAL_BACKOFF_SECONDS"
  local exponent=0
  if (( attempt > 1 )); then
    exponent=$((attempt - 1))
  fi
  for ((i=0; i<exponent; i+=1)); do
    delay=$((delay * 2))
    if (( delay >= 30 )); then
      delay=30
      break
    fi
  done
  printf '%s' "$delay"
}

LOCK_PATH="${TMPDIR:-/tmp}/${LOCK_NAME}"

cleanup_lock() {
  rm -rf "$LOCK_PATH"
}

trap cleanup_lock EXIT

if ! mkdir "$LOCK_PATH" 2>/dev/null; then
  echo "Another serialized Mux deploy is already running. Lock path: $LOCK_PATH" >&2
  exit 1
fi

functions=()
while (($# > 0)); do
  case "$1" in
    --project)
      PROJECT_ID="$2"
      shift 2
      ;;
    --max-attempts)
      MAX_ATTEMPTS="$2"
      shift 2
      ;;
    --initial-backoff-seconds)
      INITIAL_BACKOFF_SECONDS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      IFS=',' read -r -a split_names <<< "$1"
      for name in "${split_names[@]}"; do
        if [[ -n "${name// }" ]]; then
          functions+=("${name// /}")
        fi
      done
      shift
      ;;
  esac
done

if ((${#functions[@]} == 0)); then
  functions=("${DEFAULT_FUNCTIONS[@]}")
fi

if (( MAX_ATTEMPTS < 1 )); then
  echo "MAX_ATTEMPTS must be at least 1." >&2
  exit 1
fi

for function_name in "${functions[@]}"; do
  for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt+=1)); do
    echo "Deploying ${function_name} (attempt ${attempt}/${MAX_ATTEMPTS})..."
    set +e
    output=$(firebase deploy --only "functions:${function_name}" --project "$PROJECT_ID" --non-interactive 2>&1)
    status=$?
    set -e
    printf '%s\n' "$output"

    if (( status == 0 )); then
      break
    fi

    if (( attempt < MAX_ATTEMPTS )) && is_transient_conflict "$output"; then
      delay=$(backoff_delay "$attempt")
      echo "Transient deploy conflict for ${function_name}. Retrying after ${delay} seconds." >&2
      sleep "$delay"
      continue
    fi

    echo "Failed to deploy ${function_name}." >&2
    exit "$status"
  done
done

echo 'Mux streaming core deploy completed.'