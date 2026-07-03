// ═══════════════════════════════════════════════════════════════════════════
// DFC IMAGEGEN SERVICE — Auto-Generated Social Cards & Hero Images
// Facebook link previews, Instagram story cards, TikTok covers — automated.
// 6 Master Templates · DFC Shield Branding · Auto CTA · 3 Output Sizes
// ═══════════════════════════════════════════════════════════════════════════

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const { createCanvas, loadImage, registerFont } = require("canvas");
const sharp = require("sharp");
const { Worker } = require("bullmq");
const IORedis = require("ioredis");
const { initializeApp, cert } = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");
const { getFirestore } = require("firebase-admin/firestore");
const { v4: uuidv4 } = require("uuid");
const path = require("path");

// ── Firebase Init ───────────────────────────────────────────────────────
initializeApp({
  credential: cert(process.env.GOOGLE_APPLICATION_CREDENTIALS),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
});
const bucket = getStorage().bucket();
const db = getFirestore();
const redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379");

// ═══════════════════════════════════════════════════════════════════════════
// BRAND CONSTANTS — DFC Visual Identity
// ═══════════════════════════════════════════════════════════════════════════
const BRAND = {
  cyan: "#00E5FF",
  orange: "#FF6D00",
  dark: "#0A0A0A",
  darkGradient: "#121212",
  white: "#FFFFFF",
  gold: "#FFD700",
  red: "#FF1744",
  fontBold: "bold",
  fontRegular: "normal",
};

// ═══════════════════════════════════════════════════════════════════════════
// 6 MASTER TEMPLATES
// ═══════════════════════════════════════════════════════════════════════════
const TEMPLATES = {
  // Template 1: Cinematic Full — dark overlay, big headline, DFC shield
  cinematic_full: {
    name: "Cinematic Full",
    use: "PPV events, major fight announcements, hero banners",
    overlay: "rgba(0,0,0,0.75)",
    accentColor: BRAND.orange,
    headlineSize: 72,
    showShield: true,
    showCTA: true,
  },
  // Template 2: Cinematic Light — subtle overlay, clean text
  cinematic_light: {
    name: "Cinematic Light",
    use: "Liveblogs, updates, news articles",
    overlay: "rgba(0,0,0,0.55)",
    accentColor: BRAND.cyan,
    headlineSize: 56,
    showShield: true,
    showCTA: false,
  },
  // Template 3: Dubai Gold — premium feel, gold accents
  dubai_gold: {
    name: "Dubai Gold",
    use: "Feature articles, exclusive interviews, premium content",
    overlay: "rgba(10,10,10,0.80)",
    accentColor: BRAND.gold,
    headlineSize: 64,
    showShield: true,
    showCTA: true,
  },
  // Template 4: Fight Card — versus layout, two fighters
  fight_card: {
    name: "Fight Card",
    use: "Matchup announcements, fight cards",
    overlay: "rgba(0,0,0,0.70)",
    accentColor: BRAND.red,
    headlineSize: 48,
    showShield: true,
    showCTA: true,
  },
  // Template 5: Social Share — optimized for feed sharing
  social_share: {
    name: "Social Share",
    use: "Auto-attached to articles, social posts",
    overlay: "rgba(0,0,0,0.60)",
    accentColor: BRAND.cyan,
    headlineSize: 48,
    showShield: true,
    showCTA: false,
  },
  // Template 6: Story Card — vertical 9:16 for Instagram/TikTok stories
  story_card: {
    name: "Story Card",
    use: "Instagram Stories, TikTok, vertical mobile",
    overlay: "rgba(0,0,0,0.65)",
    accentColor: BRAND.orange,
    headlineSize: 56,
    showShield: true,
    showCTA: true,
  },
};

