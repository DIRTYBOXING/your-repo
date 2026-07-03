/**
 * DFC Live Collections Seed Script
 * Seeds: posts, ppv_events, events
 * Run: node scripts/seed_live_collections.js
 *
 * Uses Application Default Credentials (firebase-admin with GOOGLE_APPLICATION_CREDENTIALS)
 * or pass --key=<path-to-service-account.json>
 */
"use strict";

const admin = require("firebase-admin");
const path = require("path");

// ── Credential resolution ─────────────────────────────────────────────────
const keyArg = process.argv.find((a) => a.startsWith("--key="));
if (keyArg) {
  const keyPath = keyArg.replace("--key=", "");
  const serviceAccount = require(path.resolve(keyPath));
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
} else {
  // Falls back to GOOGLE_APPLICATION_CREDENTIALS env var or Firebase CLI login
  admin.initializeApp();
}

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const now = TS.now();

function daysFromNow(n) {
  return TS.fromDate(new Date(Date.now() + n * 86400000));
}

// ═══════════════════════════════════════════════════════════════════════════
// POSTS — Social Feed
// ═══════════════════════════════════════════════════════════════════════════
const posts = [
  {
    userId: "dfc_official",
    userDisplayName: "Data Fight Central",
    userAvatarUrl: "assets/logos/DFC logo with cyan glow effect.png",
    userRole: "admin",
    isVerified: true,
    postType: "text",
    content:
      "🥊 WELCOME TO DATA FIGHT CENTRAL — the world's first combat sports intelligence platform. Real fights. Real data. Real fighters. The era of fake fight content is over. #DFC #CombatSports",
    likes: 247,
    commentCount: 38,
    shareCount: 91,
    likedBy: [],
    bookmarkedBy: [],
    mediaUrls: [],
    mediaTypes: [],
    visibility: "public",
    createdAt: TS.fromDate(new Date(Date.now() - 3 * 3600000)),
  },
  {
    userId: "dfc_official",
    userDisplayName: "Data Fight Central",
    userAvatarUrl: "assets/logos/DFC logo with cyan glow effect.png",
    userRole: "admin",
    isVerified: true,
    postType: "article",
    content:
      "🔥 UFC 327 is locked in — headlined by a championship bout that has the entire MMA world talking. Full fight card breakdown, odds analysis, and DFC fight intelligence now live.",
    thumbnailUrl: "assets/ppv/ppv-ufc-327_thumb.jpg",
    imageUrl: "assets/ppv/ppv-ufc-327_hero.jpg",
    mediaUrls: ["assets/ppv/ppv-ufc-327_hero.jpg"],
    mediaTypes: ["image"],
    likes: 183,
    commentCount: 29,
    shareCount: 57,
    likedBy: [],
    bookmarkedBy: [],
    visibility: "public",
    createdAt: TS.fromDate(new Date(Date.now() - 5 * 3600000)),
  },
  {
    userId: "dfc_official",
    userDisplayName: "Data Fight Central",
    userAvatarUrl: "assets/logos/DFC logo with cyan glow effect.png",
    userRole: "admin",
    isVerified: true,
    postType: "article",
    content:
      "🏆 ETERNAL MMA 88 IS LIVE ON DFC — Australia's fastest-growing promotion is back. Stream live or catch the replay exclusively on Data Fight Central. Link in profile.",
    thumbnailUrl: "assets/ppv/ppv-eternal88_thumb.jpg",
    imageUrl: "assets/ppv/ppv-eternal88_hero.jpg",
    mediaUrls: ["assets/ppv/ppv-eternal88_hero.jpg"],
    mediaTypes: ["image"],
    likes: 96,
    commentCount: 14,
    shareCount: 33,
    likedBy: [],
    bookmarkedBy: [],
    visibility: "public",
    createdAt: TS.fromDate(new Date(Date.now() - 8 * 3600000)),
  },
  {
    userId: "dfc_media",
    userDisplayName: "DFC Media Desk",
    userAvatarUrl: "assets/logos/DFC logo with cyan glow effect.png",
    userRole: "media",
    isVerified: true,
    postType: "text",
    content:
      "📊 Fight IQ Stat of the Day: Fighters with a clinch success rate above 68% win at a 74% clip in championship rounds. Data from the DFC Intelligence Engine — powered by 51 Firestore collections of real fight data.",
    likes: 74,
    commentCount: 11,
    shareCount: 22,
    likedBy: [],
    bookmarkedBy: [],
    mediaUrls: [],
    mediaTypes: [],
    visibility: "public",
    createdAt: TS.fromDate(new Date(Date.now() - 12 * 3600000)),
  },
  {
    userId: "dfc_media",
    userDisplayName: "DFC Media Desk",
    userAvatarUrl: "assets/logos/DFC logo with cyan glow effect.png",
    userRole: "media",
    isVerified: true,
    postType: "article",
    content:
      "🥋 BKFC HITS QUEENSLAND — Bare Knuckle Fighting Championship touches down in Townsville. Hepi headlines a stacked card. Stream live on DFC.",
    thumbnailUrl: "assets/ppv/ppv-bkfc-townsville-hepi_thumb.jpg",
    imageUrl: "assets/ppv/ppv-bkfc-townsville-hepi_hero.jpg",
    mediaUrls: ["assets/ppv/ppv-bkfc-townsville-hepi_hero.jpg"],
    mediaTypes: ["image"],
    likes: 138,
    commentCount: 21,
    shareCount: 44,
    likedBy: [],
    bookmarkedBy: [],
    visibility: "public",
    createdAt: TS.fromDate(new Date(Date.now() - 18 * 3600000)),
  },
  {
    userId: "dfc_media",
    userDisplayName: "DFC Media Desk",
    userAvatarUrl: "assets/logos/DFC logo with cyan glow effect.png",
    userRole: "media",
    isVerified: true,
    postType: "text",
    content:
      "🌏 The DFC Events Map is live — fight events across 6 continents pinned in real time. From Brisbane to Bangkok, from Bogota to Bahrain. The global fight calendar has never looked like this. Check the Explore tab.",
    likes: 201,
    commentCount: 44,
    shareCount: 78,
    likedBy: [],
    bookmarkedBy: [],
    mediaUrls: [],
    mediaTypes: [],
    visibility: "public",
    createdAt: TS.fromDate(new Date(Date.now() - 24 * 3600000)),
  },
  {
    userId: "dfc_official",
    userDisplayName: "Data Fight Central",
    userAvatarUrl: "assets/logos/DFC logo with cyan glow effect.png",
    userRole: "admin",
    isVerified: true,
    postType: "article",
    content:
      "🌟 IBC 03 — International Boxing Championships Round 3. Two belts on the line. Four continents represented. Stream it first on DFC.",
    thumbnailUrl: "assets/ppv/ppv-ibc-03_thumb.jpg",
    imageUrl: "assets/ppv/ppv-ibc-03_hero.jpg",
    mediaUrls: ["assets/ppv/ppv-ibc-03_hero.jpg"],
    mediaTypes: ["image"],
    likes: 155,
    commentCount: 27,
    shareCount: 51,
    likedBy: [],
    bookmarkedBy: [],
    visibility: "public",
    createdAt: TS.fromDate(new Date(Date.now() - 30 * 3600000)),
  },
  {
    userId: "dfc_media",
    userDisplayName: "DFC Media Desk",
    userAvatarUrl: "assets/logos/DFC logo with cyan glow effect.png",
    userRole: "media",
    isVerified: true,
    postType: "text",
    content:
      "💡 DFC Platform Update: Fighter verification is now live. 418 screens. 262 services. 51 Firestore collections. Built from Logan Central. This isn't a demo. This is the real fight platform.",
    likes: 312,
    commentCount: 67,
    shareCount: 103,
    likedBy: [],
    bookmarkedBy: [],
    mediaUrls: [],
    mediaTypes: [],
    visibility: "public",
    createdAt: TS.fromDate(new Date(Date.now() - 36 * 3600000)),
  },
];

