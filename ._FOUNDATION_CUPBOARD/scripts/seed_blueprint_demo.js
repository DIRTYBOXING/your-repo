import admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const promoterId = "demo_promoter_blueprint";
const eventId = "demo_event_blueprint";
const posterId = "demo_poster_blueprint";

await db.collection("promoters").doc(promoterId).set(
  {
    name: "DFC Blueprint Promoter",
    slug: "dfc-blueprint-promoter",
    city: "Logan",
    region: "QLD",
    mission: "Promoter-first and community-first event growth",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  { merge: true },
);

await db.collection("events").doc(eventId).set(
  {
    title: "DFC Blueprint Showcase",
    promoterId,
    status: "upcoming",
    city: "Woodridge",
    venue: "DFC Community Hub",
    posterUrl: "/assets/nav_card_blueprint.svg",
    startsAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    ),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  { merge: true },
);

await db.collection("posters").doc(posterId).set(
  {
    eventId,
    promoterId,
    title: "Blueprint Promo Card",
    imageUrl: "/assets/nav_card_blueprint.svg",
    type: "blueprint-demo",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  { merge: true },
);

console.log("Seeded blueprint demo docs:", { promoterId, eventId, posterId });
