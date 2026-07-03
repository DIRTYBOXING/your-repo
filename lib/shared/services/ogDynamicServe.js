=========================================
 * DFC DYNAMIC OPEN GRAPH (OG) TAG SERVER
 *
 * This Cloud Function is triggered by Firebase Hosting rewrites for paths like
 * /events/:id, /fighters/:id, and /posts/:id.
 *
 * When a social media crawler (bot) requests one of these URLs, this function:
 * 1. Parses the URL to determine the content type and ID.
 * 2. Fetches the corresponding document from Firestore.
 * 3. Dynamically generates an HTML page with Open Graph (OG) meta tags
 *    (og:title, og:description, og:image) based on the Firestore data.
 * 4. Serves this HTML to the bot, ensuring a rich preview when shared.
 *
 * For regular users, it serves the standard index.html, allowing the
 * Flutter web app to handle client-side routing.
 * ==============================================================================
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

// Initialize Firebase Admin SDK if not already done
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Fetches data for a given entity from Firestore.
 * @param {string} collection The Firestore collection name.
 * @param {string} docId The document ID.
 * @returns {Promise<Object|null>} The document data or null if not found.
 */
async function getEntityData(collection, docId) {
  try {
    const doc = await db.collection(collection).doc(docId).get();
    if (!doc.exists) {
      console.warn(`Document not found: ${collection}/${docId}`);
      return null;
    }
    return doc.data();
  } catch (error) {
    console.error(`Error fetching from ${collection}/${docId}:`, error);
    return null;
  }
}

/**
 * Generates the HTML response with dynamic OG tags.
 * @param {string} originalHtml The original index.html content.
 * @param {Object} ogData The data for OG tags.
 * @returns {string} The modified HTML with OG tags.
 */
function generateHtmlWithOgTags(originalHtml, ogData) {
  const { title, description, image, url } = ogData;

  const ogTags = `
    <meta property="og:title" content="${title}" />
    <meta property="og:description" content="${description}" />
    <meta property="og:image" content="${image}" />
    <meta property="og:url" content="${url}" />
    <meta property="og:type" content="website" />
    <meta name="twitter:card" content="summary_large_image" />
  `;

  // Inject the OG tags into the <head> of the original HTML
  return originalHtml.replace("</head>", `${ogTags}</head>`);
}

exports.ogDynamicServe = functions.https.onRequest(async (req, res) => {
  const userAgent = req.headers["user-agent"] || "";
  // A list of common social media and search engine crawler user agents
  const isBot = /bot|facebook|embedly|pinterest|slack|twitter|whatsapp|google|yahoo|bing|duckduckgo|teoma|yandex/i.test(userAgent);

  // Read the main index.html file from the public hosting directory.
  // Note: The path might need adjustment based on your final build structure.
  const indexPath = path.resolve(__dirname, "../build/web/index.html");
  const indexHtml = fs.readFileSync(indexPath, "utf8");

  if (!isBot) {
    // If it's a regular user, serve the standard Flutter app.
    // The client-side router will handle the path.
    res.status(200).send(indexHtml);
    return;
  }

  // It's a bot, so we need to generate dynamic OG tags.
  const pathParts = req.path.split("/").filter((p) => p); // e.g., ['events', 'evt_001']
  if (pathParts.length < 2) {
    res.status(200).send(indexHtml); // Not a content path, serve default
    return;
  }

  const [entityType, entityId] = pathParts;
  let collectionName = "";
  let data = null;

  // Determine the collection based on the URL path
  switch (entityType) {
    case "events":
      collectionName = "ppvEvents"; // As per firestore.rules
      data = await getEntityData(collectionName, entityId);
      break;
    case "fighters":
      collectionName = "users"; // Fighters are stored in the 'users' collection
      data = await getEntityData(collectionName, entityId);
      break;
    case "posts":
      collectionName = "posts"; // Assuming a 'posts' collection
      data = await getEntityData(collectionName, entityId);
      break;
    default:
      res.status(200).send(indexHtml);
      return;
  }

  if (!data) {
    res.status(404).send(indexHtml); // Content not found, but still serve the app
    return;
  }

  // Construct the OG data from the fetched document
  const ogData = {
    title: data.name || data.displayName || "Data Fight Central",
    description: data.bio || data.description || "The operating system for combat sports.",
    image: data.poster_url || data.photoUrl || "https://datafightcentral.com/default-share-image.png", // Fallback image
    url: `https://datafightcentral.com${req.path}`,
  };

  // Generate and serve the final HTML
  const finalHtml = generateHtmlWithOgTags(indexHtml, ogData);
  res.status(200).send(finalHtml);
});
