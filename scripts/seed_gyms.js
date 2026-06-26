/**
 * seed_gyms.js — Seed Firestore `gyms` collection
 *
 * Writes gym documents in the exact shape expected by:
 *   - gym_map_command_screen.dart (_gymFromFirestore)
 *   - earth_map_view.dart (_fetchPinkShieldGyms)
 *
 * Run:
 *   node scripts/seed_gyms.js
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS env var pointing to service account JSON,
 * OR place the service account JSON at the project root as serviceAccount.json
 */

const path = require("path");
let admin;
try {
  admin = require("firebase-admin");
} catch {
  console.error("firebase-admin not found. Run: npm install firebase-admin");
  process.exit(1);
}

// ── Credential resolution ──────────────────────────────────────────────────
function loadCredential() {
  const envPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (envPath) return admin.credential.applicationDefault();

  const localPath = path.join(__dirname, "..", "serviceAccount.json");
  try {
    const sa = require(localPath);
    return admin.credential.cert(sa);
  } catch {
    // try Downloads fallback
    const downloadsPath = path.join(
      process.env.USERPROFILE || process.env.HOME || ".",
      "Downloads",
      "datafightcentral-firebase-adminsdk-fbsvc-069d63986f.json",
    );
    try {
      const sa = require(downloadsPath);
      return admin.credential.cert(sa);
    } catch {
      console.error(
        "No service account found.\n" +
          "Set GOOGLE_APPLICATION_CREDENTIALS or place serviceAccount.json at project root.",
      );
      process.exit(1);
    }
  }
}

if (!admin.apps.length) {
  admin.initializeApp({ credential: loadCredential() });
}

const db = admin.firestore();

// ── Gym data ───────────────────────────────────────────────────────────────
// Required fields:
//   name, location, latitude, longitude, status ('active')
//   tier ('pink_shield' | 'elite' | 'pro' | 'standard')
//   pinkShieldStatus (non-empty string = certified)
//   disciplines, rating, fighters, coaches, verified, hasLiveEvent

