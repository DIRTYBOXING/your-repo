#!/usr/bin/env bash
# =============================================================================
# DFC AI Corruption Detector
# =============================================================================
# Scans all Dart files for AI-generated plain-text fragments prepended to
# source code (common failure mode when automation tools mishandle output).
#
# Usage: ./scripts/detect_ai_corruption.sh
# Exit codes: 0 = clean, 1 = corruption found
# =============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED=0
TOTAL=0

echo "Scanning Dart files for suspicious first lines..."

# Whitelist of valid Dart first-token patterns:
#   //         = comment
#   /*         = block comment start
#   ///        = doc comment
#   import     = import directive
#   export     = export directive
#   library    = library declaration
#   part       = part directive
#   class      = class declaration
#   enum       = enum declaration
#   mixin      = mixin declaration
#   abstract   = abstract class
#   typedef    = typedef
#   final      = top-level final
#   const      = top-level const
#   var        = top-level var
#   void       = function return
#   Future     = async return type
#   Widget     = Flutter widget base
#   @          = annotation
#   BASE       = uppercase (likely a constant/class)
#
# Any line that starts with 3+ lowercase letters followed by a space is
# flagged as suspicious (likely plain-English AI commentary).

VALID_FIRST_LINE_PATTERN='^(//|/\*|///|import |export |library |part |class |enum |mixin |abstract |typedef |final |const |var |void |Future|Widget|@|[A-Z])'

for f in $(git ls-files '*.dart'); do
  TOTAL=$((TOTAL + 1))
  first=$(sed -n '1p' "$f" | sed 's/^[[:space:]]*//')

  if [[ -z "$first" ]]; then
    continue
  fi

  if ! echo "$first" | grep -Eq "$VALID_FIRST_LINE_PATTERN"; then
    # Double-check: is it 3+ lowercase letters (plain English)?
    if echo "$first" | grep -Eiq '^[a-z]{3,}'; then
      echo -e "${RED}SUS:${NC} $f"
      echo "  -> $first"
      FAILED=$((FAILED + 1))
    fi
  fi
done

echo ""
echo "Scanned $TOTAL Dart files."

if [[ $FAILED -gt 0 ]]; then
  echo -e "${RED}$FAILED suspicious file(s) found — possible AI corruption.${NC}"
  exit 1
else
  echo -e "${GREEN}All Dart files pass the first-line integrity check.${NC}"
  exit 0
fi
