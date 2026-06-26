const fetch = require("node-fetch");
const Bottleneck = require("bottleneck");
const limiter = new Bottleneck({ maxConcurrent: 2, minTime: 600 });

async function postToInstagram(igUserId, accessToken, mediaPayload) {
  const res = await fetch(
    `https://graph.facebook.com/v18.0/${igUserId}/media`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(mediaPayload),
    },
  );
  return res.json();
}

async function publishCreation(igUserId, accessToken, creationId) {
  const res = await fetch(
    `https://graph.facebook.com/v18.0/${igUserId}/media_publish`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({ creation_id: creationId }),
    },
  );
  return res.json();
}

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || "{}");
    const { igUserId, accessToken, videoUrl, caption } = body;
    if (!igUserId || !accessToken || !videoUrl)
      return { statusCode: 400, body: "missing" };

    const mediaPayload = { media_type: "REELS", video_url: videoUrl, caption };
    const create = await limiter.schedule(() =>
      postToInstagram(igUserId, accessToken, mediaPayload),
    );
    if (!create || !create.id) throw new Error("create_failed");

    let publish;
    for (let i = 0; i < 3; i++) {
      publish = await limiter.schedule(() =>
        publishCreation(igUserId, accessToken, create.id),
      );
      if (publish && publish.id) break;
      await new Promise((r) => setTimeout(r, 1000 * (i + 1)));
    }
    if (!publish || !publish.id) throw new Error("publish_failed");

    return {
      statusCode: 200,
      body: JSON.stringify({ id: publish.id, creation: create }),
    };
  } catch (err) {
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};
