#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# DFC Gritty Urban PPV Poster Generator
# ═══════════════════════════════════════════════════════════════════════════
# Usage: ./tools/generate_ppv_posters_gritty.sh path/to/event.json
#   or:  ./tools/generate_ppv_posters_gritty.sh --all data/events/
#
# Requires: jq, ImageMagick (convert), and optionally a grunge texture at
#           assets/ppv/grunge_texture.png
# ═══════════════════════════════════════════════════════════════════════════

OUT_DIR="assets/ppv"
TMP_DIR="/tmp/ppv_gen"
mkdir -p "$OUT_DIR" "$TMP_DIR"

generate_poster() {
  local EVENT_JSON="$1"

  if [ ! -f "$EVENT_JSON" ]; then
    echo "ERROR: File not found: $EVENT_JSON"
    return 1
  fi

  # ── Parse event JSON ──
  eventId=$(jq -r '.eventId' "$EVENT_JSON")
  title=$(jq -r '.title' "$EVENT_JSON")
  date=$(jq -r '.date' "$EVENT_JSON")
  time=$(jq -r '.time // "TBA"' "$EVENT_JSON")
  price=$(jq -r '.price' "$EVENT_JSON")
  promoter=$(jq -r '.promoter // "DFC"' "$EVENT_JSON")
  sport=$(jq -r '.sport // "MMA"' "$EVENT_JSON")
  subtitle=$(jq -r '.subtitle // empty' "$EVENT_JSON")

  fighter1=$(jq -r '.fighters[0].name // empty' "$EVENT_JSON")
  fighter2=$(jq -r '.fighters[1].name // empty' "$EVENT_JSON")

  # ── Output paths ──
  hero="$OUT_DIR/${eventId}_hero.jpg"
  thumb="$OUT_DIR/${eventId}_thumb.jpg"
  banner="$OUT_DIR/${eventId}_banner.jpg"
  portrait="$OUT_DIR/${eventId}_portrait.jpg"
  preview="$OUT_DIR/${eventId}_preview.jpg"

  bg="$TMP_DIR/${eventId}_bg.png"

  echo "Generating posters for: $title ($eventId)"

  # ── Sport-specific accent color ──
  case "$sport" in
    UFC|MMA)       accent="#ff4444" ;;
    Boxing)        accent="#ffd700" ;;
    BKFC|Brawling) accent="#ff7a18" ;;
    "Muay Thai")   accent="#e91e63" ;;
    Kickboxing)    accent="#9c27b0" ;;
    *)             accent="#ff7a18" ;;
  esac

  # ── Create dark gritty gradient background ──
  convert -size 1600x2400 gradient:'#0b0b0b'-'#1f1f1f' -colorspace sRGB "$bg"

  # ── Optional grunge texture overlay ──
  GRUNGE="assets/ppv/grunge_texture.png"
  if [ -f "$GRUNGE" ]; then
    convert "$bg" "$GRUNGE" -resize 1600x2400! -compose multiply -composite "$bg"
  fi

  # ── Fonts (adjust to installed system fonts) ──
  HEAD_FONT="Impact"
  META_FONT="Arial-Bold"

  # ── Compose hero poster ──
  local photo_left="assets/ppv/${eventId}_photo_left.jpg"
  local photo_right="assets/ppv/${eventId}_photo_right.jpg"

  if [ -f "$photo_left" ] && [ -f "$photo_right" ]; then
    # Fighter photos available — split composition
    convert "$bg" \
      \( "$photo_left" -resize 900x2400^ -gravity west -crop 800x2400+0+0 +repage \
         -modulate 100,80,100 -colorspace sRGB -fill "rgba(0,0,0,0.35)" -colorize 0 \) \
      -geometry +0+0 -composite \
      \( "$photo_right" -resize 900x2400^ -gravity east -crop 800x2400+0+0 +repage \
         -modulate 100,80,100 -colorspace sRGB -fill "rgba(0,0,0,0.35)" -colorize 0 \) \
      -geometry +800+0 -composite \
      -gravity north -fill "$accent" -stroke black -strokewidth 4 \
        -font "$HEAD_FONT" -pointsize 90 -annotate +0+120 "$title" \
      -gravity center -fill white -font "$HEAD_FONT" -pointsize 160 -annotate +0+0 "VS" \
      -gravity center -fill "$accent" -font "$META_FONT" -pointsize 52 \
        -annotate +0-350 "$fighter1" \
      -gravity center -fill "$accent" -font "$META_FONT" -pointsize 52 \
        -annotate +0+350 "$fighter2" \
      -gravity south -fill white -font "$META_FONT" -pointsize 36 \
        -annotate +0+180 "PPV \$${price} • $date • $time" \
      -gravity south -fill white -font "$META_FONT" -pointsize 28 \
        -annotate +0+120 "$promoter" \
      -quality 88 "$hero"
  else
    # No fighter photos — typographic poster
    local vs_text=""
    if [ -n "$fighter1" ] && [ -n "$fighter2" ]; then
      vs_text="$fighter1  vs  $fighter2"
    fi

    convert "$bg" \
      -gravity center -fill "$accent" -stroke black -strokewidth 3 \
        -font "$HEAD_FONT" -pointsize 140 -annotate +0-400 "$title" \
      -gravity center -fill white -font "$META_FONT" -pointsize 60 \
        -annotate +0-100 "$vs_text" \
      -gravity center -fill white -font "$HEAD_FONT" -pointsize 120 \
        -annotate +0+100 "VS" \
      -gravity center -fill "rgba(255,255,255,0.7)" -font "$META_FONT" -pointsize 40 \
        -annotate +0+300 "${subtitle:-}" \
      -gravity south -fill white -font "$META_FONT" -pointsize 48 \
        -annotate +0+200 "PPV \$${price} • $date • $time" \
      -gravity south -fill "rgba(255,255,255,0.5)" -font "$META_FONT" -pointsize 28 \
        -annotate +0+140 "$promoter" \
      -quality 88 "$hero"
  fi

  # ── Add subtle vignette and film grain ──
  convert "$hero" \
    \( +clone -fill black -colorize 0 -vignette 0x20 \) \
    -compose multiply -composite "$hero"
  convert "$hero" -attenuate 0.15 +noise Gaussian -quality 88 "$hero"

  # ── Export derivative sizes ──
  convert "$hero" -resize 1200x1200^ -gravity center -extent 1200x1200 -quality 82 "$thumb"
  convert "$hero" -resize 1920x600^  -gravity center -extent 1920x600  -quality 82 "$banner"
  convert "$hero" -resize 1080x1920^ -gravity center -extent 1080x1920 -quality 88 "$portrait"
  convert "$hero" -resize 640x360^   -gravity center -extent 640x360   -quality 78 "$preview"

  echo "  ✓ hero:     $hero"
  echo "  ✓ thumb:    $thumb"
  echo "  ✓ banner:   $banner"
  echo "  ✓ portrait: $portrait"
  echo "  ✓ preview:  $preview"
  echo ""
}

# ── Entry point ──
if [ "${1:-}" = "--all" ]; then
  DIR="${2:?Provide events directory, e.g. data/events/}"
  count=0
  for f in "$DIR"/*.json; do
    [ -f "$f" ] || continue
    generate_poster "$f"
    count=$((count + 1))
  done
  echo "═══ Generated posters for $count events ═══"
else
  EVENT_JSON="${1:?Usage: $0 path/to/event.json  or  $0 --all data/events/}"
  generate_poster "$EVENT_JSON"
fi
