#!/usr/bin/env bash
set -euo pipefail

# CHUCKYA Radar — End-to-End Test for Non-Technical Staff
# Validates: ingest → export → signature verification
# Usage:
#   chmod +x tools/e2e_test.sh
#   VERIFIER_URL=http://localhost:8081 PUBLIC_PEM=public.pem ./tools/e2e_test.sh

VERIFIER_URL="${VERIFIER_URL:-http://localhost:8081}"
SIGNED_PAYLOAD="${SIGNED_PAYLOAD:-tools/signed_payload.json}"
PUBLIC_PEM="${PUBLIC_PEM:-public.pem}"
TMPDIR="$(mktemp -d)"
EVIDENCE_ZIP="$TMPDIR/evidence.zip"
EVIDENCE_DIR="$TMPDIR/evidence"

echo "======================================="
echo "  CHUCKYA E2E Test"
echo "======================================="
echo "Verifier : $VERIFIER_URL"
echo "Payload  : $SIGNED_PAYLOAD"
echo "Public key: $PUBLIC_PEM"
echo ""

# Pre-flight checks
if [ ! -f "$SIGNED_PAYLOAD" ]; then
  echo "ERROR: signed payload not found at $SIGNED_PAYLOAD" >&2
  exit 2
fi
if [ ! -f "$PUBLIC_PEM" ]; then
  echo "ERROR: public key not found at $PUBLIC_PEM" >&2
  exit 2
fi

# 1. Ingest
echo "[1/5] Posting signed payload to verifier..."
RESP=$(curl -s -X POST "$VERIFIER_URL/v1/radar/event" \
  -H "Content-Type: application/json" \
  -d @"$SIGNED_PAYLOAD")
ALERT_ID=$(echo "$RESP" | jq -r '.id // empty')

if [ -z "$ALERT_ID" ]; then
  echo "ERROR: verifier did not return an alert id. Response:" >&2
  echo "$RESP"
  exit 3
fi

echo "  Ingested alert id: $ALERT_ID"

# 2. Wait for audit files
echo "[2/5] Waiting for audit artifacts..."
sleep 2

# 3. Request export
echo "[3/5] Requesting export for alert $ALERT_ID..."
HTTP_CODE=$(curl -s -o "$EVIDENCE_ZIP" -w "%{http_code}" \
  -X POST "$VERIFIER_URL/v1/radar/alerts/$ALERT_ID/export")

if [ "$HTTP_CODE" != "200" ] || [ ! -s "$EVIDENCE_ZIP" ]; then
  echo "ERROR: export failed (HTTP $HTTP_CODE)" >&2
  exit 4
fi

mkdir -p "$EVIDENCE_DIR"
unzip -o "$EVIDENCE_ZIP" -d "$EVIDENCE_DIR" >/dev/null

echo "  Evidence extracted to $EVIDENCE_DIR"

# 4. Verify signature
echo "[4/5] Verifying signature..."
jq -S . "$EVIDENCE_DIR/payload.json" > "$EVIDENCE_DIR/payload.canon"
jq -r '.signatureBase64' "$EVIDENCE_DIR/signed_payload.json" | base64 -d > "$EVIDENCE_DIR/sig.bin"

if openssl dgst -sha256 -verify "$PUBLIC_PEM" \
  -signature "$EVIDENCE_DIR/sig.bin" "$EVIDENCE_DIR/payload.canon"; then
  echo "  Signature verified OK"
else
  echo "ERROR: signature verification FAILED" >&2
  exit 5
fi

# 5. Print SHA256 and chain of custody
echo "[5/5] Chain of custody check..."
echo "  Computed SHA256:"
openssl dgst -sha256 "$EVIDENCE_DIR/payload.canon"
echo ""
echo "  Chain of custody:"
jq . "$EVIDENCE_DIR/chain_of_custody.json"

echo ""
echo "======================================="
echo "  E2E Test PASSED"
echo "  Evidence saved in $EVIDENCE_DIR"
echo "======================================="