// ═══════════════════════════════════════════════════════════════════════════
// PPV EVENTS — Firestore collection: ppv_events
// status options: 'announced' | 'presale' | 'onSale' | 'live' | 'ended'
// ═══════════════════════════════════════════════════════════════════════════
const ppvEvents = [
  {
    id: "ppv-ufc-327",
    eventId: "ppv-ufc-327",
    promoterId: "ufc",
    title: "UFC 327",
    subtitle: "Championship Night",
    description:
      "A world title is on the line as UFC returns with one of the most anticipated cards of 2026. Stream live on DFC.",
    sport: "MMA",
    promotion: "UFC",
    posterUrl: "assets/ppv/ppv-ufc-327_hero.jpg",
    isFinalPoster: true,
    posterAssetKind: "hero",
    eventDate: daysFromNow(14),
    status: "onSale",
    standardPriceCents: 5999,
    earlyBirdPriceCents: 4999,
    currency: "AUD",
    streamPlatforms: ["DFC"],
    purchaseCount: 1842,
    peakViewers: 0,
    totalRevenueCents: 0,
    fightCard: [],
    chatEnabled: true,
    predictionsEnabled: true,
    platformFeePct: 0.3,
    createdAt: TS.fromDate(new Date(Date.now() - 30 * 86400000)),
  },
  {
    id: "ppv-ufc-328",
    eventId: "ppv-ufc-328",
    promoterId: "ufc",
    title: "UFC 328",
    subtitle: "Legacy on the Line",
    description:
      "Two legends. One night. The biggest UFC card of the year lands on DFC.",
    sport: "MMA",
    promotion: "UFC",
    posterUrl: "assets/ppv/ppv-ufc-328_hero.jpg",
    isFinalPoster: true,
    posterAssetKind: "hero",
    eventDate: daysFromNow(35),
    status: "presale",
    standardPriceCents: 5999,
    earlyBirdPriceCents: 4499,
    currency: "AUD",
    streamPlatforms: ["DFC"],
    purchaseCount: 934,
    peakViewers: 0,
    totalRevenueCents: 0,
    fightCard: [],
    chatEnabled: true,
    predictionsEnabled: true,
    platformFeePct: 0.3,
    createdAt: TS.fromDate(new Date(Date.now() - 14 * 86400000)),
  },
  {
    id: "ppv-eternal88",
    eventId: "ppv-eternal88",
    promoterId: "eternal-mma",
    title: "Eternal MMA 88",
    subtitle: "Brisbane Fight Night",
    description:
      "Australia's premier MMA promotion returns for its 88th event — Brisbane's biggest fight night of 2026.",
    sport: "MMA",
    promotion: "Eternal MMA",
    posterUrl: "assets/ppv/ppv-eternal88_hero.jpg",
    isFinalPoster: true,
    posterAssetKind: "hero",
    eventDate: daysFromNow(7),
    status: "onSale",
    standardPriceCents: 2999,
    currency: "AUD",
    streamPlatforms: ["DFC"],
    purchaseCount: 611,
    peakViewers: 0,
    totalRevenueCents: 0,
    fightCard: [],
    chatEnabled: true,
    predictionsEnabled: true,
    platformFeePct: 0.3,
    createdAt: TS.fromDate(new Date(Date.now() - 21 * 86400000)),
  },
  {
    id: "ppv-ibc-03",
    eventId: "ppv-ibc-03",
    promoterId: "ibc",
    title: "IBC 03",
    subtitle: "International Boxing Championships",
    description:
      "Two world title bouts. Four continents represented. International Boxing Championships Round 3.",
    sport: "Boxing",
    promotion: "IBC",
    posterUrl: "assets/ppv/ppv-ibc-03_hero.jpg",
    isFinalPoster: true,
    posterAssetKind: "hero",
    eventDate: daysFromNow(21),
    status: "onSale",
    standardPriceCents: 3999,
    currency: "AUD",
    streamPlatforms: ["DFC"],
    purchaseCount: 488,
    peakViewers: 0,
    totalRevenueCents: 0,
    fightCard: [],
    chatEnabled: true,
    predictionsEnabled: true,
    platformFeePct: 0.3,
    createdAt: TS.fromDate(new Date(Date.now() - 18 * 86400000)),
  },
  {
    id: "ppv-bkfc-72",
    eventId: "ppv-bkfc-72",
    promoterId: "bkfc",
    title: "BKFC 72",
    subtitle: "Bare Knuckle Bloodsport",
    description:
      "No gloves. No mercy. BKFC 72 brings the world's most raw combat sport to DFC.",
    sport: "Bare Knuckle",
    promotion: "BKFC",
    posterUrl: "assets/ppv/ppv-bkfc-72_hero.jpg",
    isFinalPoster: true,
    posterAssetKind: "hero",
    eventDate: daysFromNow(28),
    status: "announced",
    standardPriceCents: 2499,
    currency: "AUD",
    streamPlatforms: ["DFC"],
    purchaseCount: 312,
    peakViewers: 0,
    totalRevenueCents: 0,
    fightCard: [],
    chatEnabled: true,
    predictionsEnabled: true,
    platformFeePct: 0.3,
    createdAt: TS.fromDate(new Date(Date.now() - 10 * 86400000)),
  },
  {
    id: "ppv-bkfc-townsville-hepi",
    eventId: "ppv-bkfc-townsville-hepi",
    promoterId: "bkfc",
    title: "BKFC Townsville",
    subtitle: "Hepi Headlines",
    description:
      "Bare Knuckle Fighting Championship touches down in Townsville, Queensland. Hepi headlines a stacked card.",
    sport: "Bare Knuckle",
    promotion: "BKFC",
    posterUrl: "assets/ppv/ppv-bkfc-townsville-hepi_hero.jpg",
    isFinalPoster: true,
    posterAssetKind: "hero",
    eventDate: daysFromNow(42),
    status: "announced",
    standardPriceCents: 1999,
    currency: "AUD",
    streamPlatforms: ["DFC"],
    purchaseCount: 178,
    peakViewers: 0,
    totalRevenueCents: 0,
    fightCard: [],
    chatEnabled: true,
    predictionsEnabled: true,
    platformFeePct: 0.3,
    createdAt: TS.fromDate(new Date(Date.now() - 7 * 86400000)),
  },
  {
    id: "ppv-brisbane-bonanza",
    eventId: "ppv-brisbane-bonanza",
    promoterId: "dfc",
    title: "Brisbane Bonanza",
    subtitle: "All Codes. One Night.",
    description:
      "The DFC flagship event — MMA, Boxing, Muay Thai and BKFC bouts on one card. Brisbane has never seen anything like this.",
    sport: "Multi-Discipline",
    promotion: "DFC",
    posterUrl: "assets/ppv/ppv-brisbane-bonanza_hero.jpg",
    isFinalPoster: true,
    posterAssetKind: "hero",
    eventDate: daysFromNow(56),
    status: "presale",
    standardPriceCents: 4999,
    earlyBirdPriceCents: 3999,
    currency: "AUD",
    streamPlatforms: ["DFC"],
    purchaseCount: 1104,
    peakViewers: 0,
    totalRevenueCents: 0,
    fightCard: [],
    chatEnabled: true,
    predictionsEnabled: true,
    platformFeePct: 0.3,
    createdAt: TS.fromDate(new Date(Date.now() - 5 * 86400000)),
  },
];