// ═══════════════════════════════════════════════════════════════════════════
// OUTPUT SIZES
// ═══════════════════════════════════════════════════════════════════════════
const SIZES = {
  square: { width: 2048, height: 2048, label: "Instagram/Feed (1:1)" },
  landscape: { width: 1920, height: 1080, label: "YouTube/Facebook (16:9)" },
  story: { width: 1080, height: 1920, label: "Story/TikTok (9:16)" },
  og: { width: 1200, height: 630, label: "OpenGraph/Twitter Card" },
  linkedin: { width: 1200, height: 627, label: "LinkedIn Post" },
};

// ═══════════════════════════════════════════════════════════════════════════
// CANVAS RENDERER — Generates a single image
// ═══════════════════════════════════════════════════════════════════════════
async function renderCard({
  template,
  size,
  headline,
  subheadline,
  eventTag,
  ctaText,
  bgImageUrl,
}) {
  const tmpl = TEMPLATES[template] || TEMPLATES.cinematic_full;
  const dim = SIZES[size] || SIZES.square;

  const canvas = createCanvas(dim.width, dim.height);
  const ctx = canvas.getContext("2d");

  // ── Background ────────────────────────────────────────────────────
  if (bgImageUrl) {
    try {
      const img = await loadImage(bgImageUrl);
      // Cover-fit the image
      const scale = Math.max(dim.width / img.width, dim.height / img.height);
      const x = (dim.width - img.width * scale) / 2;
      const y = (dim.height - img.height * scale) / 2;
      ctx.drawImage(img, x, y, img.width * scale, img.height * scale);
    } catch {
      // Fallback gradient
      const grad = ctx.createLinearGradient(0, 0, dim.width, dim.height);
      grad.addColorStop(0, BRAND.dark);
      grad.addColorStop(1, BRAND.darkGradient);
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, dim.width, dim.height);
    }
  } else {
    const grad = ctx.createLinearGradient(0, 0, dim.width, dim.height);
    grad.addColorStop(0, BRAND.dark);
    grad.addColorStop(0.5, "#1a1a2e");
    grad.addColorStop(1, BRAND.darkGradient);
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, dim.width, dim.height);
  }

  // ── Dark overlay ──────────────────────────────────────────────────
  ctx.fillStyle = tmpl.overlay;
  ctx.fillRect(0, 0, dim.width, dim.height);

  // ── Accent line (top) ─────────────────────────────────────────────
  ctx.fillStyle = tmpl.accentColor;
  ctx.fillRect(0, 0, dim.width, 6);

  // ── Bottom gradient fade ──────────────────────────────────────────
  const bottomGrad = ctx.createLinearGradient(
    0,
    dim.height * 0.5,
    0,
    dim.height,
  );
  bottomGrad.addColorStop(0, "rgba(0,0,0,0)");
  bottomGrad.addColorStop(1, "rgba(0,0,0,0.85)");
  ctx.fillStyle = bottomGrad;
  ctx.fillRect(0, dim.height * 0.5, dim.width, dim.height * 0.5);

  // ── Event tag (top-right) ─────────────────────────────────────────
  if (eventTag) {
    const tagFontSize = Math.round(tmpl.headlineSize * 0.35);
    ctx.font = `${BRAND.fontBold} ${tagFontSize}px sans-serif`;
    const tagWidth = ctx.measureText(eventTag.toUpperCase()).width + 40;
    ctx.fillStyle = tmpl.accentColor;
    ctx.fillRect(dim.width - tagWidth - 40, 30, tagWidth, tagFontSize + 20);
    ctx.fillStyle = BRAND.dark;
    ctx.textAlign = "right";
    ctx.fillText(eventTag.toUpperCase(), dim.width - 60, 30 + tagFontSize + 2);
  }

  // ── Headline ──────────────────────────────────────────────────────
  const fontSize = Math.round(tmpl.headlineSize * (dim.width / 2048));
  ctx.font = `${BRAND.fontBold} ${fontSize}px sans-serif`;
  ctx.fillStyle = BRAND.white;
  ctx.textAlign = "left";
  const maxWidth = dim.width * 0.8;
  const lines = wrapText(ctx, headline || "DATA FIGHT CENTRAL", maxWidth);
  const lineHeight = fontSize * 1.2;
  const textY = dim.height * 0.55;
  lines.forEach((line, i) => {
    ctx.fillText(line, dim.width * 0.1, textY + i * lineHeight);
  });

  // ── Subheadline ───────────────────────────────────────────────────
  if (subheadline) {
    const subSize = Math.round(fontSize * 0.5);
    ctx.font = `${BRAND.fontRegular} ${subSize}px sans-serif`;
    ctx.fillStyle = tmpl.accentColor;
    ctx.fillText(
      subheadline,
      dim.width * 0.1,
      textY + lines.length * lineHeight + 20,
    );
  }

  // ── CTA Button ────────────────────────────────────────────────────
  if (tmpl.showCTA && ctaText) {
    const ctaFontSize = Math.round(fontSize * 0.4);
    ctx.font = `${BRAND.fontBold} ${ctaFontSize}px sans-serif`;
    const ctaWidth = ctx.measureText(ctaText.toUpperCase()).width + 60;
    const ctaX = dim.width * 0.1;
    const ctaY = dim.height * 0.85;
    // Button background
    ctx.fillStyle = tmpl.accentColor;
    roundRect(ctx, ctaX, ctaY, ctaWidth, ctaFontSize + 30, 8);
    ctx.fill();
    // Button text
    ctx.fillStyle = BRAND.dark;
    ctx.textAlign = "left";
    ctx.fillText(ctaText.toUpperCase(), ctaX + 30, ctaY + ctaFontSize + 8);
  }

  // ── DFC Watermark (bottom-right) ──────────────────────────────────
  const wmSize = Math.round(fontSize * 0.3);
  ctx.font = `${BRAND.fontBold} ${wmSize}px sans-serif`;
  ctx.fillStyle = "rgba(255,255,255,0.4)";
  ctx.textAlign = "right";
  ctx.fillText("DATAFIGHTCENTRAL.COM", dim.width * 0.95, dim.height * 0.95);

  return canvas.toBuffer("image/png");
}

