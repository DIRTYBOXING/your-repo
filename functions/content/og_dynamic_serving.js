// ═══════════════════════════════════════════════════════════════════════════
// DYNAMIC OG SERVING — Intercept social bots, serve per-item OG tags
// ═══════════════════════════════════════════════════════════════════════════
//
// Problem: Flutter SPA serves the same static OG tags for every URL.
//          Social crawlers (Facebook, Twitter, Discord, LinkedIn, Slack)
//          never see per-post or per-event metadata.
//
// Solution: Firebase Hosting rewrite sends bot requests to this Cloud Function.
//           It reads the Firestore doc and returns HTML with correct OG tags.
//           Normal users get redirected to the SPA as before.
//
// Wiring (add to firebase.json hosting[].rewrites BEFORE the catch-all):
//   { "source": "/posts/**", "function": "ogDynamicServe" }
//   { "source": "/events/**", "function": "ogDynamicServe" }
//   { "source": "/fighters/**", "function": "ogDynamicServe" }
//
// ═══════════════════════════════════════════════════════════════════════════

const { onRequest } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

// ─── Bot detection ───────────────────────────────────────────────────────
const BOT_UA_PATTERNS = [
  "facebookexternalhit",
  "Facebot",
  "Twitterbot",
  "LinkedInBot",
  "Slackbot",
  "Discordbot",
  "WhatsApp",
  "TelegramBot",
  "Googlebot",
  "bingbot",
  "Applebot",
  "pinterest",
  "redditbot",
  "Embedly",
  "Quora Link Preview",
  "Showyoubot",
  "outbrain",
  "vkShare",
  "W3C_Validator",
];

function isBot(ua) {
  if (!ua) return false;
  const lower = ua.toLowerCase();
  return BOT_UA_PATTERNS.some((p) => lower.includes(p.toLowerCase()));
}

// ─── Defaults ────────────────────────────────────────────────────────────
const SITE_URL = "https://www.datafightcentral.com";
const DEFAULT_IMAGE = `${SITE_URL}/icons/Icon-512.png`;
const SITE_NAME = "Data Fight Central";
const DEFAULT_DESC =
  "The world's #1 AI-powered combat sports platform. UFC, MMA, Boxing, Muay Thai, BJJ & more.";

