// ═══════════════════════════════════════════════════════════════════════════
// DFC WATERFALL ENGINE — Professional Content Conveyor Belt
// ═══════════════════════════════════════════════════════════════════════════
//
// CONVEYOR STAGES:
//   1. INTAKE      — Raw RSS articles land in ingested_content (status: 'new')
//   2. SCORE       — Each article scored: freshness + trust + category demand + breaking detection
//   3. PROMOTE     — Waterfall tiers: BREAKING → FEATURED → STANDARD → REGIONAL
//   4. BALANCE     — Exposure caps per category/region (no single sport floods the feed)
//   5. HYPE        — Pre-event & live-event amplification (boost articles matching active events)
//   6. DUMP        — Post-event adrenaline dump (recap, highlights, results prioritized)
//   7. ARCHIVE     — Old content cycles out, new content cycles in (30-day TTL)
//
// Runs every 15 minutes after RSS ingestion completes.
// ═══════════════════════════════════════════════════════════════════════════

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

// ═══════════════════════════════════════════════════════════════════════════
// CONVEYOR BELT CONFIGURATION — The Dials
// ═══════════════════════════════════════════════════════════════════════════

// How many articles per promotion tier per cycle
const PROMOTION_LIMITS = {
  breaking: 3, // Max 3 breaking articles per 15-min cycle
  featured: 8, // Max 8 featured slots per cycle
  standard: 30, // Max 30 standard articles per cycle
  regional: 15, // Max 15 regional/niche per cycle
};

// Category exposure caps — % of total feed_content that can be one category
// Prevents MMA flooding out boxing, kickboxing, etc.
const CATEGORY_BALANCE = {
  mma: 0.3, // Max 30% of published feed
  boxing: 0.25, // Max 25%
  brawling: 0.1, // Max 10% (BKFC, bare knuckle)
  kickboxing: 0.1, // Max 10%
  muay_thai: 0.08, // Max 8%
  wrestling: 0.08, // Max 8%
  general: 0.09, // Max 9% (cross-sport, mainstream coverage)
};

// Region exposure caps — ensures global diversity
const REGION_BALANCE = {
  us: 0.35, // US gets 35% max (biggest market, most sources)
  uk: 0.12,
  eu: 0.1,
  au: 0.1,
  jp: 0.05,
  kr: 0.03,
  br: 0.05,
  ca: 0.04,
  in: 0.03,
  global: 0.08,
  _other: 0.05, // Everything else combined
};

// Breaking news keyword detection
const BREAKING_KEYWORDS = [
  "breaking",
  "just in",
  "official",
  "confirmed",
  "announced",
  "signed",
  "released",
  "cut from",
  "suspended",
  "stripped",
  "weigh-in",
  "main event",
  "title fight",
  "championship",
  "ko ",
  "knockout",
  "submission",
  "tko",
  "decision",
  "pulled from",
  "cancelled",
  "postponed",
  "injury",
  "drug test",
  "usada",
  "failed test",
  "popped",
  "retirement",
  "retires",
  "comeback",
  "returns",
  "record-breaking",
  "fastest",
  "historic",
];

// Event-mode keywords (hype engine activates)
const EVENT_HYPE_KEYWORDS = [
  "ufc ",
  "fight night",
  "ppv",
  "main card",
  "prelims",
  "bellator",
  "pfl",
  "one championship",
  "rizin",
  "canelo",
  "fury",
  "joshua",
  "crawford",
  "spence",
  "matchroom",
  "top rank",
  "showtime",
  "dazn",
  "tonight",
  "this weekend",
  "fight week",
  "weigh-ins",
  "press conference",
  "faceoff",
  "face off",
  "staredown",
];

// Post-event dump keywords (adrenaline cooldown)
const DUMP_KEYWORDS = [
  "results",
  "recap",
  "highlights",
  "full card results",
  "scorecards",
  "judges",
  "post-fight",
  "aftermath",
  "bonus winners",
  "performance of the night",
  "fight of the night",
  "what happened",
  "how it went",
  "round-by-round",
  "winner",
  "loser",
  "upset",
  "underdog",
  "replay",
  "slow motion",
  "finish",
];

// Content freshness decay curve (hours → score multiplier)
function freshnessScore(publishedAt) {
  const ageHours =
    (Date.now() - new Date(publishedAt).getTime()) / (1000 * 60 * 60);
  if (ageHours < 1) return 1.0; // < 1 hour: max freshness
  if (ageHours < 3) return 0.95; // 1-3 hours: near-max
  if (ageHours < 6) return 0.85; // 3-6 hours: still hot
  if (ageHours < 12) return 0.7; // 6-12 hours: warm
  if (ageHours < 24) return 0.5; // 12-24 hours: cooling
  if (ageHours < 48) return 0.3; // 1-2 days: cold
  if (ageHours < 168) return 0.15; // 2-7 days: archive zone
  return 0.05; // 7+ days: nearly dead
}

// ═══════════════════════════════════════════════════════════════════════════
// STAGE 2: SCORING ENGINE — Compute rank_score for each ingested article
// ═══════════════════════════════════════════════════════════════════════════