const GYMS = [
  // ── Pink Shield certified ─────────────────────────────────────────────
  {
    id: "gym-pink-shield-melbourne",
    name: "Pinnacle Fight Academy",
    location: "Melbourne, VIC",
    latitude: -37.814,
    longitude: 144.963,
    status: "active",
    tier: "pink_shield",
    pinkShieldStatus: "certified",
    disciplines: "Boxing · Muay Thai · BJJ · Self-Defence",
    rating: 4.9,
    fighters: 28,
    coaches: 6,
    verified: true,
    hasLiveEvent: false,
  },
  {
    id: "gym-pink-shield-sydney",
    name: "Vanguard Combat Sports",
    location: "Sydney, NSW",
    latitude: -33.868,
    longitude: 151.209,
    status: "active",
    tier: "pink_shield",
    pinkShieldStatus: "certified",
    disciplines: "MMA · Boxing · Kickboxing · Women's Classes",
    rating: 4.8,
    fighters: 34,
    coaches: 7,
    verified: true,
    hasLiveEvent: false,
  },
  {
    id: "gym-pink-shield-brisbane",
    name: "Apex Martial Arts Centre",
    location: "Brisbane, QLD",
    latitude: -27.47,
    longitude: 153.021,
    status: "active",
    tier: "pink_shield",
    pinkShieldStatus: "certified",
    disciplines: "Muay Thai · BJJ · Women's Safety",
    rating: 4.7,
    fighters: 19,
    coaches: 5,
    verified: true,
    hasLiveEvent: false,
  },

  // ── Elite gyms ────────────────────────────────────────────────────────
  {
    id: "gym-elite-perth",
    name: "Pacific Combat Academy",
    location: "Perth, WA",
    latitude: -31.953,
    longitude: 115.857,
    status: "active",
    tier: "elite",
    pinkShieldStatus: "",
    disciplines: "MMA · Wrestling · Boxing",
    rating: 4.8,
    fighters: 42,
    coaches: 9,
    verified: true,
    hasLiveEvent: true,
  },
  {
    id: "gym-elite-adelaide",
    name: "Ironclad MMA",
    location: "Adelaide, SA",
    latitude: -34.928,
    longitude: 138.6,
    status: "active",
    tier: "elite",
    pinkShieldStatus: "",
    disciplines: "MMA · Kickboxing · Wrestling",
    rating: 4.7,
    fighters: 31,
    coaches: 6,
    verified: true,
    hasLiveEvent: false,
  },
  {
    id: "gym-elite-auckland",
    name: "Southpaw Gym Auckland",
    location: "Auckland, NZ",
    latitude: -36.848,
    longitude: 174.763,
    status: "active",
    tier: "elite",
    pinkShieldStatus: "",
    disciplines: "Boxing · MMA · Strength",
    rating: 4.6,
    fighters: 25,
    coaches: 5,
    verified: true,
    hasLiveEvent: false,
  },

  // ── Pro gyms ─────────────────────────────────────────────────────────
  {
    id: "gym-pro-gold-coast",
    name: "Coral Coast Combat",
    location: "Gold Coast, QLD",
    latitude: -28.0167,
    longitude: 153.4,
    status: "active",
    tier: "pro",
    pinkShieldStatus: "",
    disciplines: "Muay Thai · BJJ · Boxing",
    rating: 4.4,
    fighters: 16,
    coaches: 4,
    verified: true,
    hasLiveEvent: false,
  },
  {
    id: "gym-pro-canberra",
    name: "Capitol City MMA",
    location: "Canberra, ACT",
    latitude: -35.28,
    longitude: 149.13,
    status: "active",
    tier: "pro",
    pinkShieldStatus: "",
    disciplines: "MMA · Kickboxing · BJJ",
    rating: 4.3,
    fighters: 12,
    coaches: 3,
    verified: false,
    hasLiveEvent: false,
  },
  {
    id: "gym-pro-townsville",
    name: "NQ Fight Factory",
    location: "Townsville, QLD",
    latitude: -19.258,
    longitude: 146.817,
    status: "active",
    tier: "pro",
    pinkShieldStatus: "",
    disciplines: "Boxing · BKFC · Muay Thai",
    rating: 4.5,
    fighters: 20,
    coaches: 4,
    verified: true,
    hasLiveEvent: true,
  },

  // ── Standard gyms ─────────────────────────────────────────────────────
  {
    id: "gym-std-hobart",
    name: "Southern Cross Martial Arts",
    location: "Hobart, TAS",
    latitude: -42.881,
    longitude: 147.324,
    status: "active",
    tier: "standard",
    pinkShieldStatus: "",
    disciplines: "Kickboxing · BJJ",
    rating: 4.0,
    fighters: 8,
    coaches: 2,
    verified: false,
    hasLiveEvent: false,
  },
  {
    id: "gym-std-darwin",
    name: "Top End Fight Club",
    location: "Darwin, NT",
    latitude: -12.462,
    longitude: 130.841,
    status: "active",
    tier: "standard",
    pinkShieldStatus: "",
    disciplines: "MMA · Boxing",
    rating: 4.1,
    fighters: 10,
    coaches: 2,
    verified: false,
    hasLiveEvent: false,
  },
];

// ── Seed ──────────────────────────────────────────────────────────────────
async function seedGyms() {
  console.log(`Seeding ${GYMS.length} gyms into Firestore...`);
  const batch = db.batch();

  for (const gym of GYMS) {
    const { id, ...data } = gym;
    const ref = db.collection("gyms").doc(id);
    batch.set(
      ref,
      {
        ...data,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    console.log(`  queued: gyms/${id} [${gym.tier}]`);
  }

  await batch.commit();
  console.log(`\n✓ ${GYMS.length} gym documents written to Firestore`);
  console.log("\nPink Shield gyms seeded:");
  GYMS.filter((g) => g.pinkShieldStatus === "certified").forEach((g) => {
    console.log(`  • ${g.name} (${g.location})`);
  });
}

seedGyms()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Seed failed:", err);
    process.exit(1);
  });
