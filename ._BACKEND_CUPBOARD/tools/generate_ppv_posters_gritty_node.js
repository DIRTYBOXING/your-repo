// ═══════════════════════════════════════════════════════════════════════════
// DFC Gritty Urban PPV Poster Generator — Node.js / Sharp
// ═══════════════════════════════════════════════════════════════════════════
// Usage:
//   node tools/generate_ppv_posters_gritty_node.js data/events/ppv-ufc-327.json
//   node tools/generate_ppv_posters_gritty_node.js --all data/events/
//
// Requires: npm install sharp
// Outputs WebP (smaller, faster) with JPG fallback for hero.
// ═══════════════════════════════════════════════════════════════════════════

import sharp from "sharp";
import fs from "fs/promises";
import path from "path";

const OUT_DIR = "assets/ppv";

// Sport-specific accent colors
const ACCENT_MAP = {
  UFC: "#ff4444",
  MMA: "#ff4444",
  Boxing: "#ffd700",
  BKFC: "#ff7a18",
  Brawling: "#ff7a18",
  "Muay Thai": "#e91e63",
  Kickboxing: "#9c27b0",
};

function escapeXml(unsafe) {
  if (!unsafe) return "";
  return unsafe.replace(
    /[<>&'"]/g,
    (c) =>
      ({
        "<": "&lt;",
        ">": "&gt;",
        "&": "&amp;",
        "'": "&apos;",
        '"': "&quot;",
      })[c],
  );
}

async function generatePoster(eventJsonPath) {
  const raw = await fs.readFile(eventJsonPath, "utf8");
  const data = JSON.parse(raw);
  await fs.mkdir(OUT_DIR, { recursive: true });

  const {
    eventId,
    title,
    date,
    time = "TBA",
    price,
    promoter = "DFC",
    sport = "MMA",
    subtitle = "",
  } = data;

  const fighter1 = data.fighters?.[0]?.name || "";
  const fighter2 = data.fighters?.[1]?.name || "";
  const accent = ACCENT_MAP[sport] || "#ff7a18";

  const heroW = 1600;
  const heroH = 2400;

  // ── Background gradient SVG ──
  const bgSvg = `<svg width="${heroW}" height="${heroH}">
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="0.3" y2="1">
        <stop offset="0" stop-color="#0b0b0b"/>
        <stop offset="0.5" stop-color="#1a1a1a"/>
        <stop offset="1" stop-color="#1f1f1f"/>
      </linearGradient>
      <radialGradient id="vig" cx="50%" cy="50%" r="70%">
        <stop offset="0" stop-color="transparent"/>
        <stop offset="1" stop-color="rgba(0,0,0,0.6)"/>
      </radialGradient>
    </defs>
    <rect width="100%" height="100%" fill="url(#bg)"/>
    <rect width="100%" height="100%" fill="url(#vig)"/>
  </svg>`;

  // ── Text overlay SVG ──
  const vsLine =
    fighter1 && fighter2
      ? `<text x="50%" y="48%" text-anchor="middle" class="fighter">${escapeXml(fighter1)}</text>
         <text x="50%" y="52%" text-anchor="middle" class="vs">VS</text>
         <text x="50%" y="56%" text-anchor="middle" class="fighter">${escapeXml(fighter2)}</text>`
      : "";

  const textSvg = `<svg width="${heroW}" height="${heroH}">
    <style>
      .title {
        fill: ${accent};
        font-size: 110px;
        font-weight: 900;
        font-family: Impact, 'Arial Black', sans-serif;
        text-transform: uppercase;
        letter-spacing: 4px;
      }
      .subtitle {
        fill: rgba(255,255,255,0.7);
        font-size: 40px;
        font-family: Arial, sans-serif;
        font-weight: 600;
      }
      .fighter {
        fill: #ffffff;
        font-size: 52px;
        font-weight: 700;
        font-family: Arial, sans-serif;
        text-transform: uppercase;
      }
      .vs {
        fill: ${accent};
        font-size: 120px;
        font-weight: 900;
        font-family: Impact, 'Arial Black', sans-serif;
      }
      .meta {
        fill: #ffffff;
        font-size: 36px;
        font-family: Arial, sans-serif;
      }
      .promoter {
        fill: rgba(255,255,255,0.5);
        font-size: 28px;
        font-family: Arial, sans-serif;
      }
    </style>
    <text x="50%" y="22%" text-anchor="middle" class="title">${escapeXml(title)}</text>
    <text x="50%" y="28%" text-anchor="middle" class="subtitle">${escapeXml(subtitle)}</text>
    ${vsLine}
    <text x="50%" y="85%" text-anchor="middle" class="meta">PPV $${escapeXml(String(price))} · ${escapeXml(date)} · ${escapeXml(time)}</text>
    <text x="50%" y="90%" text-anchor="middle" class="promoter">${escapeXml(promoter)}</text>
  </svg>`;

  // ── Compose hero poster ──
  const heroPath = path.join(OUT_DIR, `${eventId}_hero.webp`);
  const heroJpgPath = path.join(OUT_DIR, `${eventId}_hero.jpg`);

  const bgBuffer = Buffer.from(bgSvg);
  const textBuffer = Buffer.from(textSvg);

  // Check for fighter photos
  const photoLeft = path.join(OUT_DIR, `${eventId}_photo_left.jpg`);
  const photoRight = path.join(OUT_DIR, `${eventId}_photo_right.jpg`);
  const hasPhotos =
    (await fs
      .access(photoLeft)
      .then(() => true)
      .catch(() => false)) &&
    (await fs
      .access(photoRight)
      .then(() => true)
      .catch(() => false));

  const composites = [];

  if (hasPhotos) {
    const leftBuf = await sharp(photoLeft)
      .resize(800, heroH, { fit: "cover", position: "west" })
      .modulate({ brightness: 0.8, saturation: 0.8 })
      .toBuffer();
    const rightBuf = await sharp(photoRight)
      .resize(800, heroH, { fit: "cover", position: "east" })
      .modulate({ brightness: 0.8, saturation: 0.8 })
      .toBuffer();
    composites.push(
      { input: leftBuf, left: 0, top: 0 },
      { input: rightBuf, left: 800, top: 0 },
    );
  }

  composites.push({ input: textBuffer, left: 0, top: 0 });

  // Generate hero WebP
  await sharp(bgBuffer)
    .composite(composites)
    .webp({ quality: 85 })
    .toFile(heroPath);

  // Generate hero JPG fallback
  await sharp(bgBuffer)
    .composite(composites)
    .jpeg({ quality: 88 })
    .toFile(heroJpgPath);

  // ── Derivative sizes ──
  const sizes = [
    { name: "thumb", w: 1200, h: 1200, quality: 82 },
    { name: "banner", w: 1920, h: 600, quality: 82 },
    { name: "portrait", w: 1080, h: 1920, quality: 88 },
    { name: "preview", w: 640, h: 360, quality: 78 },
  ];

  for (const { name, w, h, quality } of sizes) {
    const outWebp = path.join(OUT_DIR, `${eventId}_${name}.webp`);
    const outJpg = path.join(OUT_DIR, `${eventId}_${name}.jpg`);
    await sharp(heroJpgPath)
      .resize(w, h, { fit: "cover", position: "centre" })
      .webp({ quality })
      .toFile(outWebp);
    await sharp(heroJpgPath)
      .resize(w, h, { fit: "cover", position: "centre" })
      .jpeg({ quality })
      .toFile(outJpg);
  }

  console.log(
    `✓ ${eventId}: hero, thumb, banner, portrait, preview (WebP + JPG)`,
  );
}

// ── Entry point ──
async function main() {
  const args = process.argv.slice(2);

  if (args[0] === "--all") {
    const dir = args[1];
    if (!dir) {
      console.error(
        "Usage: node generate_ppv_posters_gritty_node.js --all data/events/",
      );
      process.exit(1);
    }
    const files = (await fs.readdir(dir)).filter((f) => f.endsWith(".json"));
    console.log(`Generating posters for ${files.length} events...`);
    for (const f of files) {
      await generatePoster(path.join(dir, f));
    }
    console.log(`═══ Done: ${files.length} events ═══`);
  } else if (args[0]) {
    await generatePoster(args[0]);
  } else {
    console.error(
      "Usage: node generate_ppv_posters_gritty_node.js <event.json | --all dir/>",
    );
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
