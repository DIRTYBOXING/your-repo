// ═══════════════════════════════════════════════════════════════════════════
// DFC AUTO-FEED SCHEDULER — Server-Side Feed Aggregation & Ranking
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
//   Move the auto-feed orchestrator from client-side (Dart) to server-side
//   so that the unified feed is always fresh, even when no user has the app open.
//
// FLOW (runs every 15 minutes):
//   1. Read trusted RSS sources from Firestore `feed_sources` collection
//   2. Fetch + normalize items from each source
//   3. Apply trust scoring + safety classification
//   4. Rank by strategic score (trust × weight + opportunity)
//   5. Write top N items to `auto_feed_cache` (pre-computed for app reads)
//   6. Prune stale items older than 48 hours
//
// CLIENT IMPACT:
//   AutoFeedOrchestratorService can now read `auto_feed_cache` as the
//   primary source and only fall back to live fetching on manual refresh.
//
// ═══════════════════════════════════════════════════════════════════════════

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION, Parser } = require("../config");

const FEED_CACHE_COLLECTION = "auto_feed_cache";
const FEED_SOURCES_COLLECTION = "feed_sources";
const MAX_CACHE_ITEMS = 200;
const STALE_HOURS = 48;

// ─── Source type enum (mirrors Dart FeedSourceType) ──────────────────────
const SOURCE_TYPES = {
  rss: "news",
  youtube: "video",
  partner: "partner",
  studio: "studio",
  social: "social",
};

// ─── Trust classification thresholds ─────────────────────────────────────
const TRUST_PROFILES = {
  verified_partner: { minScore: 0.9, weight: 1.5 },
  trusted_media: { minScore: 0.7, weight: 1.2 },
  community: { minScore: 0.4, weight: 0.8 },
  unclassified: { minScore: 0.0, weight: 0.5 },
};

// ─── Default RSS sources (used when feed_sources collection is empty) ────
const DEFAULT_SOURCES = [
  {
    id: "mma_fighting",
    name: "MMA Fighting",
    url: "https://www.mmafighting.com/rss/current",
    type: "rss",
    trustProfile: "trusted_media",
    enabled: true,
  },
  {
    id: "sherdog",
    name: "Sherdog",
    url: "https://www.sherdog.com/rss/news.xml",
    type: "rss",
    trustProfile: "trusted_media",
    enabled: true,
  },
  {
    id: "boxing_scene",
    name: "Boxing Scene",
    url: "https://www.boxingscene.com/rss.php",
    type: "rss",
    trustProfile: "trusted_media",
    enabled: true,
  },
];

// ─── Keyword-based ranking lifts ─────────────────────────────────────────
const RANKING_KEYWORDS = {
  main_event: {
    keywords: ["main event", "headliner", "title fight", "championship"],
    lift: 0.25,
  },
  ticket_revenue: {
    keywords: ["tickets", "ppv", "sold out", "buy now", "on sale"],
    lift: 0.2,
  },
  viral: {
    keywords: ["viral", "knockout", "ko", "finish", "highlight"],
    lift: 0.15,
  },
  legend: {
    keywords: ["legend", "ultimate legends", "hall of fame"],
    lift: 0.3,
  },
  australian: {
    keywords: ["australia", "aussie", "melbourne", "sydney", "brisbane"],
    lift: 0.2,
  },
};

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: Fetch and parse RSS feed
// ═══════════════════════════════════════════════════════════════════════════
async function fetchRssFeed(source) {
  if (!Parser) {
    console.warn("rss-parser not installed — skipping RSS fetch");
    return [];
  }

  try {
    const parser = new Parser({
      timeout: 10000,
      headers: { "User-Agent": "DataFightCentral/1.0 (Feed Aggregator)" },
    });
    const feed = await parser.parseURL(source.url);

    return (feed.items || []).slice(0, 20).map((item) => ({
      id: `${source.id}_${hashString(item.link || item.guid || item.title)}`,
      title: (item.title || "").substring(0, 200),
      body: stripHtml(
        item.contentSnippet || item.content || item.summary || "",
      ).substring(0, 500),
      source: source.name,
      sourceType: SOURCE_TYPES[source.type] || "news",
      publishedAt: item.pubDate ? new Date(item.pubDate) : new Date(),
      linkUrl: item.link || null,
      imageUrl: extractImageUrl(item) || null,
      videoUrl: null,
      tags: extractTags(item),
    }));
  } catch (err) {
    console.error(`Failed to fetch RSS from ${source.name}:`, err.message);
    return [];
  }
}

// ─── String helpers ──────────────────────────────────────────────────────
function hashString(str) {
  let hash = 0;
  for (let i = 0; i < (str || "").length; i++) {
    const char = str.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash |= 0;
  }
  return Math.abs(hash).toString(36);
}

function stripHtml(html) {
  return (html || "")
    .replace(/<[^>]*>/g, "")
    .replace(/&[^;]+;/g, " ")
    .trim();
}

function extractImageUrl(item) {
  if (item.enclosure && item.enclosure.url) return item.enclosure.url;
  const match = (item.content || "").match(/<img[^>]+src="([^"]+)"/);
  return match ? match[1] : null;
}

