#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const admin = require("firebase-admin");

function printUsage(error, exitCode = 0) {
  const stream = exitCode === 0 ? process.stdout : process.stderr;
  if (error) {
    stream.write(`Error: ${error}\n\n`);
  }
  stream.write(
    [
      "Usage:",
      "  npm run seed:real-event -- --file data/real_event_seed.json",
      "  npm run seed:real-event -- --file data/real_event_seed.json --dry-run",
      "",
      "Payload file shape:",
      "  {",
      '    "event": { ... },',
      '    "ppv": { ...optional },',
      '    "promoter": { ...optional },',
      '    "fighters": [ ...optional ]',
      "  }",
      "",
      "Minimal payload also supported:",
      "  {",
      '    "title": "Real Event Title",',
      '    "promoterId": "promoter_123",',
      '    "date": "2026-04-24",',
      '    "time": "19:00",',
      '    "venue": "Venue Name",',
      '    "city": "Melbourne",',
      '    "country": "Australia",',
      '    "posterUrl": "https://...",',
      '    "price": 24.99,',
      '    "platforms": ["DFC Live"]',
      "  }",
    ].join("\n"),
  );
  process.exit(exitCode);
}

function parseArgs(argv) {
  const args = { file: null, dryRun: false };

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === "--file" || token === "-f") {
      args.file = argv[index + 1] || null;
      index += 1;
      continue;
    }
    if (token === "--dry-run") {
      args.dryRun = true;
      continue;
    }
    if (token === "--help" || token === "-h") {
      printUsage(undefined, 0);
    }
    printUsage(`Unknown argument: ${token}`, 1);
  }

  if (!args.file) {
    printUsage("Missing required --file argument.", 1);
  }

  return args;
}

function loadPayload(filePath) {
  const absolutePath = path.resolve(process.cwd(), filePath);
  if (!fs.existsSync(absolutePath)) {
    throw new Error(`Payload file not found: ${absolutePath}`);
  }

  try {
    const raw = fs.readFileSync(absolutePath, "utf8");
    return { absolutePath, payload: JSON.parse(raw) };
  } catch (error) {
    throw new Error(`Failed to parse JSON payload: ${error.message}`);
  }
}

function requireString(value, label) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`${label} is required.`);
  }
  return value.trim();
}