// ── Helper: word wrap ───────────────────────────────────────────────────
function wrapText(ctx, text, maxWidth) {
  const words = text.split(" ");
  const lines = [];
  let line = "";
  for (const word of words) {
    const test = line ? `${line} ${word}` : word;
    if (ctx.measureText(test).width > maxWidth && line) {
      lines.push(line);
      line = word;
    } else {
      line = test;
    }
  }
  if (line) lines.push(line);
  return lines;
}

// ── Helper: rounded rect ────────────────────────────────────────────────
function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}

// ═══════════════════════════════════════════════════════════════════════════
// EXPRESS API
// ═══════════════════════════════════════════════════════════════════════════
const app = express();
app.use(helmet());
app.use(cors({ origin: true }));
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_, res) =>
  res.json({ status: "ok", service: "dfc-imagegen" }),
);

// ── List available templates ────────────────────────────────────────────
app.get("/api/imagegen/templates", (_, res) => {
  res.json({ templates: TEMPLATES, sizes: SIZES });
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/imagegen/generate — Generate social card(s)
// ═══════════════════════════════════════════════════════════════════════════
app.post("/api/imagegen/generate", async (req, res) => {
  try {
    const {
      headline,
      subheadline,
      eventTag,
      ctaText,
      template = "cinematic_full",
      sizes = ["square", "og"],
      bgImageUrl,
      articleId,
      userId,
    } = req.body;

    if (!headline)
      return res.status(400).json({ error: "headline is required" });

    const results = {};
    for (const size of sizes) {
      const buffer = await renderCard({
        template,
        size,
        headline,
        subheadline,
        eventTag,
        ctaText,
        bgImageUrl,
      });

      // Also generate webp thumbnail
      const webpBuffer = await sharp(buffer).webp({ quality: 85 }).toBuffer();

      // Upload to Firebase Storage
      const basePath = `imagegen/${userId || "system"}/${uuidv4()}`;
      const pngPath = `${basePath}/${size}.png`;
      const webpPath = `${basePath}/${size}.webp`;

      const pngFile = bucket.file(pngPath);
      await pngFile.save(buffer, { metadata: { contentType: "image/png" } });
      await pngFile.makePublic();

      const webpFile = bucket.file(webpPath);
      await webpFile.save(webpBuffer, {
        metadata: { contentType: "image/webp" },
      });
      await webpFile.makePublic();

      results[size] = {
        png: `https://storage.googleapis.com/${bucket.name}/${pngPath}`,
        webp: `https://storage.googleapis.com/${bucket.name}/${webpPath}`,
      };
    }

    // ── Attach to article if provided ───────────────────────────────
    if (articleId) {
      await db
        .collection("feed_content")
        .doc(articleId)
        .update({
          socialCards: results,
          heroImage: results.landscape?.png || results.square?.png || null,
          ogImage: results.og?.png || null,
          updatedAt: new Date(),
        });
    }

    return res.json({ status: "ok", images: results });
  } catch (err) {
    console.error("[imagegen] Error:", err);
    return res.status(500).json({ error: "Image generation failed" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/imagegen/auto — Auto-select template based on content type
// This is the Facebook/LinkedIn-killer: auto social card for every post
// ═══════════════════════════════════════════════════════════════════════════
app.post("/api/imagegen/auto", async (req, res) => {
  try {
    const { contentType, headline, subheadline, eventTag, articleId, userId } =
      req.body;
    if (!headline)
      return res.status(400).json({ error: "headline is required" });

    // Auto-select template based on content type
    const templateMap = {
      liveblog: "cinematic_light",
      recap: "cinematic_full",
      feature: "dubai_gold",
      fight_card: "fight_card",
      news: "social_share",
      story: "story_card",
      ppv: "cinematic_full",
      promo: "dubai_gold",
    };
    const template = templateMap[contentType] || "social_share";

    // Auto-select sizes based on content
    const sizeMap = {
      liveblog: ["og", "story"],
      recap: ["square", "og", "landscape"],
      feature: ["landscape", "og", "linkedin"],
      fight_card: ["square", "story", "og"],
      news: ["og", "square"],
      story: ["story"],
      ppv: ["square", "landscape", "og", "story"],
      promo: ["square", "landscape", "story", "og"],
    };
    const sizes = sizeMap[contentType] || ["og", "square"];

    const ctaMap = {
      ppv: "BUY PPV NOW",
      promo: "GET TICKETS",
      feature: "READ MORE",
      fight_card: "FULL CARD",
    };
    const ctaText = ctaMap[contentType] || null;

    // Forward to generate endpoint
    const results = {};
    for (const size of sizes) {
      const buffer = await renderCard({
        template,
        size,
        headline,
        subheadline,
        eventTag,
        ctaText,
      });
      const webpBuffer = await sharp(buffer).webp({ quality: 85 }).toBuffer();

      const basePath = `imagegen/${userId || "system"}/${uuidv4()}`;
      const pngPath = `${basePath}/${size}.png`;
      const webpPath = `${basePath}/${size}.webp`;

      const pngFile = bucket.file(pngPath);
      await pngFile.save(buffer, { metadata: { contentType: "image/png" } });
      await pngFile.makePublic();
      const webpFile = bucket.file(webpPath);
      await webpFile.save(webpBuffer, {
        metadata: { contentType: "image/webp" },
      });
      await webpFile.makePublic();

      results[size] = {
        png: `https://storage.googleapis.com/${bucket.name}/${pngPath}`,
        webp: `https://storage.googleapis.com/${bucket.name}/${webpPath}`,
      };
    }

    if (articleId) {
      await db
        .collection("feed_content")
        .doc(articleId)
        .update({
          socialCards: results,
          heroImage: results.landscape?.png || results.square?.png || null,
          ogImage: results.og?.png || null,
          updatedAt: new Date(),
        });
    }

    return res.json({ status: "ok", template, sizes, images: results });
  } catch (err) {
    console.error("[imagegen/auto] Error:", err);
    return res.status(500).json({ error: "Auto image generation failed" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// BACKGROUND WORKER — Process image jobs from upload-service
// ═══════════════════════════════════════════════════════════════════════════
const imageWorker = new Worker(
  "imagegen",
  async (job) => {
    const { uploadId, publicUrl, userId } = job.data;
    console.log(
      `[imagegen-worker] Processing thumbnails for upload ${uploadId}`,
    );

    try {
      // Generate optimized variants using sharp
      const response = await fetch(publicUrl);
      const buffer = Buffer.from(await response.arrayBuffer());

      const variants = {};
      const sizes = [
        { name: "thumb_sm", width: 150, height: 150 },
        { name: "thumb_md", width: 400, height: 400 },
        { name: "thumb_lg", width: 800, height: 800 },
        { name: "og", width: 1200, height: 630 },
      ];

      for (const s of sizes) {
        const resized = await sharp(buffer)
          .resize(s.width, s.height, { fit: "cover" })
          .webp({ quality: 85 })
          .toBuffer();

        const remotePath = `thumbnails/${userId}/${uploadId}/${s.name}.webp`;
        const file = bucket.file(remotePath);
        await file.save(resized, { metadata: { contentType: "image/webp" } });
        await file.makePublic();
        variants[s.name] =
          `https://storage.googleapis.com/${bucket.name}/${remotePath}`;
      }

      await db.collection("media_uploads").doc(uploadId).update({
        variants,
        updatedAt: new Date(),
      });

      console.log(
        `[imagegen-worker] ${Object.keys(variants).length} thumbnails generated for ${uploadId}`,
      );
    } catch (err) {
      console.error(`[imagegen-worker] Failed for ${uploadId}:`, err.message);
    }
  },
  { connection: redis, concurrency: 4 },
);

// ═══════════════════════════════════════════════════════════════════════════
// ARTICLE / STORY TEMPLATES — Structured content scaffolds
// Used by feed publisher + CMS to generate article HTML/markdown
// ═══════════════════════════════════════════════════════════════════════════
const STORY_TEMPLATES = {
  liveblog: {
    name: "Liveblog",
    description: "Real-time round-by-round coverage with timestamped updates",
    sections: [
      "hero_image",
      "intro",
      "rounds",
      "result",
      "post_fight_quotes",
      "stats_table",
    ],
    imageSlots: { hero: "landscape", social: "og", story: "story" },
    autoGenImages: ["social_share", "story_card"],
  },
  recap: {
    name: "Fight Recap",
    description: "Post-event narrative recap with analysis and highlights",
    sections: [
      "hero_image",
      "headline",
      "lede",
      "body",
      "key_moments",
      "scorecards",
      "whats_next",
    ],
    imageSlots: { hero: "landscape", card: "square", og: "og" },
    autoGenImages: ["cinematic_full", "social_share"],
  },
  feature: {
    name: "Feature Article",
    description: "Long-form fighter profile, gym spotlight, or investigation",
    sections: [
      "hero_image",
      "headline",
      "subheadline",
      "body_parts",
      "pull_quotes",
      "gallery",
      "cta",
    ],
    imageSlots: { hero: "landscape", portrait: "story", share: "og" },
    autoGenImages: ["dubai_gold", "social_share"],
  },
  interview: {
    name: "Q&A Interview",
    description: "Structured question-and-answer format with fighter/coach",
    sections: ["hero_image", "intro", "qa_pairs", "rapid_fire", "closing"],
    imageSlots: { hero: "landscape", headshot: "square", share: "og" },
    autoGenImages: ["cinematic_light", "social_share"],
  },
  ppv_promo: {
    name: "PPV Promotion",
    description: "Hype piece with fight card, pricing, and buy CTA",
    sections: [
      "hero_image",
      "event_title",
      "main_event",
      "undercard",
      "pricing",
      "buy_cta",
      "countdown",
    ],
    imageSlots: { hero: "landscape", card: "square", story: "story", og: "og" },
    autoGenImages: [
      "cinematic_full",
      "fight_card",
      "story_card",
      "social_share",
    ],
  },
  news_flash: {
    name: "Breaking News",
    description: "Short-form breaking update (injury, signing, controversy)",
    sections: ["headline", "alert_image", "body", "source_attribution"],
    imageSlots: { alert: "og", social: "square" },
    autoGenImages: ["cinematic_light", "social_share"],
  },
};

// GET /api/imagegen/story-templates — List available story/article templates
app.get("/api/imagegen/story-templates", (req, res) => {
  const list = Object.entries(STORY_TEMPLATES).map(([id, t]) => ({
    id,
    name: t.name,
    description: t.description,
    sections: t.sections,
    imageSlots: t.imageSlots,
    autoGenImages: t.autoGenImages,
  }));
  return res.json({ templates: list });
});

// POST /api/imagegen/story-scaffold — Generate a full article scaffold from template
app.post("/api/imagegen/story-scaffold", async (req, res) => {
  try {
    const { templateId, eventId, headline, subtitle, body, metadata } =
      req.body;
    const template = STORY_TEMPLATES[templateId];
    if (!template) {
      return res.status(400).json({
        error: `Unknown template: ${templateId}`,
        available: Object.keys(STORY_TEMPLATES),
      });
    }

    // Build scaffold
    const scaffold = {
      templateId,
      templateName: template.name,
      eventId: eventId || null,
      headline: headline || "",
      subtitle: subtitle || "",
      sections: {},
      imageJobs: [],
      metadata: metadata || {},
      createdAt: new Date(),
    };

    // Initialize empty sections
    for (const section of template.sections) {
      scaffold.sections[section] = section === "qa_pairs" ? [] : "";
    }

    // Fill provided body into appropriate section
    if (body) {
      if (scaffold.sections.body !== undefined) scaffold.sections.body = body;
      else if (scaffold.sections.lede !== undefined)
        scaffold.sections.lede = body;
      else if (scaffold.sections.intro !== undefined)
        scaffold.sections.intro = body;
    }

    // Queue image generation jobs for each auto-gen image template
    for (const imgTemplate of template.autoGenImages) {
      const sizesForTemplate = Object.values(template.imageSlots);
      for (const size of [...new Set(sizesForTemplate)]) {
        scaffold.imageJobs.push({
          template: imgTemplate,
          size,
          headline: headline || "DFC",
          eventTag: metadata?.eventTag || "",
          status: "queued",
        });
      }
    }

    // Store scaffold in Firestore
    const docRef = await db.collection("article_scaffolds").add(scaffold);

    // Queue image generation
    for (const job of scaffold.imageJobs) {
      await imagegenQueue.add("story-image", {
        scaffoldId: docRef.id,
        ...job,
      });
    }

    return res.json({
      scaffoldId: docRef.id,
      templateName: template.name,
      sections: template.sections,
      imageJobsQueued: scaffold.imageJobs.length,
    });
  } catch (err) {
    console.error("[story-scaffold] Error:", err);
    return res.status(500).json({ error: "Scaffold generation failed" });
  }
});

// ── Start Server ────────────────────────────────────────────────────────
const PORT = process.env.PORT || 4002;
app.listen(PORT, () => {
  console.log(`🎨 DFC Imagegen Service running on port ${PORT}`);
  console.log(`   Templates: ${Object.keys(TEMPLATES).join(", ")}`);
  console.log(`   Sizes: ${Object.keys(SIZES).join(", ")}`);
  console.log(`   Story Templates: ${Object.keys(STORY_TEMPLATES).join(", ")}`);
});