function computeRankScore(article) {
  const title = (article.title || "").toLowerCase();
  const summary = (article.summary || "").toLowerCase();
  const text = title + " " + summary;

  // Base score from source trust (0.75–0.98 → normalized to 0–1 range)
  const trustBase = ((article.trustScore || 0.8) - 0.7) / 0.3; // 0.7→0, 1.0→1

  // Freshness (exponential decay)
  const freshness = freshnessScore(article.publishedAt);

  // Breaking news detection
  let breakingBoost = 0;
  let breakingCount = 0;
  for (const kw of BREAKING_KEYWORDS) {
    if (text.includes(kw)) breakingCount++;
  }
  if (breakingCount >= 3) breakingBoost = 0.35;
  else if (breakingCount >= 2) breakingBoost = 0.25;
  else if (breakingCount >= 1) breakingBoost = 0.15;

  // Event hype detection
  let hypeBoost = 0;
  let hypeCount = 0;
  for (const kw of EVENT_HYPE_KEYWORDS) {
    if (text.includes(kw)) hypeCount++;
  }
  if (hypeCount >= 3) hypeBoost = 0.2;
  else if (hypeCount >= 1) hypeBoost = 0.1;

  // Post-event dump detection
  let dumpBoost = 0;
  let dumpCount = 0;
  for (const kw of DUMP_KEYWORDS) {
    if (text.includes(kw)) dumpCount++;
  }
  if (dumpCount >= 3) dumpBoost = 0.15;
  else if (dumpCount >= 1) dumpBoost = 0.08;

  // Image bonus (articles with images rank higher in visual feeds)
  const imageBonus = article.imageUrl ? 0.05 : 0;

  // Summary length bonus (longer summaries = richer content)
  const summaryBonus = (article.summary || "").length > 200 ? 0.03 : 0;

  // Composite score (0–1 scale, can exceed 1 for breaking+hype combos)
  const raw =
    trustBase * 0.25 + // 25% weight: source credibility
    freshness * 0.3 + // 30% weight: time decay (most important)
    breakingBoost + // Additive: breaking news
    hypeBoost + // Additive: event proximity
    dumpBoost + // Additive: post-event recap
    imageBonus + // Additive: has visual
    summaryBonus; // Additive: content depth

  // Clamp to 0–1 range for storage
  return Math.min(1.0, Math.max(0, parseFloat(raw.toFixed(4))));
}

// Determine promotion tier from score
function assignTier(score, breakingCount) {
  if (score >= 0.85 && breakingCount >= 2) return "breaking";
  if (score >= 0.7) return "featured";
  if (score >= 0.4) return "standard";
  return "regional";
}

// ═══════════════════════════════════════════════════════════════════════════
// STAGE 3+4: WATERFALL PROMOTER — Score, tier, balance, promote
// ═══════════════════════════════════════════════════════════════════════════