function optionalString(value) {
  if (typeof value !== "string") {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function optionalNumber(value) {
  if (value === null || value === undefined || value === "") {
    return undefined;
  }

  const numberValue = Number(value);
  if (Number.isNaN(numberValue)) {
    throw new TypeError(`Expected numeric value, received: ${value}`);
  }
  return numberValue;
}

function parseDate(value, label) {
  if (!value) {
    return undefined;
  }

  const dateValue = new Date(value);
  if (Number.isNaN(dateValue.getTime())) {
    throw new TypeError(`Invalid date for ${label}: ${value}`);
  }
  return dateValue;
}

function timestampOrUndefined(value, label) {
  const dateValue = parseDate(value, label);
  return dateValue ? admin.firestore.Timestamp.fromDate(dateValue) : undefined;
}

function compactObject(input) {
  return Object.fromEntries(
    Object.entries(input).filter(([, value]) => value !== undefined),
  );
}

function getStringArray(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => (typeof item === "string" ? item.trim() : item))
    .filter(Boolean);
}

function firstString(...values) {
  for (const value of values) {
    const normalized = optionalString(value);
    if (normalized) {
      return normalized;
    }
  }
  return undefined;
}

function slugify(value) {
  const normalized = String(value || "")
    .trim()
    .toLowerCase()
    .replaceAll(/[^a-z0-9]+/g, "-")
    .replaceAll(/^-+|-+$/g, "");

  return normalized || "event";
}

function combineDateAndTime(dateValue, timeValue) {
  const normalizedDate = requireString(dateValue, "date");
  const normalizedTime = optionalString(timeValue);
  if (!normalizedTime || normalizedDate.includes("T")) {
    return normalizedDate;
  }

  const timeWithSeconds = /^\d{2}:\d{2}$/.test(normalizedTime)
    ? `${normalizedTime}:00`
    : normalizedTime;
  return `${normalizedDate}T${timeWithSeconds}`;
}

function hasBundleSections(payload) {
  return Boolean(
    payload &&
    typeof payload === "object" &&
    (payload.event || payload.ppv || payload.promoter || payload.fighters),
  );
}

function normalizeMinimalPayload(payload) {
  const title = requireString(payload.title, "title");
  const promoterId = requireString(payload.promoterId, "promoterId");
  const date = combineDateAndTime(payload.date, payload.time);
  const venue = requireString(payload.venue, "venue");
  const city = requireString(payload.city, "city");
  const country = requireString(payload.country, "country");
  const posterUrl = requireString(payload.posterUrl, "posterUrl");
  const price = optionalNumber(payload.price);
  const platforms = getStringArray(payload.platforms);
  const generatedId = `${slugify(title)}-${slugify(payload.date)}`;
  const sportType = firstString(payload.sportType) || "Combat Sports";

  return compactObject({
    event: compactObject({
      id: firstString(payload.eventId, payload.id) || generatedId,
      promoterId,
      title,
      description: firstString(payload.description),
      venue,
      city,
      state: firstString(payload.state),
      country,
      eventDate: date,
      mainCardTime: date,
      sportType,
      status: firstString(payload.status) || "upcoming",
      posterUrl,
      thumbnailUrl: posterUrl,
      bannerUrl: posterUrl,
      broadcastInfo: platforms[0],
      streamProviders: platforms,
      isFeatured: true,
      isPublic: true,
      price,
    }),
    ppv: compactObject({
      id: firstString(payload.ppvId) || generatedId,
      promoterId,
      title,
      description: firstString(payload.description),
      sport: sportType,
      status: "onSale",
      price,
      currency: firstString(payload.currency) || "AUD",
      streamPlatforms: platforms,
    }),
    promoter: firstString(payload.promoterName)
      ? compactObject({
          id: promoterId,
          name: firstString(payload.promoterName),
          city,
          state: firstString(payload.state),
          country,
        })
      : undefined,
    fighters: Array.isArray(payload.fighters) ? payload.fighters : undefined,
  });
}

function parseRecord(record) {
  if (!record) {
    return { wins: 0, losses: 0, draws: 0, noContests: 0 };
  }

  const parts = String(record)
    .split("-")
    .map((item) => Number(item.trim()));
  if (parts.some((value) => Number.isNaN(value))) {
    throw new Error(`Invalid record value: ${record}`);
  }

  return {
    wins: parts[0] || 0,
    losses: parts[1] || 0,
    draws: parts[2] || 0,
    noContests: parts[3] || 0,
  };
}

function normalizeEventStatus(status) {
  const normalized = String(status || "upcoming")
    .trim()
    .toLowerCase();

  switch (normalized) {
    case "draft":
    case "announced":
    case "upcoming":
    case "live":
    case "results":
    case "completed":
    case "archived":
    case "canceled":
      return normalized;
    case "onsale":
    case "on_sale":
      return "onSale";
    case "cancelled":
      return "canceled";
    default:
      return "upcoming";
  }
}

function normalizePpvStatus(status) {
  const normalized = String(status || "onSale")
    .trim()
    .toLowerCase();

  switch (normalized) {
    case "announced":
      return "announced";
    case "presale":
      return "presale";
    case "onsale":
    case "on_sale":
    case "sale":
    case "upcoming":
      return "onSale";
    case "live":
      return "live";
    case "replay":
    case "results":
    case "completed":
      return "replay";
    case "expired":
    case "archived":
    case "canceled":
    case "cancelled":
      return "expired";
    default:
      return "onSale";
  }
}

function buildFightCard(fights, eventId) {
  if (!Array.isArray(fights)) {
    return [];
  }

  return fights.map((fight, index) => {
    const fighter1Name =
      firstString(fight.fighter1Name, fight.redCorner) || undefined;
    const fighter2Name =
      firstString(fight.fighter2Name, fight.blueCorner) || undefined;

    if (!fighter1Name || !fighter2Name) {
      throw new Error(`fightCard[${index}] must include fighter names.`);
    }

    return compactObject({
      fightId: firstString(fight.fightId) || `${eventId}_fight_${index + 1}`,
      fighter1Name,
      fighter2Name,
      weightClass: firstString(fight.weightClass),
      rounds: optionalNumber(fight.rounds) || 3,
      isMainEvent: fight.isMainEvent === true || index === 0,
      isTitleFight: fight.isTitleFight === true,
      boutOrder: optionalNumber(fight.boutOrder) || index + 1,
    });
  });
}

function resolveEventStreamProviders(eventInput, ppvInput) {
  const directProviders = getStringArray(eventInput.streamProviders);
  if (directProviders.length > 0) {
    return directProviders;
  }

  return getStringArray(ppvInput.streamPlatforms);
}

function resolveSponsors(primary, fallback) {
  if (Array.isArray(primary)) {
    return primary;
  }
  if (Array.isArray(fallback)) {
    return fallback;
  }
  return [];
}

function resolveStandardPriceCents(ppvInput, eventInput) {
  if (ppvInput.standardPriceCents !== undefined) {
    return optionalNumber(ppvInput.standardPriceCents) || 0;
  }
  if (ppvInput.price !== undefined) {
    return Math.round((optionalNumber(ppvInput.price) || 0) * 100);
  }
  if (eventInput.price !== undefined) {
    return Math.round((optionalNumber(eventInput.price) || 0) * 100);
  }
  return 0;
}

function buildContext(payload) {
  if (!payload || typeof payload !== "object") {
    throw new Error("Seed payload must be a JSON object.");
  }

  const normalizedPayload = hasBundleSections(payload)
    ? payload
    : normalizeMinimalPayload(payload);

  const eventInput = normalizedPayload.event || {};
  const ppvInput =
    normalizedPayload.ppv && typeof normalizedPayload.ppv === "object"
      ? normalizedPayload.ppv
      : {};
  const promoterInput =
    normalizedPayload.promoter && typeof normalizedPayload.promoter === "object"
      ? normalizedPayload.promoter
      : null;
  const fightersInput = Array.isArray(normalizedPayload.fighters)
    ? normalizedPayload.fighters
    : [];

  const eventId = requireString(
    eventInput.id || eventInput.eventId,
    "event.id or event.eventId",
  );
  const promoterId = requireString(
    eventInput.promoterId || ppvInput.promoterId || promoterInput?.id,
    "event.promoterId, ppv.promoterId, or promoter.id",
  );
  const eventTitle = requireString(
    eventInput.title || eventInput.name || ppvInput.title,
    "event.title or event.name",
  );
  const eventDate = parseDate(
    eventInput.eventDate || eventInput.startTime || ppvInput.eventDate,
    "event.eventDate",
  );
  if (!eventDate) {
    throw new Error("event.eventDate or event.startTime is required.");
  }

  return {
    eventInput,
    ppvInput,
    promoterInput,
    fightersInput,
    eventId,
    promoterId,
    eventTitle,
    eventDate,
    mainCardTime: parseDate(
      eventInput.mainCardTime || eventInput.startTime,
      "event.mainCardTime",
    ),
    latitude: optionalNumber(eventInput.latitude ?? eventInput.lat),
    longitude: optionalNumber(eventInput.longitude ?? eventInput.lng),
    eventStatus: normalizeEventStatus(eventInput.status),
    eventStreamProviders: resolveEventStreamProviders(eventInput, ppvInput),
    ppvEnabled:
      normalizedPayload.ppv !== null && normalizedPayload.ppv !== false,
  };
}

function buildEventDoc(context) {
  const {
    eventInput,
    ppvInput,
    promoterInput,
    promoterId,
    eventTitle,
    eventDate,
    mainCardTime,
    latitude,
    longitude,
    eventStatus,
    eventStreamProviders,
  } = context;

  return compactObject({
    promoterId,
    promoter: promoterId,
    promotionName: firstString(
      eventInput.promotionName,
      ppvInput.promotion,
      promoterInput?.name,
    ),
    name: eventTitle,
    title: eventTitle,
    description: firstString(eventInput.description, ppvInput.description),
    venue: requireString(
      eventInput.venue || eventInput.venueName,
      "event.venue or event.venueName",
    ),
    venueName: requireString(
      eventInput.venueName || eventInput.venue,
      "event.venue or event.venueName",
    ),
    city: requireString(eventInput.city, "event.city"),
    state: firstString(eventInput.state),
    country: requireString(eventInput.country, "event.country"),
    eventDate: admin.firestore.Timestamp.fromDate(eventDate),
    date: admin.firestore.Timestamp.fromDate(eventDate),
    mainCardTime: mainCardTime
      ? admin.firestore.Timestamp.fromDate(mainCardTime)
      : undefined,
    sportType:
      firstString(eventInput.sportType, ppvInput.sport) || "Combat Sports",
    status: eventStatus,
    posterUrl: firstString(eventInput.posterUrl),
    thumbnailUrl: firstString(eventInput.thumbnailUrl, eventInput.posterUrl),
    bannerUrl: firstString(eventInput.bannerUrl, eventInput.posterUrl),
    posterAspectRatio: optionalNumber(eventInput.posterAspectRatio),
    broadcastInfo: firstString(
      eventInput.broadcastInfo,
      eventStreamProviders[0],
    ),
    streamUrl: firstString(eventInput.streamUrl),
    replayUrl: firstString(eventInput.replayUrl),
    ticketUrl: firstString(eventInput.ticketUrl, eventInput.ticketsUrl),
    ticketsUrl: firstString(eventInput.ticketUrl, eventInput.ticketsUrl),
    isFeatured: eventInput.isFeatured !== false,
    isPublic: eventInput.isPublic !== false,
    isPPV: ppvInput.disabled !== true,
    latitude,
    longitude,
    lat: latitude,
    lng: longitude,
    source: firstString(eventInput.source) || "manual_real_seed",
    imageIds: Array.isArray(eventInput.imageIds) ? eventInput.imageIds : [],
    mediaIds: Array.isArray(eventInput.mediaIds) ? eventInput.mediaIds : [],
    posterMediaId: firstString(eventInput.posterMediaId),
    sponsors: resolveSponsors(eventInput.sponsors, ppvInput.sponsors),
    streamProviders: eventStreamProviders,
    fightIds: Array.isArray(eventInput.fightIds) ? eventInput.fightIds : [],
    seededAt: admin.firestore.FieldValue.serverTimestamp(),
    seededBy: "scripts/seed_real_event_bundle.cjs",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function buildPpvDoc(context) {
  if (!context.ppvEnabled) {
    return null;
  }

  const {
    eventInput,
    ppvInput,
    promoterInput,
    eventId,
    promoterId,
    eventTitle,
    eventDate,
    eventStreamProviders,
  } = context;
  const ppvDate =
    parseDate(
      ppvInput.eventDate ||
        ppvInput.startTime ||
        eventInput.eventDate ||
        eventInput.startTime,
      "ppv.eventDate",
    ) || eventDate;
  const fightCard = buildFightCard(
    ppvInput.fightCard ||
      ppvInput.mainCard ||
      eventInput.fightCard ||
      eventInput.mainCard ||
      [],
    eventId,
  );
  const posterUrl = firstString(
    ppvInput.posterUrl,
    eventInput.posterUrl,
    eventInput.bannerUrl,
    eventInput.thumbnailUrl,
  );
  const isFinalPoster = ppvInput.isFinalPoster === true || Boolean(posterUrl);
  const streamPlatforms = getStringArray(ppvInput.streamPlatforms);

  return {
    id: firstString(ppvInput.id) || eventId,
    data: compactObject({
      eventId,
      promoterId,
      title: firstString(ppvInput.title) || eventTitle,
      subtitle: firstString(ppvInput.subtitle, eventInput.subtitle),
      description: firstString(ppvInput.description, eventInput.description),
      posterUrl,
      isFinalPoster,
      posterAssetKind:
        firstString(ppvInput.posterAssetKind) ||
        (posterUrl ? "finalPoster" : "generatedFallback"),
      trailerUrl: firstString(ppvInput.trailerUrl),
      sport:
        firstString(ppvInput.sport, eventInput.sportType) || "Combat Sports",
      promotion: firstString(
        ppvInput.promotion,
        eventInput.promotionName,
        promoterInput?.name,
      ),
      eventDate: admin.firestore.Timestamp.fromDate(ppvDate),
      endTime: timestampOrUndefined(
        ppvInput.endTime || eventInput.endTime,
        "ppv.endTime",
      ),
      presaleStart: timestampOrUndefined(
        ppvInput.presaleStart,
        "ppv.presaleStart",
      ),
      onSaleStart: timestampOrUndefined(
        ppvInput.onSaleStart,
        "ppv.onSaleStart",
      ),
      replayExpiry: timestampOrUndefined(
        ppvInput.replayExpiry,
        "ppv.replayExpiry",
      ),
      status: normalizePpvStatus(ppvInput.status || eventInput.status),
      standardPriceCents: resolveStandardPriceCents(ppvInput, eventInput),
      earlyBirdPriceCents: optionalNumber(ppvInput.earlyBirdPriceCents),
      premiumPriceCents: optionalNumber(ppvInput.premiumPriceCents),
      vipPriceCents: optionalNumber(ppvInput.vipPriceCents),
      currency: firstString(ppvInput.currency) || "AUD",
      streamUrl: firstString(ppvInput.streamUrl, eventInput.streamUrl),
      replayUrl: firstString(ppvInput.replayUrl, eventInput.replayUrl),
      replayAvailable: ppvInput.replayAvailable === true,
      streamPlatforms:
        streamPlatforms.length > 0 ? streamPlatforms : eventStreamProviders,
      purchaseCount: optionalNumber(ppvInput.purchaseCount) || 0,
      peakViewers: optionalNumber(ppvInput.peakViewers) || 0,
      totalRevenueCents: optionalNumber(ppvInput.totalRevenueCents) || 0,
      fightCard,
      ticketUrl: firstString(
        ppvInput.ticketUrl,
        eventInput.ticketUrl,
        eventInput.ticketsUrl,
      ),
      platformFeePct: optionalNumber(ppvInput.platformFeePct) || 0.3,
      chatEnabled: ppvInput.chatEnabled !== false,
      multiCamEnabled: ppvInput.multiCamEnabled === true,
      predictionsEnabled: ppvInput.predictionsEnabled !== false,
      sponsors: resolveSponsors(ppvInput.sponsors, eventInput.sponsors),
      seededAt: admin.firestore.FieldValue.serverTimestamp(),
      seededBy: "scripts/seed_real_event_bundle.cjs",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }),
  };
}

function buildPromoterDoc(promoterInput, promoterId) {
  if (!promoterInput) {
    return null;
  }

  return {
    id: requireString(promoterInput.id || promoterId, "promoter.id"),
    data: compactObject({
      name: requireString(promoterInput.name, "promoter.name"),
      displayName: firstString(promoterInput.displayName, promoterInput.name),
      logoUrl: firstString(promoterInput.logoUrl),
      bannerUrl: firstString(promoterInput.bannerUrl),
      photoUrl: firstString(promoterInput.logoUrl),
      coverPhotoUrl: firstString(promoterInput.bannerUrl),
      city: firstString(promoterInput.city),
      state: firstString(promoterInput.state),
      country: firstString(promoterInput.country),
      location: firstString(
        [promoterInput.city, promoterInput.state, promoterInput.country]
          .filter(Boolean)
          .join(", "),
      ),
      websiteUrl: firstString(promoterInput.websiteUrl),
      instagramUrl: firstString(promoterInput.instagramUrl),
      facebookUrl: firstString(promoterInput.facebookUrl),
      seededAt: admin.firestore.FieldValue.serverTimestamp(),
      seededBy: "scripts/seed_real_event_bundle.cjs",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }),
  };
}

function buildFighterDocs(fightersInput, eventId, defaultSportType) {
  return fightersInput.map((fighter, index) => {
    const fighterId = requireString(
      fighter.id || fighter.userId || `fighter_${index + 1}`,
      `fighters[${index}].id`,
    );
    const fullName = requireString(
      fighter.fullName || fighter.name,
      `fighters[${index}].fullName or fighters[${index}].name`,
    );
    const record = parseRecord(fighter.record);

    return {
      id: fighterId,
      data: compactObject({
        userId: firstString(fighter.userId) || fighterId,
        fullName,
        name: fullName,
        nickname: firstString(fighter.nickname),
        nationality: firstString(fighter.nationality, fighter.country),
        gender: firstString(fighter.gender) || "undisclosed",
        weightClass: firstString(fighter.weightClass),
        sportType: firstString(fighter.sportType, defaultSportType),
        status: firstString(fighter.status) || "active",
        wins: record.wins,
        losses: record.losses,
        draws: record.draws,
        noContests: record.noContests,
        photoUrl: firstString(fighter.photoUrl, fighter.portraitUrl),
        portraitUrl: firstString(fighter.portraitUrl, fighter.photoUrl),
        coverPhotoUrl: firstString(fighter.coverPhotoUrl),
        city: firstString(fighter.city),
        state: firstString(fighter.state),
        country: firstString(fighter.country),
        latitude: optionalNumber(fighter.latitude ?? fighter.lat),
        longitude: optionalNumber(fighter.longitude ?? fighter.lng),
        upcomingEventId: firstString(fighter.upcomingEventId) || eventId,
        qnaEnabled: fighter.qnaEnabled !== false,
        commentsEnabled: fighter.commentsEnabled !== false,
        matchupAvailability:
          firstString(fighter.matchupAvailability) || "available",
        preferredWeightClasses: getStringArray(fighter.preferredWeightClasses),
        preferredOpponentStyles: getStringArray(
          fighter.preferredOpponentStyles,
        ),
        blockedFighterIds: getStringArray(fighter.blockedFighterIds),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        seededAt: admin.firestore.FieldValue.serverTimestamp(),
        seededBy: "scripts/seed_real_event_bundle.cjs",
      }),
    };
  });
}

function buildBundle(payload) {
  const context = buildContext(payload);

  return {
    event: {
      id: context.eventId,
      data: buildEventDoc(context),
    },
    ppv: buildPpvDoc(context),
    promoter: buildPromoterDoc(context.promoterInput, context.promoterId),
    fighters: buildFighterDocs(
      context.fightersInput,
      context.eventId,
      context.eventInput.sportType || "Combat Sports",
    ),
  };
}

function entryPath(entry, bundle) {
  if (entry === bundle.event) {
    return `events/${entry.id}`;
  }
  if (entry === bundle.ppv) {
    return `ppv_events/${entry.id}`;
  }
  if (entry === bundle.promoter) {
    return `promoters/${entry.id}`;
  }
  return `fighters/${entry.id}`;
}

function summarizeBundle(bundle) {
  const writes = [
    bundle.event,
    bundle.ppv,
    bundle.promoter,
    ...bundle.fighters,
  ].filter(Boolean);

  return writes.map((entry) => ({
    path: entryPath(entry, bundle),
    fields: Object.keys(entry.data).sort((left, right) =>
      left.localeCompare(right),
    ),
  }));
}

async function writeBundle(bundle) {
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const db = admin.firestore();
  const batch = db.batch();

  batch.set(db.collection("events").doc(bundle.event.id), bundle.event.data, {
    merge: true,
  });
  if (bundle.ppv) {
    batch.set(db.collection("ppv_events").doc(bundle.ppv.id), bundle.ppv.data, {
      merge: true,
    });
  }
  if (bundle.promoter) {
    batch.set(
      db.collection("promoters").doc(bundle.promoter.id),
      bundle.promoter.data,
      { merge: true },
    );
  }
  for (const fighter of bundle.fighters) {
    batch.set(db.collection("fighters").doc(fighter.id), fighter.data, {
      merge: true,
    });
  }

  await batch.commit();
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const { absolutePath, payload } = loadPayload(args.file);
  const bundle = buildBundle(payload);
  const summary = summarizeBundle(bundle);

  if (args.dryRun) {
    console.log(`Dry run for payload: ${absolutePath}`);
    console.log(JSON.stringify(summary, null, 2));
    return;
  }

  await writeBundle(bundle);
  console.log(`Seeded bundle from ${absolutePath}`);
  for (const item of summary) {
    console.log(`  ✓ ${item.path}`);
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