// ─── Sanitize text for meta tag values ───────────────────────────────────
function esc(str) {
  if (!str) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function truncate(str, max = 200) {
  if (!str) return "";
  const s = String(str);
  return s.length > max ? s.slice(0, max - 1) + "…" : s;
}

// ─── Build HTML shell with OG tags ───────────────────────────────────────
function buildOgHtml({ title, description, image, url, type, imageAlt }) {
  const safeTitle = esc(title || SITE_NAME);
  const safeDesc = esc(truncate(description || DEFAULT_DESC, 300));
  const safeImage = esc(image || DEFAULT_IMAGE);
  const safeUrl = esc(url || SITE_URL);
  const safeType = esc(type || "article");
  const safeAlt = esc(imageAlt || safeTitle);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${safeTitle}</title>

  <!-- Open Graph -->
  <meta property="og:title" content="${safeTitle}" />
  <meta property="og:description" content="${safeDesc}" />
  <meta property="og:image" content="${safeImage}" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta property="og:image:alt" content="${safeAlt}" />
  <meta property="og:url" content="${safeUrl}" />
  <meta property="og:type" content="${safeType}" />
  <meta property="og:site_name" content="${esc(SITE_NAME)}" />

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:site" content="@DataFightCentral" />
  <meta name="twitter:title" content="${safeTitle}" />
  <meta name="twitter:description" content="${safeDesc}" />
  <meta name="twitter:image" content="${safeImage}" />
  <meta name="twitter:image:alt" content="${safeAlt}" />

  <link rel="canonical" href="${safeUrl}" />

  <!-- Redirect non-bots (safety net) -->
  <meta http-equiv="refresh" content="0;url=${safeUrl}" />
</head>
<body>
  <p>Redirecting to <a href="${safeUrl}">${safeTitle}</a>…</p>
</body>
</html>`;
}

// ─── Fetch post data from Firestore ──────────────────────────────────────
async function getPostMeta(postId) {
  const doc = await db.collection("posts").doc(postId).get();
  if (!doc.exists) return null;
  const d = doc.data();

  // Determine best image: og_image > poster > first media URL > default
  let image = d.og_image || d.posterUrl || d.imageUrl || null;
  if (!image && d.media && Array.isArray(d.media)) {
    const m = d.media.find((x) => x.variants && x.variants.og);
    if (m) image = m.variants.og;
  }
  if (!image && d.mediaUrl) image = d.mediaUrl;

  // Build title
  const authorName = d.authorName || d.userName || "";
  const title =
    d.title || (authorName ? `${authorName} on DFC` : "Post on DFC");

  return {
    title,
    description: d.content || d.text || d.excerpt || DEFAULT_DESC,
    image,
    url: `${SITE_URL}/posts/${postId}`,
    type: "article",
  };
}

// ─── Fetch event data from Firestore ─────────────────────────────────────
async function getEventMeta(eventId) {
  const doc = await db.collection("events").doc(eventId).get();
  if (!doc.exists) {
    // Try ppv_events collection
    const ppvDoc = await db.collection("ppv_events").doc(eventId).get();
    if (!ppvDoc.exists) return null;
    const d = ppvDoc.data();
    return {
      title: d.title || d.eventName || "PPV Event on DFC",
      description: d.description || d.tagline || DEFAULT_DESC,
      image: d.posterUrl || d.imageUrl || d.og_image || null,
      url: `${SITE_URL}/events/${eventId}`,
      type: "event",
    };
  }
  const d = doc.data();
  return {
    title: d.title || d.eventName || "Event on DFC",
    description: d.description || d.venue || DEFAULT_DESC,
    image: d.posterUrl || d.imageUrl || d.og_image || null,
    url: `${SITE_URL}/events/${eventId}`,
    type: "event",
  };
}

// ─── Fetch fighter data from Firestore ───────────────────────────────────
async function getFighterMeta(fighterId) {
  const doc = await db.collection("fighters").doc(fighterId).get();
  if (!doc.exists) return null;
  const d = doc.data();
  const name = d.name || d.displayName || "Fighter";
  const record = d.record || "";
  const desc = record
    ? `${name} — Record: ${record}`
    : `${name} on Data Fight Central`;
  return {
    title: `${name} — Data Fight Central`,
    description: d.bio || desc,
    image: d.avatarUrl || d.profileImageUrl || d.photoUrl || null,
    url: `${SITE_URL}/fighters/${fighterId}`,
    type: "profile",
  };
}

// ─── Main HTTP handler ───────────────────────────────────────────────────
exports.ogDynamicServe = onRequest(
  { region: REGION, cors: false },
  async (req, res) => {
    const ua = req.get("user-agent") || "";

    // Only serve OG HTML to bots — redirect humans to the SPA
    if (!isBot(ua)) {
      const fullUrl = `${SITE_URL}${req.originalUrl || req.url}`;
      res.redirect(302, fullUrl);
      return;
    }

    const path = req.path || "";
    let meta = null;

    try {
      // Route: /posts/:id
      const postMatch = path.match(/^\/posts\/([a-zA-Z0-9_-]+)/);
      if (postMatch) {
        meta = await getPostMeta(postMatch[1]);
      }

      // Route: /events/:id
      if (!meta) {
        const eventMatch = path.match(/^\/events\/([a-zA-Z0-9_-]+)/);
        if (eventMatch) {
          meta = await getEventMeta(eventMatch[1]);
        }
      }

      // Route: /fighters/:id
      if (!meta) {
        const fighterMatch = path.match(/^\/fighters\/([a-zA-Z0-9_-]+)/);
        if (fighterMatch) {
          meta = await getFighterMeta(fighterMatch[1]);
        }
      }
    } catch (err) {
      console.error("OG Dynamic Serve error:", err);
    }

    // Fallback to generic site card
    if (!meta) {
      meta = {
        title: "Data Fight Central — #1 AI Combat Sports Platform",
        description: DEFAULT_DESC,
        image: DEFAULT_IMAGE,
        url: `${SITE_URL}${path}`,
        type: "website",
      };
    }

    const html = buildOgHtml(meta);

    res.set("Cache-Control", "public, max-age=300, s-maxage=600");
    res.set("Content-Type", "text/html; charset=utf-8");
    res.status(200).send(html);
  },
);
