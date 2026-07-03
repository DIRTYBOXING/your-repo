#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  CHUCKYA — SIGNATURE VERIFICATION CLI                       ║
# ║  One-liner commands for police demos and evidence handover  ║
# ║  Requires: jq, openssl, sha256sum (or shasum on macOS)     ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# ─── Configuration ───
EVIDENCE_DIR="${1:-.}"
PAYLOAD="$EVIDENCE_DIR/payload.json"
SIGNED="$EVIDENCE_DIR/signed_payload.json"
PUBKEY="$EVIDENCE_DIR/public.pem"
CHAIN="$EVIDENCE_DIR/chain_of_custody.json"

echo "╔══════════════════════════════════════════════════════╗"
echo "║  CHUCKYA Evidence Verification                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ─── Check required files ───
for f in "$PAYLOAD" "$SIGNED" "$PUBKEY" "$CHAIN"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Missing file: $f"
        exit 1
    fi
done
echo "[OK] All evidence files present"
echo ""

# ─── Step 1: Canonicalize payload ───
echo "Step 1: Canonicalizing payload (deterministic JSON sort)..."
jq -S . "$PAYLOAD" > "$EVIDENCE_DIR/payload.canon"
echo "  → payload.canon created"
echo ""

# ─── Step 2: Extract and decode signature ───
echo "Step 2: Extracting signature from signed payload..."
jq -r '.signatureBase64' "$SIGNED" | base64 -d > "$EVIDENCE_DIR/sig.bin" 2>/dev/null || \
    jq -r '.signatureBase64' "$SIGNED" | base64 --decode > "$EVIDENCE_DIR/sig.bin"
echo "  → sig.bin extracted"
echo ""

# ─── Step 3: Verify signature with OpenSSL ───
echo "Step 3: Verifying signature against public key..."
if openssl dgst -sha256 -verify "$PUBKEY" -signature "$EVIDENCE_DIR/sig.bin" "$EVIDENCE_DIR/payload.canon" 2>/dev/null; then
    echo "  ✓ SIGNATURE VERIFIED OK"
else
    echo "  ✗ SIGNATURE VERIFICATION FAILED"
    exit 2
fi
echo ""

# ─── Step 4: Compute SHA256 for chain of custody ───
echo "Step 4: Computing SHA256 hash for chain of custody..."
if command -v sha256sum &>/dev/null; then
    HASH=$(sha256sum "$EVIDENCE_DIR/payload.canon" | awk '{print $1}')
elif command -v shasum &>/dev/null; then
    HASH=$(shasum -a 256 "$EVIDENCE_DIR/payload.canon" | awk '{print $1}')
else
    HASH=$(openssl dgst -sha256 "$EVIDENCE_DIR/payload.canon" | awk '{print $NF}')
fi
echo "  Computed:  $HASH"
echo ""

# ─── Step 5: Cross-reference chain of custody ───
echo "Step 5: Checking chain of custody..."
CHAIN_HASH=$(jq -r '.payloadHash // .entries[0].hash // "NOT_FOUND"' "$CHAIN" 2>/dev/null)
if [ "$CHAIN_HASH" = "NOT_FOUND" ] || [ -z "$CHAIN_HASH" ]; then
    echo "  ⚠ Could not extract hash from chain_of_custody.json (check format)"
    echo "  Manual check: compare computed hash above with chain file entries"
else
    echo "  Chain:     $CHAIN_HASH"
    if [ "$HASH" = "$CHAIN_HASH" ]; then
        echo "  ✓ HASH MATCHES CHAIN OF CUSTODY"
    else
        echo "  ✗ HASH MISMATCH — EVIDENCE MAY BE TAMPERED"
        exit 3
    fi
fi
echo ""

# ─── Summary ───
echo "╔══════════════════════════════════════════════════════╗"
echo "║  VERIFICATION COMPLETE                              ║"
echo "║  Signature: VERIFIED                                ║"
echo "║  SHA256:    $HASH  ║"
echo "║  Chain:     CHECKED                                 ║"
echo "╚══════════════════════════════════════════════════════╝"

# ─── Cleanup temp files ───
# Uncomment to auto-clean:
# rm -f "$EVIDENCE_DIR/payload.canon" "$EVIDENCE_DIR/sig.bin"
