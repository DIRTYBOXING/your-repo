// tools/generate_cluster_icons.dart
//
// Generates precomputed cluster icon PNGs (cluster_1.png ... cluster_100.png).
// Uses the `image` package so it runs headless with plain `dart run`.
//
// Usage:  dart run tools/generate_cluster_icons.dart
//
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final outDir = Directory('assets/cluster_icons');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  const int maxCount = 100;
  const int size = 120;
  const int radius = size ~/ 2;

  // DFC neon cyan theme colours
  const bgR = 0, bgG = 229, bgB = 255; // #00E5FF — cyan ring
  const innerR = 10, innerG = 10, innerB = 18; // #0A0A12 — dark core

  for (int count = 1; count <= maxCount; count++) {
    final fileName = 'cluster_$count.png';
    final outPath = '${outDir.path}/$fileName';
    if (File(outPath).existsSync()) {
      print('Skip (exists) $outPath');
      continue;
    }

    final image = img.Image(width: size, height: size, numChannels: 4);

    // --- Draw filled circles ---
    _fillCircle(image, radius, radius, radius, bgR, bgG, bgB);
    _fillCircle(image, radius, radius, radius - 4, innerR, innerG, innerB);

    // --- Draw count text (bitmap digits) ---
    _drawCenteredCount(image, count, size, bgR, bgG, bgB);

    final pngBytes = img.encodePng(image);
    File(outPath).writeAsBytesSync(pngBytes);
    print('Wrote $outPath');
  }

  print('\nDone — $maxCount cluster icons in ${outDir.path}/');
}

/// Fill a circle with the given colour.
void _fillCircle(
  img.Image image,
  int cx,
  int cy,
  int r,
  int red,
  int green,
  int blue,
) {
  for (int y = cy - r; y <= cy + r; y++) {
    for (int x = cx - r; x <= cx + r; x++) {
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= r * r) {
        image.setPixelRgba(x, y, red, green, blue, 255);
      }
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tiny 5×7 bitmap font for digits 0-9  (each glyph is 5 wide × 7 tall)
// ──────────────────────────────────────────────────────────────────────────────
const _glyphW = 5;
const _glyphH = 7;

const _digits = <int, List<String>>{
  0: [' ### ', '#   #', '#   #', '#   #', '#   #', '#   #', ' ### '],
  1: ['  #  ', ' ##  ', '  #  ', '  #  ', '  #  ', '  #  ', ' ### '],
  2: [' ### ', '#   #', '    #', '  ## ', ' #   ', '#    ', '#####'],
  3: [' ### ', '#   #', '    #', '  ## ', '    #', '#   #', ' ### '],
  4: ['   # ', '  ## ', ' # # ', '#  # ', '#####', '   # ', '   # '],
  5: ['#####', '#    ', '#### ', '    #', '    #', '#   #', ' ### '],
  6: [' ### ', '#   #', '#    ', '#### ', '#   #', '#   #', ' ### '],
  7: ['#####', '    #', '   # ', '  #  ', '  #  ', '  #  ', '  #  '],
  8: [' ### ', '#   #', '#   #', ' ### ', '#   #', '#   #', ' ### '],
  9: [' ### ', '#   #', '#   #', ' ####', '    #', '#   #', ' ### '],
};

/// Draw a count number centred in the image using the bitmap font.
/// Scale factor chosen so the text fills roughly 60% of the icon width.
void _drawCenteredCount(
  img.Image image,
  int count,
  int size,
  int r,
  int g,
  int b,
) {
  final digits = count.toString().split('').map(int.parse).toList();
  final numDigits = digits.length;

  // Pick scale: 1-digit → 6x, 2-digit → 4x, 3-digit → 3x
  final int scale;
  if (numDigits == 1) {
    scale = 6;
  } else if (numDigits == 2) {
    scale = 4;
  } else {
    scale = 3;
  }

  final spacing = max(1, scale ~/ 2); // inter-digit gap in pixels
  final totalW = numDigits * _glyphW * scale + (numDigits - 1) * spacing;
  final totalH = _glyphH * scale;
  final startX = (size - totalW) ~/ 2;
  final startY = (size - totalH) ~/ 2;

  var dx = startX;
  for (final digit in digits) {
    final glyph = _digits[digit]!;
    for (int gy = 0; gy < _glyphH; gy++) {
      final row = glyph[gy];
      for (int gx = 0; gx < _glyphW; gx++) {
        if (gx < row.length && row[gx] == '#') {
          // Fill a scale×scale block
          for (int sy = 0; sy < scale; sy++) {
            for (int sx = 0; sx < scale; sx++) {
              final px = dx + gx * scale + sx;
              final py = startY + gy * scale + sy;
              if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
                image.setPixelRgba(px, py, r, g, b, 255);
              }
            }
          }
        }
      }
    }
    dx += _glyphW * scale + spacing;
  }
}