async function runWaterfallPromotion() {
  const stats = {
    scored: 0,
    promoted: { breaking: 0, featured: 0, standard: 0, regional: 0 },
    skippedBalance: 0,
    skippedQuality: 0,
    archived: 0,
  };

  // ── Get current category/region distribution in feed_content ──
  const publishedSnap = await db
    .collection("feed_content")
    .where("status", "==", "published")
    .select("category", "region")
    .get();

  const totalPublished = publishedSnap.size || 1;
  const categoryCounts = {};
  const regionCounts = {};

  for (const doc of publishedSnap.docs) {
    const d = doc.data();
    categoryCounts[d.category] = (categoryCounts[d.category] || 0) + 1;
    regionCounts[d.region] = (regionCounts[d.region] || 0) + 1;
  }

  // ── Pull new ingested articles ──
  const newDocs = await db
    .collection("ingested_content")
    .where("status", "==", "new")
    .orderBy("ingestedAt", "desc")
    .limit(200)
    .get();

  if (newDocs.empty) {
    console.log("[Waterfall] No new articles to process.");
    return stats;
  }

  // ── Score and sort all candidates ──
  const candidates = [];
  for (const doc of newDocs.docs) {
    const data = doc.data();

    // Quality gate: must have title, URL, and min 20-char title
    if (!data.title || !data.url || data.title.length < 20) {
      stats.skippedQuality++;
      continue;
    }

    const title = (data.title || "").toLowerCase();
    const summary = (data.summary || "").toLowerCase();
    const text = title + " " + summary;

    let breakingCount = 0;
    for (const kw of BREAKING_KEYWORDS) {
      if (text.includes(kw)) breakingCount++;
    }

    const score = computeRankScore(data);
    const tier = assignTier(score, breakingCount);

    candidates.push({ ref: doc.ref, data, score, tier, breakingCount });
    stats.scored++;
  }

  // Sort by score descending — best content first
  candidates.sort((a, b) => b.score - a.score);

  // ── Waterfall promotion with balance checks ──
  const tierCounts = { breaking: 0, featured: 0, standard: 0, regional: 0 };
  const batch = db.batch();
  let batchSize = 0;

  for (const candidate of candidates) {
    const { ref, data, score, tier } = candidate;

    // Tier cap check
    if (tierCounts[tier] >= PROMOTION_LIMITS[tier]) {
      // Tier full — try to demote to next tier
      const fallbackTier =
        tier === "breaking"
          ? "featured"
          : tier === "featured"
            ? "standard"
            : tier === "standard"
              ? "regional"
              : null;
      if (
        !fallbackTier ||
        tierCounts[fallbackTier] >= PROMOTION_LIMITS[fallbackTier]
      ) {
        stats.skippedBalance++;
        // Mark as 'queued' so it gets picked up next cycle
        batch.update(ref, { status: "queued" });
        batchSize++;
        if (batchSize >= 490) break; // Firestore batch limit is 500
        continue;
      }
      // Demote to fallback tier
      candidate.tier = fallbackTier;
    }

    // Category balance check
    const catKey = data.category || "general";
    const catCap = CATEGORY_BALANCE[catKey] || CATEGORY_BALANCE.general;
    const catCurrent = (categoryCounts[catKey] || 0) / totalPublished;
    if (catCurrent >= catCap && totalPublished > 50) {
      // Category over-represented — only allow breaking through
      if (candidate.tier !== "breaking") {
        stats.skippedBalance++;
        batch.update(ref, { status: "queued" });
        batchSize++;
        if (batchSize >= 490) break;
        continue;
      }
    }

    // Region balance check
    const regKey = data.region || "global";
    const regCap = REGION_BALANCE[regKey] || REGION_BALANCE._other;
    const regCurrent = (regionCounts[regKey] || 0) / totalPublished;
    if (regCurrent >= regCap && totalPublished > 50) {
      if (candidate.tier !== "breaking") {
        stats.skippedBalance++;
        batch.update(ref, { status: "queued" });
        batchSize++;
        if (batchSize >= 490) break;
        continue;
      }
    }

    // ── PROMOTE: Write to feed_content ──
    const feedRef = db.collection("feed_content").doc();
    batch.set(feedRef, {
      title: data.title,
      summary: (data.summary || "").slice(0, 300),
      source: data.source || "",
      category: data.category || "general",
      region: data.region || "global",
      url: data.url,
      imageUrl: data.imageUrl || null,
      posterUrl: data.imageUrl || null, // Mirror for EventModel compatibility
      heroImageUrl: data.imageUrl || null, // Mirror for hero banner widgets
      promoterLogoUrl: data.promoterLogoUrl || data.sourceLogoUrl || null,
      publishedAt: data.publishedAt || new Date().toISOString(),
      trustScore: data.trustScore || 0.8,
      authorName: data.authorName || data.source || "",
      attribution:
        data.attribution ||
        "Originally published by " + (data.source || "unknown"),
      tags: data.tags || [],
      // Waterfall fields
      status: "published",
      tier: candidate.tier,
      rankScore: score,
      isBreaking: candidate.tier === "breaking",
      isFeatured:
        candidate.tier === "featured" || candidate.tier === "breaking",
      feedType:
        data.feedType || (candidate.tier === "breaking" ? "EVENT" : "NEWS"),
      promotedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Mark ingested as promoted
    batch.update(ref, {
      status: "promoted",
      tier: candidate.tier,
      rankScore: score,
    });

    tierCounts[candidate.tier]++;
    stats.promoted[candidate.tier]++;
    categoryCounts[catKey] = (categoryCounts[catKey] || 0) + 1;
    regionCounts[regKey] = (regionCounts[regKey] || 0) + 1;
    batchSize++;

    if (batchSize >= 490) break; // Firestore batch limit
  }

  if (batchSize > 0) {
    await batch.commit();
  }

  console.log(
    `[Waterfall] Scored: ${stats.scored} | Promoted: B=${stats.promoted.breaking} F=${stats.promoted.featured} S=${stats.promoted.standard} R=${stats.promoted.regional} | Balanced-skip: ${stats.skippedBalance} | Quality-skip: ${stats.skippedQuality}`,
  );
  return stats;
}

// ═══════════════════════════════════════════════════════════════════════════
// HYPE RAMP CURVE — Event proximity countdown boost
// ═══════════════════════════════════════════════════════════════════════════
//
//   HYPE LEVEL
//   ▲
//   │        ████  ← FIGHT NIGHT (max hype)
//   │       █    █
//   │      █      █
//   │    ██        ██  ← Post-event dump
//   │  ██            ████  ← Slow decay
//   │██                  ████████  ← Archive
//   └──────────────────────────────────► TIME
//    -7d  -3d  -1d  LIVE  +6h  +24h  +72h
//
// As events approach: hype ramps UP (articles boosted more aggressively)
// During event: MAXIMUM boost (everything related is featured/breaking)
// After event: photos/images/highlights FLOOD, then slowly decay out
// ═══════════════════════════════════════════════════════════════════════════

// Hype ramp: hours until event → boost multiplier
function getHypeMultiplier(hoursUntilEvent) {
  if (hoursUntilEvent <= 0 && hoursUntilEvent >= -4) return 1.0; // LIVE — max hype
  if (hoursUntilEvent <= 1) return 0.95; // < 1 hour out — nearly live
  if (hoursUntilEvent <= 3) return 0.85; // 1-3 hours — fight night imminent
  if (hoursUntilEvent <= 6) return 0.75; // 3-6 hours — weigh-in day energy
  if (hoursUntilEvent <= 12) return 0.65; // 12 hours — tomorrow night
  if (hoursUntilEvent <= 24) return 0.55; // 1 day — fight week peak
  if (hoursUntilEvent <= 48) return 0.45; // 2 days — fight week rising
  if (hoursUntilEvent <= 72) return 0.35; // 3 days — fight week begins
  if (hoursUntilEvent <= 168) return 0.2; // 1 week — announcement hype
  if (hoursUntilEvent <= 336) return 0.1; // 2 weeks — early promo
  return 0.05; // 2+ weeks — low simmer
}

// Post-event dump decay: hours since event ended → dump intensity
// Media content (photos, highlights, results) floods then slowly fades
function getDumpIntensity(hoursSinceEnd) {
  if (hoursSinceEnd <= 1) return 1.0; // 0-1h: ADRENALINE PEAK — results, KO clips, reactions
  if (hoursSinceEnd <= 3) return 0.9; // 1-3h: HIGHLIGHT FLOOD — photos, slow-mo, replays
  if (hoursSinceEnd <= 6) return 0.75; // 3-6h: RECAP WAVE — post-fight interviews, analysis
  if (hoursSinceEnd <= 12) return 0.55; // 6-12h: MORNING AFTER — scorecards, takeaways
  if (hoursSinceEnd <= 24) return 0.35; // 12-24h: NEXT DAY — deep analysis, what's next
  if (hoursSinceEnd <= 48) return 0.2; // 24-48h: COOLING — injury updates, callouts
  if (hoursSinceEnd <= 72) return 0.1; // 48-72h: WINDING DOWN — aftermath, rankings impact
  return 0.0; // 72h+: dump complete, let next event take over
}

// Media content keywords (photos, images, video content from events)
const MEDIA_KEYWORDS = [
  "photo",
  "photos",
  "image",
  "images",
  "gallery",
  "video",
  "clip",
  "footage",
  "watch",
  "stream",
  "highlight",
  "highlights",
  "replay",
  "slow motion",
  "slow-mo",
  "behind the scenes",
  "backstage",
  "locker room",
  "walkout",
  "entrance",
  "weigh-in photos",
  "face-off photos",
  "ko clip",
  "finish clip",
  "submission clip",
  "press conference video",
  "interview",
  "post-fight interview",
  "embedded",
  "countdown",
  "promo video",
  "trailer",
];

// ═══════════════════════════════════════════════════════════════════════════
// STAGE 5: HYPE ENGINE — Event Proximity Countdown Ramp
// ═══════════════════════════════════════════════════════════════════════════
//
// Scans ALL events within 2-week window. For each event:
//   - Computes hype multiplier based on countdown
//   - Builds fighter/promotion keyword sets
//   - Boosts matching content proportionally to proximity
//   - As events get closer: MORE articles boosted, HIGHER scores
//   - Multiple events can run simultaneously (next event ramps up
//     while current event dumps)
// ═══════════════════════════════════════════════════════════════════════════

async function runHypeEngine() {
  const stats = { boosted: 0, events: 0, eventDetails: [] };
  const now = new Date();
  const twoWeeksAhead = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);
  const fourHoursAgo = new Date(now.getTime() - 4 * 60 * 60 * 1000); // include live events

  // ── Fetch all events in the hype window (2 weeks ahead + currently live) ──
  let upcomingEvents = [];
  try {
    // Events with eventDate (primary field from EventModel)
    const eventSnap = await db
      .collection("events")
      .where("eventDate", ">=", fourHoursAgo.toISOString())
      .where("eventDate", "<=", twoWeeksAhead.toISOString())
      .limit(20)
      .get();

    upcomingEvents = eventSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  } catch (_) {
    // events collection may not exist yet
  }

  // Also check for events stored with startTime field (legacy format)
  try {
    const legacySnap = await db
      .collection("events")
      .where("startTime", ">=", fourHoursAgo.toISOString())
      .where("startTime", "<=", twoWeeksAhead.toISOString())
      .limit(20)
      .get();

    const existingIds = new Set(upcomingEvents.map((e) => e.id));
    for (const doc of legacySnap.docs) {
      if (!existingIds.has(doc.id)) {
        upcomingEvents.push({ id: doc.id, ...doc.data() });
      }
    }
  } catch (_) {}

  if (upcomingEvents.length === 0) {
    console.log("[Hype Engine] No upcoming events in 2-week window. Idling.");
    return stats;
  }

  stats.events = upcomingEvents.length;

  // ── Process each event: compute ramp + build keywords ──
  const eventProfiles = [];
  for (const evt of upcomingEvents) {
    const eventTime = new Date(evt.eventDate || evt.startTime || evt.date);
    const hoursUntil = (eventTime.getTime() - now.getTime()) / (1000 * 60 * 60);
    const hypeMultiplier = getHypeMultiplier(hoursUntil);

    // Build keyword set from event data
    const keywords = new Set();
    const name = (evt.name || evt.title || "").toLowerCase();
    // Add full event name and individual words > 3 chars
    if (name) {
      keywords.add(name);
      name
        .split(/[\s\-:]+/)
        .filter((w) => w.length >= 4)
        .forEach((w) => keywords.add(w));
    }
    // Add promotion name
    if (evt.promotionName) keywords.add(evt.promotionName.toLowerCase());
    if (evt.promotion) keywords.add(evt.promotion.toLowerCase());
    // Add fighter names from fightIds or embedded fighters
    if (evt.fighters && Array.isArray(evt.fighters)) {
      for (const f of evt.fighters) {
        const fname = (f.name || f.fighterName || "").toLowerCase();
        if (fname) {
          keywords.add(fname);
          fname
            .split(/\s+/)
            .filter((w) => w.length >= 4)
            .forEach((w) => keywords.add(w));
        }
      }
    }
    // Add venue, city for local hype
    if (evt.venue) keywords.add(evt.venue.toLowerCase());
    if (evt.city) keywords.add(evt.city.toLowerCase());

    const hypePhase =
      hoursUntil > 72
        ? "early_promo"
        : hoursUntil > 24
          ? "fight_week"
          : hoursUntil > 6
            ? "fight_day"
            : hoursUntil > 0
              ? "imminent"
              : "live";

    eventProfiles.push({
      id: evt.id,
      name: name,
      hoursUntil: Math.round(hoursUntil * 10) / 10,
      hypeMultiplier,
      hypePhase,
      keywords: [...keywords],
      region: evt.country || evt.region || "global",
      sportType: evt.sportType || "mma",
    });

    stats.eventDetails.push({
      id: evt.id,
      name: name,
      phase: hypePhase,
      multiplier: hypeMultiplier,
      keywordCount: keywords.size,
    });
  }

  // ── Boost published content matching event keywords ──
  const recentFeed = await db
    .collection("feed_content")
    .where("status", "==", "published")
    .orderBy("promotedAt", "desc")
    .limit(200)
    .get();

  const batch = db.batch();
  let batchSize = 0;

  for (const doc of recentFeed.docs) {
    const data = doc.data();
    // Skip if already at max hype or recently hyped (prevent re-boost spam)
    if (data.rankScore >= 0.98) continue;
    if (data.hypeAt) {
      const hypeAge =
        (now.getTime() -
          new Date(
            data.hypeAt._seconds ? data.hypeAt._seconds * 1000 : data.hypeAt,
          ).getTime()) /
        (1000 * 60 * 60);
      if (hypeAge < 2) continue; // Don't re-hype within 2 hours
    }

    const text = (
      (data.title || "") +
      " " +
      (data.summary || "")
    ).toLowerCase();

    // Check against all events — article could match multiple events
    let bestBoost = 0;
    let bestEventId = null;
    let bestPhase = null;

    for (const profile of eventProfiles) {
      let matchScore = 0;
      for (const kw of profile.keywords) {
        if (text.includes(kw)) {
          matchScore += kw.length >= 8 ? 2 : 1; // Longer keywords = stronger match
        }
      }

      if (matchScore >= 2) {
        // Scale boost by hype multiplier (closer event = bigger boost)
        const boost = Math.min(
          0.35,
          profile.hypeMultiplier * 0.35 * (matchScore / 6),
        );
        if (boost > bestBoost) {
          bestBoost = boost;
          bestEventId = profile.id;
          bestPhase = profile.hypePhase;
        }
      }
    }

    if (bestBoost > 0.05) {
      const newScore = Math.min(1.0, (data.rankScore || 0.5) + bestBoost);
      const updateFields = {
        rankScore: newScore,
        isFeatured: true,
        hypeBoost: true,
        hypeEventId: bestEventId,
        hypePhase: bestPhase,
        hypeBoostAmount: parseFloat(bestBoost.toFixed(3)),
        hypeAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Imminent/live events: upgrade tier to featured
      if (bestPhase === "imminent" || bestPhase === "live") {
        updateFields.tier = "featured";
      }

      batch.update(doc.ref, updateFields);
      stats.boosted++;
      batchSize++;
      if (batchSize >= 490) break;
    }
  }

  if (batchSize > 0) await batch.commit();

  console.log(
    `[Hype Engine] Events: ${stats.events} | Boosted: ${stats.boosted} articles`,
  );
  for (const evt of stats.eventDetails) {
    console.log(
      `  → ${evt.name}: phase=${evt.phase} multiplier=${evt.multiplier} keywords=${evt.keywordCount}`,
    );
  }
  return stats;
}

// ═══════════════════════════════════════════════════════════════════════════
// STAGE 6: ADRENALINE DUMP — Hyperdrive Post-Event Media Decay System
// ═══════════════════════════════════════════════════════════════════════════
//
// After an event ends:
//   PHASE 1 (0-1h):  ADRENALINE PEAK — Results, KO clips, reactions FLOOD the feed
//   PHASE 2 (1-3h):  HIGHLIGHT FLOOD — Photos, galleries, slow-mo replays
//   PHASE 3 (3-6h):  RECAP WAVE — Post-fight interviews, analysis
//   PHASE 4 (6-12h): MORNING AFTER — Scorecards, takeaways, "what happened"
//   PHASE 5 (12-24h): NEXT DAY — Deep analysis, injury reports, what's next
//   PHASE 6 (24-48h): COOLING — Rankings impact, callouts, future matchups
//   PHASE 7 (48-72h): WIND DOWN — Move aside for next event's hype ramp
//
// Media content (photos, images, video) gets EXTRA boost during early phases
// then slowly decays to make room for the NEXT event's hype ramp
// ═══════════════════════════════════════════════════════════════════════════

async function runAdrenalineDump() {
  const stats = {
    dumped: 0,
    mediaBoosts: 0,
    decayed: 0,
    eventsEnded: 0,
    phases: {},
  };
  const now = new Date();
  const threeDaysAgo = new Date(now.getTime() - 72 * 60 * 60 * 1000);

  // ── Find recently ended events (up to 72 hours ago) ──
  let endedEvents = [];
  try {
    // Check events with status 'results' or 'completed'
    const resultSnap = await db
      .collection("events")
      .where("status", "in", ["results", "completed"])
      .limit(20)
      .get();

    for (const doc of resultSnap.docs) {
      const data = doc.data();
      const eventTime = new Date(
        data.eventDate || data.endTime || data.startTime,
      );
      const hoursSince =
        (now.getTime() - eventTime.getTime()) / (1000 * 60 * 60);
      if (hoursSince >= 0 && hoursSince <= 72) {
        endedEvents.push({ id: doc.id, ...data, hoursSinceEnd: hoursSince });
      }
    }
  } catch (_) {}

  // Fallback: also check by eventDate in past 72h
  try {
    const pastSnap = await db
      .collection("events")
      .where("eventDate", ">=", threeDaysAgo.toISOString())
      .where("eventDate", "<=", now.toISOString())
      .limit(20)
      .get();

    const existingIds = new Set(endedEvents.map((e) => e.id));
    for (const doc of pastSnap.docs) {
      if (!existingIds.has(doc.id)) {
        const data = doc.data();
        const eventTime = new Date(data.eventDate);
        const hoursSince =
          (now.getTime() - eventTime.getTime()) / (1000 * 60 * 60);
        if (hoursSince >= 0) {
          endedEvents.push({ id: doc.id, ...data, hoursSinceEnd: hoursSince });
        }
      }
    }
  } catch (_) {}

  stats.eventsEnded = endedEvents.length;

  if (endedEvents.length === 0) {
    console.log("[Adrenaline Dump] No recent ended events. Skipping.");
    return stats;
  }

  // ── Build keyword profiles for ended events ──
  const endedProfiles = [];
  for (const evt of endedEvents) {
    const intensity = getDumpIntensity(evt.hoursSinceEnd);
    const keywords = new Set();
    const name = (evt.name || evt.title || "").toLowerCase();
    if (name) {
      keywords.add(name);
      name
        .split(/[\s\-:]+/)
        .filter((w) => w.length >= 4)
        .forEach((w) => keywords.add(w));
    }
    if (evt.promotionName) keywords.add(evt.promotionName.toLowerCase());
    if (evt.fighters && Array.isArray(evt.fighters)) {
      for (const f of evt.fighters) {
        const fname = (f.name || "").toLowerCase();
        if (fname) keywords.add(fname);
      }
    }

    const phase =
      evt.hoursSinceEnd <= 1
        ? "adrenaline_peak"
        : evt.hoursSinceEnd <= 3
          ? "highlight_flood"
          : evt.hoursSinceEnd <= 6
            ? "recap_wave"
            : evt.hoursSinceEnd <= 12
              ? "morning_after"
              : evt.hoursSinceEnd <= 24
                ? "next_day"
                : evt.hoursSinceEnd <= 48
                  ? "cooling"
                  : "wind_down";

    endedProfiles.push({
      id: evt.id,
      name: name,
      intensity,
      phase,
      hoursSince: Math.round(evt.hoursSinceEnd * 10) / 10,
      keywords: [...keywords],
    });

    stats.phases[phase] = (stats.phases[phase] || 0) + 1;
  }

  // ── Process feed content: boost event-related, decay old dump content ──
  const recentFeed = await db
    .collection("feed_content")
    .where("status", "==", "published")
    .orderBy("promotedAt", "desc")
    .limit(200)
    .get();

  const batch = db.batch();
  let batchSize = 0;

  for (const doc of recentFeed.docs) {
    const data = doc.data();
    const text = (
      (data.title || "") +
      " " +
      (data.summary || "")
    ).toLowerCase();

    // ── DECAY: Previously dumped content that's now stale ──
    if (data.adrenalineDump && data.dumpEventId) {
      const matchingEvent = endedProfiles.find(
        (p) => p.id === data.dumpEventId,
      );
      if (matchingEvent) {
        const currentIntensity = matchingEvent.intensity;
        const previousScore = data.rankScore || 0.5;

        // Decay: reduce score proportional to fading intensity
        if (currentIntensity < 0.3 && previousScore > 0.5) {
          const decayedScore = Math.max(0.2, previousScore * currentIntensity);
          batch.update(doc.ref, {
            rankScore: parseFloat(decayedScore.toFixed(4)),
            dumpPhase: matchingEvent.phase,
            dumpDecayAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          stats.decayed++;
          batchSize++;
          if (batchSize >= 490) break;
          continue;
        }
      }
    }

    // ── BOOST: Fresh content matching ended events ──
    if (data.adrenalineDump) continue; // Already processed

    let bestBoost = 0;
    let bestEventId = null;
    let bestPhase = null;
    let isMediaContent = false;

    for (const profile of endedProfiles) {
      if (profile.intensity <= 0) continue; // Dump complete for this event

      let matchScore = 0;
      for (const kw of profile.keywords) {
        if (text.includes(kw)) matchScore++;
      }

      // Check for dump-specific keywords (results, recap, highlights)
      let dumpKeywordHits = 0;
      for (const kw of DUMP_KEYWORDS) {
        if (text.includes(kw)) dumpKeywordHits++;
      }

      // Check for media content (photos, video, images)
      let mediaHits = 0;
      for (const kw of MEDIA_KEYWORDS) {
        if (text.includes(kw)) mediaHits++;
      }

      const totalRelevance = matchScore + dumpKeywordHits;
      if (totalRelevance >= 2) {
        // Base boost from dump intensity (proximity to event end)
        let boost = profile.intensity * 0.3;

        // Extra boost for media content (photos/video get preferential treatment)
        if (mediaHits >= 1) {
          boost += profile.intensity * 0.15; // Media gets +15% intensity-scaled boost
          isMediaContent = true;
        }

        // Extra boost for high dump keyword density (actual results/recaps)
        if (dumpKeywordHits >= 3) boost += 0.08;

        boost = Math.min(0.4, boost);

        if (boost > bestBoost) {
          bestBoost = boost;
          bestEventId = profile.id;
          bestPhase = profile.phase;
        }
      }
    }

    if (bestBoost > 0.05) {
      const newScore = Math.min(1.0, (data.rankScore || 0.5) + bestBoost);
      batch.update(doc.ref, {
        rankScore: newScore,
        isFeatured: bestPhase !== "wind_down",
        adrenalineDump: true,
        dumpEventId: bestEventId,
        dumpPhase: bestPhase,
        dumpBoostAmount: parseFloat(bestBoost.toFixed(3)),
        isMediaContent: isMediaContent,
        dumpAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      stats.dumped++;
      if (isMediaContent) stats.mediaBoosts++;
      batchSize++;
      if (batchSize >= 490) break;
    }
  }

  if (batchSize > 0) await batch.commit();

  console.log(
    `[Adrenaline Dump] Events: ${stats.eventsEnded} | Dumped: ${stats.dumped} | Media: ${stats.mediaBoosts} | Decayed: ${stats.decayed}`,
  );
  for (const [phase, count] of Object.entries(stats.phases)) {
    console.log(`  → Phase: ${phase} (${count} events)`);
  }
  return stats;
}

// ═══════════════════════════════════════════════════════════════════════════
// STAGE 7: ARCHIVE SWEEP — Cycle old content out (30-day TTL)
// ═══════════════════════════════════════════════════════════════════════════

async function runArchiveSweep() {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  let archived = 0;

  // Archive old feed_content
  const oldFeed = await db
    .collection("feed_content")
    .where("status", "==", "published")
    .where("publishedAt", "<=", thirtyDaysAgo.toISOString())
    .limit(200)
    .get();

  if (!oldFeed.empty) {
    const batch = db.batch();
    for (const doc of oldFeed.docs) {
      batch.update(doc.ref, { status: "archived" });
      archived++;
    }
    await batch.commit();
  }

  // Clean up old ingested_content (promoted/queued older than 7 days)
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  let cleaned = 0;

  const oldIngested = await db
    .collection("ingested_content")
    .where("status", "in", ["promoted", "queued"])
    .where("ingestedAt", "<=", sevenDaysAgo)
    .limit(200)
    .get();

  if (!oldIngested.empty) {
    const batch = db.batch();
    for (const doc of oldIngested.docs) {
      batch.update(doc.ref, { status: "expired" });
      cleaned++;
    }
    await batch.commit();
  }

  console.log(
    `[Archive Sweep] Archived: ${archived} feed articles. Expired: ${cleaned} ingested docs.`,
  );
  return { archived, cleaned };
}

// ═══════════════════════════════════════════════════════════════════════════
// RE-QUEUE: Pick up 'queued' articles from previous cycles
// ═══════════════════════════════════════════════════════════════════════════

async function reQueueStalled() {
  let requeued = 0;

  const queuedDocs = await db
    .collection("ingested_content")
    .where("status", "==", "queued")
    .orderBy("ingestedAt", "desc")
    .limit(50)
    .get();

  if (!queuedDocs.empty) {
    const batch = db.batch();
    for (const doc of queuedDocs.docs) {
      batch.update(doc.ref, { status: "new" }); // put back on conveyor
      requeued++;
    }
    await batch.commit();
  }

  console.log(
    `[Re-Queue] Recycled ${requeued} queued articles back to conveyor.`,
  );
  return { requeued };
}

// ═══════════════════════════════════════════════════════════════════════════
// MASTER CONVEYOR — Runs all stages in sequence (scheduled)
// ═══════════════════════════════════════════════════════════════════════════

const waterfallConveyor = onSchedule(
  { schedule: "every 15 minutes", region: REGION },
  async () => {
    console.log("[Waterfall Conveyor] ===== BELT START =====");
    const startTime = Date.now();

    // Stage 1: Re-queue stalled items from previous cycles
    const requeue = await reQueueStalled();

    // Stage 2+3+4: Score, tier, balance, promote
    const promotion = await runWaterfallPromotion();

    // Stage 5: Hype Engine (event proximity boost)
    const hype = await runHypeEngine();

    // Stage 6: Adrenaline Dump (post-event recap boost)
    const dump = await runAdrenalineDump();

    // Stage 7: Archive sweep (30-day TTL)
    const archive = await runArchiveSweep();

    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);

    // Write conveyor run stats for monitoring
    await db.collection("conveyor_runs").add({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      elapsedSeconds: parseFloat(elapsed),
      requeue,
      promotion,
      hype,
      dump,
      archive,
    });

    console.log(`[Waterfall Conveyor] ===== BELT COMPLETE (${elapsed}s) =====`);
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// MANUAL TRIGGER — Force a conveyor run + get stats back
// ═══════════════════════════════════════════════════════════════════════════

const triggerWaterfall = onCall({ region: REGION }, async () => {
  console.log("[Waterfall] Manual trigger fired.");
  const startTime = Date.now();

  const requeue = await reQueueStalled();
  const promotion = await runWaterfallPromotion();
  const hype = await runHypeEngine();
  const dump = await runAdrenalineDump();
  const archive = await runArchiveSweep();

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);

  return {
    elapsed: elapsed + "s",
    requeue,
    promotion,
    hype,
    dump,
    archive,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// FEED HEALTH DASHBOARD — Get pipeline stats (callable)
// ═══════════════════════════════════════════════════════════════════════════

const getFeedHealth = onCall({ region: REGION }, async () => {
  // Count by status in ingested_content
  const [newCount, queuedCount, promotedCount] = await Promise.all([
    db
      .collection("ingested_content")
      .where("status", "==", "new")
      .count()
      .get(),
    db
      .collection("ingested_content")
      .where("status", "==", "queued")
      .count()
      .get(),
    db
      .collection("ingested_content")
      .where("status", "==", "promoted")
      .count()
      .get(),
  ]);

  // Count by status in feed_content
  const [publishedCount, archivedCount] = await Promise.all([
    db
      .collection("feed_content")
      .where("status", "==", "published")
      .count()
      .get(),
    db
      .collection("feed_content")
      .where("status", "==", "archived")
      .count()
      .get(),
  ]);

  // Category distribution
  const publishedSnap = await db
    .collection("feed_content")
    .where("status", "==", "published")
    .select("category", "region", "tier", "rankScore")
    .get();

  const categoryDist = {};
  const regionDist = {};
  const tierDist = {};
  let avgScore = 0;

  for (const doc of publishedSnap.docs) {
    const d = doc.data();
    categoryDist[d.category || "unknown"] =
      (categoryDist[d.category || "unknown"] || 0) + 1;
    regionDist[d.region || "unknown"] =
      (regionDist[d.region || "unknown"] || 0) + 1;
    tierDist[d.tier || "unscored"] = (tierDist[d.tier || "unscored"] || 0) + 1;
    avgScore += d.rankScore || 0;
  }

  const total = publishedSnap.size || 1;
  avgScore = parseFloat((avgScore / total).toFixed(3));

  // Last conveyor run
  let lastRun = null;
  try {
    const lastRunSnap = await db
      .collection("conveyor_runs")
      .orderBy("timestamp", "desc")
      .limit(1)
      .get();
    if (!lastRunSnap.empty) {
      lastRun = lastRunSnap.docs[0].data();
    }
  } catch (_) {}

  return {
    pipeline: {
      ingested: {
        new: newCount.data().count,
        queued: queuedCount.data().count,
        promoted: promotedCount.data().count,
      },
      published: publishedCount.data().count,
      archived: archivedCount.data().count,
    },
    balance: {
      categories: categoryDist,
      categoryCaps: CATEGORY_BALANCE,
      regions: regionDist,
      regionCaps: REGION_BALANCE,
      tiers: tierDist,
    },
    scoring: {
      averageRankScore: avgScore,
      promotionLimitsPerCycle: PROMOTION_LIMITS,
    },
    lastConveyorRun: lastRun,
  };
});

module.exports = {
  waterfallConveyor,
  triggerWaterfall,
  getFeedHealth,
  // Export internals for testing
  computeRankScore,
  PROMOTION_LIMITS,
  CATEGORY_BALANCE,
  REGION_BALANCE,
};
