#!/usr/bin/env node
// scripts/test_publish_fb.esm.js
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

const DRY_RUN = process.env.DRY_RUN === '1' || process.env.DRY_RUN === 'true';
const PROJECT = process.env.GOOGLE_CLOUD_PROJECT || process.env.PROJECT_ID || 'datafightcentral';

async function getSecret(name) {
  const client = new SecretManagerServiceClient();
  const [version] = await client.accessSecretVersion({
    name: `projects/${PROJECT}/secrets/${name}/versions/latest`,
  });
  const payload = version.payload.data.toString('utf8');
  return payload;
}

async function main() {
  console.log('Starting staging harness (ESM) - DRY_RUN=', DRY_RUN ? 'true' : 'false');
  try {
    const pageId = await getSecret('facebook_page_id');
    const token = await getSecret('facebook_page_token');
    console.log('Secrets loaded: facebook_page_id=', pageId ? `***${pageId.slice(-4)}` : 'MISSING');
    console.log('Token masked: token=***' + (token ? token.slice(-4) : 'MISSING'));

    if (DRY_RUN) {
      console.log('DRY_RUN set - exiting after secret validation.');
      process.exit(0);
    }

    // dynamic import of promotion-worker dist entry
    const mod = await import('../promotion-worker/dist/index.js');
    if (!mod.publishToFacebook) {
      console.error('publishToFacebook not exported from promotion-worker/dist/index.js');
      process.exit(2);
    }

    // Example safe test post (ensure this is a test Page)
    const result = await mod.publishToFacebook({
      text: 'DFC staging test post (automated)',
      imageUrl: null,
      pageId,
    });
    console.log('publish result:', result);
    process.exit(0);
  } catch (err) {
    console.error('Staging harness error:', err);
    process.exit(1);
  }
}

main();