function extractTags(item) {
  const tags = [];
  if (item.categories) {
    tags.push(
      ...item.categories
        .map((c) => (typeof c === "string" ? c : c.name || ""))
        .filter(Boolean),
    );
  }
  return tags.slice(0, 10);
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: Trust scoring + keyword ranking
// ═══════════════════════════════════════════════════════════════════════════
function scoreItem(item, trustProfile) {
  const profile = TRUST_PROFILES[trustProfile] || TRUST_PROFILES.unclassified;
  const trustScore = profile.minScore + 0.1; // Base trust from source profile
  const rankingWeight = profile.weight;

  // Keyword-based opportunity scoring
  let opportunityScore = 0;
  const textLower = `${item.title} ${item.body}`.toLowerCase();
  const commandSignals = [];

  for (const [signal, config] of Object.entries(RANKING_KEYWORDS)) {
    if (config.keywords.some((kw) => textLower.includes(kw))) {
      opportunityScore += config.lift;
      commandSignals.push(signal.replace(/_/g, "-"));
    }
  }

  opportunityScore = Math.min(opportunityScore, 1.0);
  const strategicScore = Math.min(
    trustScore * rankingWeight + opportunityScore,
    3.0,
  );

  return {
    trustScore,
    rankingWeight,
    trustProfileKey: trustProfile,
    promoterOpportunityScore: opportunityScore,
    strategicScore,
    commandSignals,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: Safety check (basic keyword blocklist)
// ═══════════════════════════════════════════════════════════════════════════
const BLOCKED_KEYWORDS = [
  "gambling",
  "betting odds",
  "sportsbook",
  "wager",
  "steroids",
  "doping scandal",
];

function isSafe(item) {
  const textLower = `${item.title} ${item.body}`.toLowerCase();
  return !BLOCKED_KEYWORDS.some((kw) => textLower.includes(kw));
}

// ═══════════════════════════════════════════════════════════════════════════
// CORE: Aggregate, score, rank, persist
// ═══════════════════════════════════════════════════════════════════════════
async function runFeedAggregation() {
  const startTime = Date.now();

  // 1. Load feed sources (Firestore-first, fallback to defaults)
  let sources = [];
  try {
    const snap = await db
      .collection(FEED_SOURCES_COLLECTION)
      .where("enabled", "==", true)
      .get();
    if (!snap.empty) {
      sources = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    }
  } catch (_) {
    // Collection may not exist yet
  }

  if (sources.length === 0) {
    sources = DEFAULT_SOURCES;
  }

  // 2. Fetch from all sources in parallel
  const rssSources = sources.filter((s) => s.type === "rss");
  const fetchPromises = rssSources.map((s) => fetchRssFeed(s));
  const results = await Promise.allSettled(fetchPromises);

  let allItems = [];
  results.forEach((result, i) => {
    if (result.status === "fulfilled") {
      const source = rssSources[i];
      const scored = result.value.filter(isSafe).map((item) => ({
        ...item,
        ...scoreItem(item, source.trustProfile || "unclassified"),
      }));
      allItems.push(...scored);
    }
  });

  // 3. Deduplicate by ID
  const seen = new Set();
  allItems = allItems.filter((item) => {
    if (seen.has(item.id)) return false;
    seen.add(item.id);
    return true;
  });

  // 4. Rank by strategic score (descending)
  allItems.sort((a, b) => b.strategicScore - a.strategicScore);
  allItems = allItems.slice(0, MAX_CACHE_ITEMS);

  // 5. Write to Firestore cache (batch writes, 400 per batch)
  const BATCH_LIMIT = 400;
  for (let i = 0; i < allItems.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    const chunk = allItems.slice(i, i + BATCH_LIMIT);

    for (const item of chunk) {
      const ref = db.collection(FEED_CACHE_COLLECTION).doc(item.id);
      batch.set(
        ref,
        {
          ...item,
          publishedAt: admin.firestore.Timestamp.fromDate(
            item.publishedAt instanceof Date ? item.publishedAt : new Date(),
          ),
          cachedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    await batch.commit();
  }

  // 6. Prune stale items (older than STALE_HOURS)
  const cutoff = new Date(Date.now() - STALE_HOURS * 60 * 60 * 1000);
  const staleSnap = await db
    .collection(FEED_CACHE_COLLECTION)
    .where("publishedAt", "<", admin.firestore.Timestamp.fromDate(cutoff))
    .limit(400)
    .get();

  if (!staleSnap.empty) {
    const pruneBatch = db.batch();
    staleSnap.docs.forEach((doc) => pruneBatch.delete(doc.ref));
    await pruneBatch.commit();
    console.log(`Pruned ${staleSnap.size} stale feed items`);
  }

  // 7. Write run metadata
  await db
    .collection("system_metadata")
    .doc("auto_feed_last_run")
    .set({
      ranAt: admin.firestore.FieldValue.serverTimestamp(),
      itemsCached: allItems.length,
      sourcesFetched: rssSources.length,
      itemsPruned: staleSnap.empty ? 0 : staleSnap.size,
      durationMs: Date.now() - startTime,
    });

  console.log(
    `Auto-feed aggregation complete: ${allItems.length} items cached from ${rssSources.length} sources (${Date.now() - startTime}ms)`,
  );

  return {
    itemsCached: allItems.length,
    sourcesFetched: rssSources.length,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULED FUNCTION — Runs every 15 minutes
// ═══════════════════════════════════════════════════════════════════════════
const autoFeedAggregator = onSchedule(
  {
    schedule: "every 15 minutes",
    region: REGION,
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async () => {
    await runFeedAggregation();
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE — Manual trigger for admin (refresh feed on demand)
// ═══════════════════════════════════════════════════════════════════════════
const autoFeedRefresh = onCall({ region: REGION }, async (request) => {
  // Optional: restrict to admin
  const uid = request.auth?.uid;
  if (uid) {
    const userDoc = await db.collection("users").doc(uid).get();
    const role = userDoc.exists ? userDoc.data().role : "fan";
    if (role !== "admin") {
      return { status: "error", message: "Admin access required" };
    }
  }

  const result = await runFeedAggregation();
  return { status: "ok", ...result };
});

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════
module.exports = {
  autoFeedAggregator,
  autoFeedRefresh,
};
