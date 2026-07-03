// ═══════════════════════════════════════════════════════════════════════════
// STREAM SIMULATION TEST — Verify glass-to-glass latency pipeline
// ═══════════════════════════════════════════════════════════════════════════
//
// Creates a TEST Mux live stream, returns OBS connection details,
// and provides a latency measurement endpoint.
//
// Usage:
//   1. Call `simulateStream` → get RTMP URL + stream key
//   2. Push OBS to that RTMP URL with a timer video
//   3. Call `measureLatency` with the stream doc ID → get health stats
//   4. Call `teardownSimulation` to clean up the test stream
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

// ═══════════════════════════════════════════════════════════════════════════
// SIMULATE STREAM — Create a TEST Mux live stream
// ═══════════════════════════════════════════════════════════════════════════
const simulateStream = onCall({ region: REGION }, async (request) => {
  const { title, latencyMode } = request.data;

  // Try to use Mux
  let muxClient = null;
  try {
    const Mux = require("@mux/mux-node");
    const tokenId = process.env.MUX_TOKEN_ID;
    const tokenSecret = process.env.MUX_TOKEN_SECRET;
    if (tokenId && tokenSecret) {
      muxClient = new Mux({ tokenId, tokenSecret });
    }
  } catch (e) {
    // Mux not available
  }

  const testTitle = title || `DFC Latency Test — ${new Date().toISOString()}`;
  const mode = latencyMode || "low";

  if (muxClient) {
    // ── Real Mux test stream ──
    try {
      const liveStream = await muxClient.video.liveStreams.create({
        playback_policy: ["public"],
        new_asset_settings: { playback_policy: ["public"] },
        latency_mode: mode,
        reconnect_window: 30,
        max_continuous_duration: 3600, // 1 hour max for test
        test: true, // TEST MODE — no billing
      });

      const streamKey = liveStream.stream_key;
      const playbackId = liveStream.playback_ids?.[0]?.id;
      const muxStreamId = liveStream.id;

      // Persist for tracking
      const docRef = db.collection("stream_simulations").doc();
      await docRef.set({
        muxStreamId,
        muxPlaybackId: playbackId,
        streamKey,
        title: testTitle,
        latencyMode: mode,
        status: "idle",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: request.auth?.uid || "system",
      });

      return {
        success: true,
        simulationId: docRef.id,
        muxStreamId,
        obsConfig: {
          server: "rtmp://global-live.mux.com:5222/app",
          streamKey,
          srtUrl: `srt://global-live.mux.com:5222?streamid=${streamKey}`,
        },
        playback: {
          hlsUrl: `https://stream.mux.com/${playbackId}.m3u8`,
          playbackId,
        },
        latencyMode: mode,
        isTest: true,
        instructions: [
          "1. Open OBS Studio → Settings → Stream",
          '2. Set Service to "Custom"',
          `3. Server: rtmp://global-live.mux.com:5222/app`,
          `4. Stream Key: ${streamKey}`,
          '5. Settings → Output → set Tune to "zerolatency"',
          "6. Settings → Output → set Bitrate to 4000 kbps",
          "7. Play a stopwatch/timer video as source",
          '8. Click "Start Streaming"',
          `9. Open HLS URL in app: https://stream.mux.com/${playbackId}.m3u8`,
          "10. Compare timestamps — goal: < 3 second difference",
        ],
      };
    } catch (e) {
      return {
        error: `Mux stream creation failed: ${e.message}`,
        muxAvailable: true,
      };
    }
  }

  // ── No Mux keys — return setup instructions ──
  return {
    success: false,
    muxAvailable: false,
    message:
      "Mux API keys not configured. Set MUX_TOKEN_ID and MUX_TOKEN_SECRET first.",
    steps: [
      "1. Sign up at https://mux.com (free tier available)",
      "2. Create an API Access Token in Mux Dashboard → Settings → API Access Tokens",
      "3. Run: firebase functions:secrets:set MUX_TOKEN_ID",
      "4. Run: firebase functions:secrets:set MUX_TOKEN_SECRET",
      "5. (Optional) For signed playback: firebase functions:secrets:set MUX_SIGNING_KEY_ID",
      "6. (Optional) firebase functions:secrets:set MUX_SIGNING_PRIVATE_KEY",
      "7. Deploy: firebase deploy --only functions",
      "8. Re-run this simulation",
    ],
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// MEASURE LATENCY — Check stream health & latency stats
// ═══════════════════════════════════════════════════════════════════════════
const measureLatency = onCall({ region: REGION }, async (request) => {
  const { simulationId } = request.data;
  if (!simulationId) return { error: "simulationId required" };

  const doc = await db.collection("stream_simulations").doc(simulationId).get();
  if (!doc.exists) return { error: "Simulation not found" };

  const sim = doc.data();

  let muxClient = null;
  try {
    const Mux = require("@mux/mux-node");
    const tokenId = process.env.MUX_TOKEN_ID;
    const tokenSecret = process.env.MUX_TOKEN_SECRET;
    if (tokenId && tokenSecret) {
      muxClient = new Mux({ tokenId, tokenSecret });
    }
  } catch (e) {
    // Mux not available
  }

  if (!muxClient) return { error: "Mux not configured" };

  try {
    const muxStream = await muxClient.video.liveStreams.retrieve(
      sim.muxStreamId,
    );

    const status = muxStream.status;
    const isActive = status === "active";

    // Update local status
    if (status !== sim.status) {
      await doc.ref.update({
        status,
        ...(isActive
          ? { wentLiveAt: admin.firestore.FieldValue.serverTimestamp() }
          : {}),
      });
    }

    return {
      streamStatus: status,
      isLive: isActive,
      latencyMode: muxStream.latency_mode || sim.latencyMode,
      reconnectWindow: muxStream.reconnect_window,
      activeAssetId: muxStream.active_asset_id || null,
      hlsUrl: `https://stream.mux.com/${sim.muxPlaybackId}.m3u8`,
      health: {
        expectedLatency:
          muxStream.latency_mode === "low" ? "2-4 seconds" : "6-10 seconds",
        recommendation: isActive
          ? "Stream is LIVE. Compare OBS timer to app timer for latency measurement."
          : `Stream status: ${status}. Start streaming from OBS first.`,
      },
    };
  } catch (e) {
    return { error: `Failed to check stream: ${e.message}` };
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// TEARDOWN SIMULATION — Clean up test stream
// ═══════════════════════════════════════════════════════════════════════════
const teardownSimulation = onCall({ region: REGION }, async (request) => {
  const { simulationId } = request.data;
  if (!simulationId) return { error: "simulationId required" };

  const doc = await db.collection("stream_simulations").doc(simulationId).get();
  if (!doc.exists) return { error: "Simulation not found" };

  const sim = doc.data();

  let muxClient = null;
  try {
    const Mux = require("@mux/mux-node");
    const tokenId = process.env.MUX_TOKEN_ID;
    const tokenSecret = process.env.MUX_TOKEN_SECRET;
    if (tokenId && tokenSecret) {
      muxClient = new Mux({ tokenId, tokenSecret });
    }
  } catch (e) {
    // Mux not available
  }

  if (muxClient && sim.muxStreamId) {
    try {
      await muxClient.video.liveStreams.delete(sim.muxStreamId);
    } catch (e) {
      console.warn("Failed to delete Mux stream:", e.message);
    }
  }

  await doc.ref.update({
    status: "torn_down",
    tornDownAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, message: "Test stream cleaned up" };
});

module.exports = {
  simulateStream,
  measureLatency,
  teardownSimulation,
};
