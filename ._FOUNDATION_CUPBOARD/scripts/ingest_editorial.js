const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

// ⭐ Point to the local emulator by default for dev workflows
// Comment this out and provide a service account key to deploy to production
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

// Initialize Firebase Admin
admin.initializeApp({ projectId: 'dfc-local-dev' });
const db = admin.firestore();

const CONTENT_DIR = path.join(__dirname, '../content');

async function ingestDirectory(dirPath) {
  if (!fs.existsSync(dirPath)) {
    console.log(`[!] Directory not found: ${dirPath}`);
    return;
  }

  const items = fs.readdirSync(dirPath);

  for (const item of items) {
    const fullPath = path.join(dirPath, item);
    const stat = fs.statSync(fullPath);

    if (stat.isDirectory()) {
      // Recursively search subdirectories (events, fighters, gyms, etc.)
      await ingestDirectory(fullPath);
    } else if (item.endsWith('.md')) {
      // Slug is the filename without .md (e.g., event_123_preview)
      const slug = item.replace('.md', '');
      const body = fs.readFileSync(fullPath, 'utf8');

      console.log(`[+] Ingesting article: ${slug}...`);

      await db.collection('editorial').doc(slug).set({
        body: body,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }
}

async function main() {
  console.log('--- DFC EDITORIAL INGESTION ENGINE ---');
  await ingestDirectory(CONTENT_DIR);
  console.log('--- INGESTION COMPLETE ---');
  process.exit(0);
}

main().catch(console.error);
