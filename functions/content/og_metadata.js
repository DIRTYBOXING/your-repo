// ═══════════════════════════════════════════════════════════════════════════
// OG METADATA ENRICHMENT — Server-side Open Graph fetching on post creation
// ═══════════════════════════════════════════════════════════════════════════

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { admin, db, REGION } = require("../config");
const axios = require("axios");

// ─── URL extraction regex ────────────────────────────────────────────────
const URL_REGEX = /https?:\/\/[^\s<>"')\]]+/g;

// ─── Allowed domains (block internal / untrusted hits) ───────────────────
const BLOCKED_DOMAINS = [
  "localhost",
  "127.0.0.1",
  "0.0.0.0",
  "10.",
  "192.168.",
  "172.",
];

function isBlockedUrl(url) {
  try {
    const hostname = new URL(url).hostname;
    return BLOCKED_DOMAINS.some(
      (d) => hostname.startsWith(d) || hostname === d,
    );
  } catch {
    return true;
  }
}

function extractFirstUrl(text) {
  if (!text || typeof text !== "string") return null;
  const matches = text.match(URL_REGEX);
  if (!matches) return null;
  for (const url of matches) {
    if (!isBlockedUrl(url)) return url;
  }
  return null;
}

// ─── OG Tag extraction via regex (avoids jsdom dependency) ───────────────
function extractOgTags(html) {
  const og = {};
  // Match <meta property="og:..." content="...">
  const metaRegex =
    /<meta\s+[^>]*property\s*=\s*["']og:([^"']+)["'][^>]*content\s*=\s*["']([^"']*)["'][^>]*\/?>/gi;
  let match;
  while ((match = metaRegex.exec(html)) !== null) {
    og[`og:${match[1]}`] = decodeHtmlEntities(match[2]);
  }

  // Also try reversed attribute order: content before property
  const metaRegexAlt =
    /<meta\s+[^>]*content\s*=\s*["']([^"']*)["'][^>]*property\s*=\s*["']og:([^"']+)["'][^>]*\/?>/gi;
  while ((match = metaRegexAlt.exec(html)) !== null) {
    const key = `og:${match[2]}`;
    if (!og[key]) og[key] = decodeHtmlEntities(match[1]);
  }

  // Fallback: <title> tag if no og:title
  if (!og["og:title"]) {
    const titleMatch = html.match(/<title[^>]*>([^<]+)<\/title>/i);
    if (titleMatch) og["og:title"] = decodeHtmlEntities(titleMatch[1].trim());
  }

  // Fallback: meta description if no og:description
  if (!og["og:description"]) {
    const descMatch = html.match(
      /<meta\s+[^>]*name\s*=\s*["']description["'][^>]*content\s*=\s*["']([^"']*)["'][^>]*\/?>/i,
    );
    if (descMatch) og["og:description"] = decodeHtmlEntities(descMatch[1]);
  }

  return og;
}

function decodeHtmlEntities(text) {
  return text
    .replaceAll("&amp;", "&")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">")
    .replaceAll("&quot;", '"')
    .replaceAll("&#39;", "'")
    .replaceAll("&#x27;", "'")
    .replaceAll("&#x2F;", "/");
}

// ═══════════════════════════════════════════════════════════════════════════
// FIRESTORE TRIGGER — Enrich new posts with OG metadata
// ═══════════════════════════════════════════════════════════════════════════

exports.fetchOgMetadata = onDocumentCreated(
  { document: "posts/{postId}", region: REGION },
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const postData = snap.data();
    const content = postData.content || "";

    // Skip if client already provided link preview data
    if (postData.linkPreviewUrl) return null;

    const url = extractFirstUrl(content);
    if (!url) return null;

    try {
      const response = await axios.get(url, {
        timeout: 6000,
        maxRedirects: 3,
        headers: {
          "User-Agent": "DataFightCentral/1.0 (OG Fetcher)",
          Accept: "text/html",
        },
        // Only read first 100KB to avoid large payloads
        maxContentLength: 100 * 1024,
        responseType: "text",
      });

      const html = typeof response.data === "string" ? response.data : "";
      if (!html) return null;

      const ogData = extractOgTags(html);
      if (Object.keys(ogData).length === 0) return null;

      // Add the source URL
      ogData["og:url"] = ogData["og:url"] || url;

      return snap.ref.update({ ogPreview: ogData });
    } catch (error) {
      console.error(
        `OG fetch error for post ${event.params.postId}:`,
        error.message,
      );
      return null;
    }
  },
);
