/**
 * SSR Open-Graph Clip Page Generator
 * ------------------------------------
 * Serves pre-rendered HTML with OG meta tags so that social crawlers
 * (Facebook, Twitter, iMessage, Discord, Slack) render a rich preview
 * when a DFC clip link is shared.
 *
 * Route:  GET /clip/:clipId
 *
 * Falls back to a generic DFC preview if the clip is not found.
 */
"use strict";

const express = require("express");
const admin = require("firebase-admin");

const app = express();
const PORT = process.env.OG_PORT || 4020;

// Lazy Firebase init (reuse existing app if available)
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

const DFC_ORIGIN = process.env.DFC_ORIGIN || "https://datafightcentral.com";
const CDN_BASE = process.env.CDN_BASE || "https://cdn.datafightcentral.com";
const FB_APP_ID = process.env.FB_APP_ID || "";
const TWITTER_SITE = process.env.TWITTER_SITE || "@DataFightHQ";

function escapeHtml(str) {
  if (!str) return "";
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#x27;");
}

function renderClipPage(clip) {
  const title = escapeHtml(clip.title || "DFC Fight Clip");
  const description = escapeHtml(
    clip.description || "Watch this fight clip on Data Fight Central",
  );
  const thumbnail = escapeHtml(
    clip.thumbnailUrl || `${CDN_BASE}/og/default-clip.jpg`,
  );
  const videoUrl = escapeHtml(clip.videoUrl || "");
  const canonicalUrl = escapeHtml(`${DFC_ORIGIN}/clip/${clip.id}`);
  const duration = clip.durationSec ? Math.round(clip.durationSec) : 30;
  const width = clip.width || 1280;
  const height = clip.height || 720;

  return `<!DOCTYPE html>
<html lang="en" prefix="og: https://ogp.me/ns# video: https://ogp.me/ns/video#">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${title} | Data Fight Central</title>

  <!-- Open Graph -->
  <meta property="og:type"        content="video.other">
  <meta property="og:title"       content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:url"         content="${canonicalUrl}">
  <meta property="og:site_name"   content="Data Fight Central">
  <meta property="og:image"       content="${thumbnail}">
  <meta property="og:image:width" content="${width}">
  <meta property="og:image:height" content="${height}">
  ${
    videoUrl
      ? `<meta property="og:video"         content="${videoUrl}">
  <meta property="og:video:type"   content="video/mp4">
  <meta property="og:video:width"  content="${width}">
  <meta property="og:video:height" content="${height}">
  <meta property="og:video:duration" content="${duration}">`
      : ""
  }
  ${FB_APP_ID ? `<meta property="fb:app_id" content="${FB_APP_ID}">` : ""}

  <!-- Twitter Card -->
  <meta name="twitter:card"        content="player">
  <meta name="twitter:site"        content="${TWITTER_SITE}">
  <meta name="twitter:title"       content="${title}">
  <meta name="twitter:description" content="${description}">
  <meta name="twitter:image"       content="${thumbnail}">
  ${
    videoUrl
      ? `<meta name="twitter:player"       content="${canonicalUrl}">
  <meta name="twitter:player:width"  content="${width}">
  <meta name="twitter:player:height" content="${height}">`
      : ""
  }

  <!-- JSON-LD -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "VideoObject",
    "name": "${title}",
    "description": "${description}",
    "thumbnailUrl": "${thumbnail}",
    ${videoUrl ? `"contentUrl": "${videoUrl}",` : ""}
    "uploadDate": "${clip.createdAt || new Date().toISOString()}",
    "duration": "PT${duration}S",
    "publisher": {
      "@type": "Organization",
      "name": "Data Fight Central",
      "url": "${DFC_ORIGIN}"
    }
  }
  </script>

  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    body{background:#0a0a0f;color:#e0e0e0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh}
    .hero{max-width:800px;text-align:center;padding:2rem}
    .hero img{width:100%;border-radius:12px;box-shadow:0 0 40px rgba(0,200,255,.15)}
    .hero h1{margin:1.2rem 0 .5rem;font-size:1.6rem;background:linear-gradient(135deg,#00c8ff,#7b2dff);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    .hero p{color:#aaa;font-size:1rem;line-height:1.5}
    .cta{display:inline-block;margin-top:1.5rem;padding:.8rem 2rem;border-radius:8px;background:linear-gradient(135deg,#00c8ff,#7b2dff);color:#fff;text-decoration:none;font-weight:600;font-size:1rem;transition:opacity .2s}
    .cta:hover{opacity:.85}
  </style>
</head>
<body>
  <div class="hero">
    <img src="${thumbnail}" alt="${title}">
    <h1>${title}</h1>
    <p>${description}</p>
    <a class="cta" href="${canonicalUrl}">Watch on DFC</a>
  </div>
  <script>
    // Redirect real users (not bots) to the SPA
    if (!/bot|crawl|spider|facebook|twitter|linkedin|slack|discord|whatsapp|telegram/i.test(navigator.userAgent)) {
      window.location.replace('${canonicalUrl}');
    }
  </script>
</body>
</html>`;
}

function renderFallback() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Data Fight Central</title>
  <meta property="og:title"       content="Data Fight Central">
  <meta property="og:description" content="The combat sports operating system — live events, clips, stats, and community.">
  <meta property="og:image"       content="${CDN_BASE}/og/dfc-default.jpg">
  <meta property="og:url"         content="${DFC_ORIGIN}">
  <meta name="twitter:card"       content="summary_large_image">
</head>
<body style="background:#0a0a0f;color:#fff;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh">
  <h1 style="font-size:2rem">Data Fight Central</h1>
  <script>window.location.replace('${DFC_ORIGIN}');</script>
</body>
</html>`;
}

// Health check
app.get("/health", (_req, res) =>
  res.json({ status: "ok", service: "og-clip-ssr" }),
);

// Clip OG page
app.get("/clip/:clipId", async (req, res) => {
  try {
    const { clipId } = req.params;
    if (!clipId || clipId.length > 128) {
      return res.status(400).send(renderFallback());
    }

    const doc = await db.collection("clips").doc(clipId).get();
    if (!doc.exists) {
      return res.status(404).send(renderFallback());
    }

    const clip = { id: doc.id, ...doc.data() };
    res.set("Cache-Control", "public, max-age=300, s-maxage=600");
    return res.status(200).send(renderClipPage(clip));
  } catch (err) {
    console.error("[og-clip-ssr] Error:", err.message);
    return res.status(500).send(renderFallback());
  }
});

// Catch-all → fallback
app.get("/{*path}", (_req, res) => res.send(renderFallback()));

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`[og-clip-ssr] Listening on http://localhost:${PORT}`);
  });
}

module.exports = { app, renderClipPage, renderFallback };
