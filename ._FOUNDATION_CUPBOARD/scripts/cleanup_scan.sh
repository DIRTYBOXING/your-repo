#!/usr/bin/env bash
# scripts/cleanup_scan.sh
# DFC Repository Health & Dead Code Scanner
# Usage: bash scripts/cleanup_scan.sh [--ci]
# Output: devops/reports/cleanup_scan.log (when redirected)
set -euo pipefail

CI_MODE=0
[[ "${1:-}" == "--ci" ]] && CI_MODE=1

REPORT_DIR="devops/reports"
mkdir -p "$REPORT_DIR"

SEP="================================================================"
warn() { echo "⚠️  $*"; }
ok()   { echo "✅  $*"; }

echo "$SEP"
echo "=== DFC Cleanup Scan — $(date -u '+%Y-%m-%d %H:%M UTC') ==="
echo "$SEP"

# ── 1. Largest tracked files ─────────────────────────────────────────────────
echo ""
echo "── 1. Top 50 largest tracked files ─────────────────────────────────────"
git ls-files | while IFS= read -r f; do
  [[ -f "$f" ]] && printf "%10d %s\n" "$(wc -c < "$f")" "$f"
done | sort -nr | head -n 50 || true

# ── 2. Large untracked / binary files (>500 KB, outside build & .git) ────────
echo ""
echo "── 2. Untracked files > 500 KB ──────────────────────────────────────────"
find . -type f -size +500k \
  -not -path "./.git/*" \
  -not -path "./build/*" \
  -not -path "./node_modules/*" \
  -not -path "./.dart_tool/*" \
  -print | sort || true

# ── 3. TODO / FIXME / DEPRECATED grep ────────────────────────────────────────
echo ""
echo "── 3. TODO / FIXME / DEPRECATED occurrences ────────────────────────────"
grep -RIn \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude-dir=build \
  --exclude-dir=.dart_tool \
  --include="*.dart" \
  --include="*.ts" \
  --include="*.js" \
  --include="*.yaml" \
  --include="*.yml" \
  -E "TODO|FIXME|DEPRECATED" . 2>/dev/null | head -n 80 || true

# ── 4. Flutter / Dart static analysis ────────────────────────────────────────
echo ""
echo "── 4. Flutter analyze ───────────────────────────────────────────────────"
ANALYZE_ERRORS=0
if command -v flutter >/dev/null 2>&1; then
  flutter analyze --no-pub 2>&1 | tee /tmp/flutter_analyze.txt || true
  ANALYZE_ERRORS=$(grep -c "^  error •" /tmp/flutter_analyze.txt 2>/dev/null || echo 0)
  echo "Errors found: $ANALYZE_ERRORS"
  if [[ "$ANALYZE_ERRORS" -gt 0 ]]; then
    warn "Flutter analyze reports $ANALYZE_ERRORS error(s)."
  else
    ok "Flutter analyze: no errors."
  fi
else
  warn "flutter not found — skipping analysis"
fi

# ── 5. JS / TS lint ──────────────────────────────────────────────────────────
echo ""
echo "── 5. npm lint ──────────────────────────────────────────────────────────"
if [[ -f package.json ]]; then
  if node -e "const p=require('./package.json'); process.exit(p.scripts&&p.scripts.lint?0:1)" 2>/dev/null; then
    npm run lint 2>&1 | tail -n 20 || true
  else
    echo "No lint script in package.json — skipping"
  fi
else
  echo "No package.json — skipping"
fi

# ── 6. Depcheck (optional) ───────────────────────────────────────────────────
echo ""
echo "── 6. Unused npm dependencies ───────────────────────────────────────────"
if command -v depcheck >/dev/null 2>&1; then
  depcheck --json > "$REPORT_DIR/depcheck.json" 2>&1 || true
  ok "depcheck output → $REPORT_DIR/depcheck.json"
else
  echo "depcheck not installed — skipping (npm install -g depcheck to enable)"
fi

# ── 7. Files untouched > 2 years ─────────────────────────────────────────────
echo ""
echo "── 7. Dart files not touched in 2+ years ────────────────────────────────"
CUTOFF=$(date -u -d '2 years ago' '+%Y-%m-%d' 2>/dev/null || date -u -v-2y '+%Y-%m-%d')
git log --since="$CUTOFF" --pretty=format: --name-only -- '*.dart' 2>/dev/null \
  | sort -u > /tmp/recently_touched.txt
git ls-files '*.dart' | while IFS= read -r f; do
  if ! grep -qxF "$f" /tmp/recently_touched.txt 2>/dev/null; then
    echo "STALE: $f"
  fi
done | head -n 50 || true

# ── 8. Potential unreferenced Dart files ─────────────────────────────────────
echo ""
echo "── 8. Potentially unreferenced Dart files (best-effort) ─────────────────"
if command -v rg >/dev/null 2>&1; then
  UNUSED_COUNT=0
  git ls-files '*.dart' | while IFS= read -r f; do
    base="${f##*/}"
    stem="${base%.dart}"
    # skip generated, main, and barrel files
    [[ "$base" == *".g.dart" || "$base" == *".freezed.dart" ]] && continue
    [[ "$stem" == "main" || "$stem" == *"_test" ]] && continue
    if ! rg -qn --hidden --no-ignore-vcs \
        --glob '!build/**' --glob '!.git/**' --glob '!.dart_tool/**' \
        -- "(import.*$stem|part.*$stem)" . 2>/dev/null; then
      echo "POTENTIAL-UNUSED: $f"
      UNUSED_COUNT=$((UNUSED_COUNT+1))
    fi
  done
  echo "Scan complete."
else
  echo "ripgrep (rg) not installed — skipping (brew install ripgrep / apt install ripgrep)"
fi

# ── 9. Dart files > 400 lines ────────────────────────────────────────────────
echo ""
echo "── 9. Dart files > 400 lines (refactor candidates) ─────────────────────"
git ls-files '*.dart' | while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  lines=$(wc -l < "$f")
  [[ "$lines" -gt 400 ]] && printf "%6d lines  %s\n" "$lines" "$f"
done | sort -nr | head -n 30 || true

# ── 10. Summary ──────────────────────────────────────────────────────────────
echo ""
echo "$SEP"
echo "=== Scan Summary ==="
echo "  Flutter analyze errors : $ANALYZE_ERRORS"
echo "  Report dir             : $REPORT_DIR"
echo "  Timestamp              : $(date -u '+%Y-%m-%d %H:%M UTC')"
echo "$SEP"

# In CI mode, fail fast if there are Flutter analyze errors
if [[ "$CI_MODE" -eq 1 && "$ANALYZE_ERRORS" -gt 0 ]]; then
  echo "CI mode: failing due to $ANALYZE_ERRORS Flutter analyze error(s)."
  exit 1
fi

echo "Scan complete."