// ═══════════════════════════════════════════════════════════════════════════
// EVENTS — Global Events Map (lat/lng required)
// ═══════════════════════════════════════════════════════════════════════════
const events = [
  {
    title: "UFC 327 — Las Vegas",
    latitude: 36.1699,
    longitude: -115.1398,
    eventDate: daysFromNow(14),
    ticketPrice: 250,
    broadcaster: "DFC",
    sport: "MMA",
    promotion: "UFC",
    venue: "T-Mobile Arena",
    city: "Las Vegas",
    country: "USA",
  },
  {
    title: "Eternal MMA 88 — Brisbane",
    latitude: -27.4698,
    longitude: 153.0251,
    eventDate: daysFromNow(7),
    ticketPrice: 85,
    broadcaster: "DFC",
    sport: "MMA",
    promotion: "Eternal MMA",
    venue: "Brisbane Entertainment Centre",
    city: "Brisbane",
    country: "Australia",
  },
  {
    title: "IBC 03 — London",
    latitude: 51.5074,
    longitude: -0.1278,
    eventDate: daysFromNow(21),
    ticketPrice: 180,
    broadcaster: "DFC",
    sport: "Boxing",
    promotion: "IBC",
    venue: "The O2 Arena",
    city: "London",
    country: "UK",
  },
  {
    title: "BKFC 72 — Tampa",
    latitude: 27.9506,
    longitude: -82.4572,
    eventDate: daysFromNow(28),
    ticketPrice: 120,
    broadcaster: "DFC",
    sport: "Bare Knuckle",
    promotion: "BKFC",
    venue: "Amalie Arena",
    city: "Tampa",
    country: "USA",
  },
  {
    title: "BKFC Townsville — Hepi Headliner",
    latitude: -19.259,
    longitude: 146.8169,
    eventDate: daysFromNow(42),
    ticketPrice: 65,
    broadcaster: "DFC",
    sport: "Bare Knuckle",
    promotion: "BKFC",
    venue: "Townsville Entertainment & Convention Centre",
    city: "Townsville",
    country: "Australia",
  },
  {
    title: "ONE 170 — Bangkok",
    latitude: 13.7563,
    longitude: 100.5018,
    eventDate: daysFromNow(10),
    ticketPrice: 200,
    broadcaster: "DFC",
    sport: "Muay Thai / MMA",
    promotion: "ONE Championship",
    venue: "Impact Arena",
    city: "Bangkok",
    country: "Thailand",
  },
  {
    title: "Brisbane Bonanza — DFC Flagship",
    latitude: -27.4698,
    longitude: 153.0251,
    eventDate: daysFromNow(56),
    ticketPrice: 150,
    broadcaster: "DFC",
    sport: "Multi-Discipline",
    promotion: "DFC",
    venue: "Queensland Country Bank Stadium",
    city: "Brisbane",
    country: "Australia",
  },
  {
    title: "PFL Pittsburgh 2026",
    latitude: 40.4406,
    longitude: -79.9959,
    eventDate: daysFromNow(18),
    ticketPrice: 130,
    broadcaster: "DFC",
    sport: "MMA",
    promotion: "PFL",
    venue: "PPG Paints Arena",
    city: "Pittsburgh",
    country: "USA",
  },
  {
    title: "IFMA Antalya Cup",
    latitude: 36.8969,
    longitude: 30.7133,
    eventDate: daysFromNow(30),
    ticketPrice: 50,
    broadcaster: "DFC",
    sport: "Muay Thai",
    promotion: "IFMA",
    venue: "Antalya Arena",
    city: "Antalya",
    country: "Turkey",
  },
  {
    title: "UFC Perth 2026",
    latitude: -31.9505,
    longitude: 115.8605,
    eventDate: daysFromNow(49),
    ticketPrice: 195,
    broadcaster: "DFC",
    sport: "MMA",
    promotion: "UFC",
    venue: "RAC Arena",
    city: "Perth",
    country: "Australia",
  },
  {
    title: "Legends 45 — Adelaide",
    latitude: -34.9285,
    longitude: 138.6007,
    eventDate: daysFromNow(35),
    ticketPrice: 75,
    broadcaster: "DFC",
    sport: "MMA",
    promotion: "Legends MMA",
    venue: "Hindmarsh Stadium",
    city: "Adelaide",
    country: "Australia",
  },
  {
    title: "Adelaide Contender Series 12",
    latitude: -34.9285,
    longitude: 138.6007,
    eventDate: daysFromNow(63),
    ticketPrice: 60,
    broadcaster: "DFC",
    sport: "MMA",
    promotion: "DFC",
    venue: "Adelaide Entertainment Centre",
    city: "Adelaide",
    country: "Australia",
  },
];

// ═══════════════════════════════════════════════════════════════════════════
// SEED
// ═══════════════════════════════════════════════════════════════════════════
async function seed() {
  const batch1 = db.batch();
  const batch2 = db.batch();
  const batch3 = db.batch();

  // Posts
  console.log(`Seeding ${posts.length} posts...`);
  for (const post of posts) {
    const ref = db.collection("posts").doc();
    batch1.set(ref, post);
  }
  await batch1.commit();
  console.log("✅ posts seeded");

  // PPV Events
  console.log(`Seeding ${ppvEvents.length} ppv_events...`);
  for (const ppv of ppvEvents) {
    const { id, ...data } = ppv;
    const ref = db.collection("ppv_events").doc(id);
    batch2.set(ref, data, { merge: true });
  }
  await batch2.commit();
  console.log("✅ ppv_events seeded");

  // Events (map)
  console.log(`Seeding ${events.length} events...`);
  for (const ev of events) {
    const ref = db.collection("events").doc();
    batch3.set(ref, ev);
  }
  await batch3.commit();
  console.log("✅ events seeded");

  console.log("\n🔥 DFC is live. All three collections seeded.");
}

seed().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
