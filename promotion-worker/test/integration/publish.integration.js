// promotion-worker/test/integration/publish.integration.js
const assert = require('assert');
const fetch = require('node-fetch');

const PROJECT = process.env.GOOGLE_CLOUD_PROJECT || 'datafightcentral';
const PAGE_ID = process.env.TEST_FACEBOOK_PAGE_ID;
const PAGE_TOKEN = process.env.TEST_FACEBOOK_PAGE_TOKEN;

if (!PAGE_ID || !PAGE_TOKEN) {
  console.error('Set TEST_FACEBOOK_PAGE_ID and TEST_FACEBOOK_PAGE_TOKEN for integration test.');
  process.exit(0); // skip if not configured
}

async function postToPage(message) {
  const url = `https://graph.facebook.com/v19.0/${PAGE_ID}/feed`;
  const res = await fetch(url, {
    method: 'POST',
    body: new URLSearchParams({ message, access_token: PAGE_TOKEN }),
  });
  return res.json();
}

async function deletePost(postId) {
  const url = `https://graph.facebook.com/v19.0/${postId}`;
  const res = await fetch(url, {
    method: 'DELETE',
    body: new URLSearchParams({ access_token: PAGE_TOKEN }),
  });
  return res.json();
}

(async () => {
  try {
    const message = `DFC integration test ${Date.now()}`;
    const create = await postToPage(message);
    assert(create && create.id, 'Post creation failed');
    console.log('Created post id:', create.id);

    // cleanup
    const del = await deletePost(create.id);
    console.log('Delete response:', del);
    process.exit(0);
  } catch (err) {
    console.error('Integration test failed:', err);
    process.exit(1);
  }
})();
