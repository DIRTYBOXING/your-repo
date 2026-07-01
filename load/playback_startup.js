/**
 * DFC k6 Load Test — DRM Playback Startup + Manifest Fetch
 * Run: k6 run load/playback_startup.js
 */
import http from "k6/http";
import { check, group, sleep } from "k6";
import { Trend, Rate } from "k6/metrics";

const startupTime = new Trend("playback_startup_ms", true);
const bufferRatio = new Rate("buffering_events");
const manifestFetchFailed = new Rate("manifest_fetch_failed");
const drmIssueFailed = new Rate("drm_issue_failed");

export const options = {
  scenarios: {
    live_event_viewers: {
      executor: "ramping-arrival-rate",
      startRate: 10,
      timeUnit: "1s",
      preAllocatedVUs: 200,
      maxVUs: 500,
      stages: [
        { duration: "20s", target: 50 },
        { duration: "30s", target: 200 },
        { duration: "20s", target: 200 },
        { duration: "20s", target: 50 },
        { duration: "10s", target: 0 },
      ],
    },
  },
  thresholds: {
    playback_startup_ms: ["p(50)<2000", "p(95)<3000"],
    http_req_failed: ["rate<0.01"],
    buffering_events: ["rate<0.02"],
    manifest_fetch_failed: ["rate<0.02"],
    drm_issue_failed: ["rate<0.01"],
  },
};

const FUNCTIONS_BASE_URL =
  __ENV.FUNCTIONS_BASE_URL ||
  "http://127.0.0.1:5001/datafightcentral/australia-southeast1";
const MANIFEST_URL =
  __ENV.MANIFEST_URL ||
  "https://stream.mux.com/placeholder.m3u8";
const EVENT_ID = __ENV.EVENT_ID || "bkfc-newcastle-2026";
const FIREBASE_ID_TOKEN = __ENV.FIREBASE_ID_TOKEN || "";
const params = {
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${FIREBASE_ID_TOKEN}`,
  },
};

export default function playbackStartupScenario() {
  const deviceId = `dev-${__VU}`;

  group("DRM Token → Manifest", () => {
    const tokenRes = http.post(
      `${FUNCTIONS_BASE_URL}/drmTokenApi`,
      JSON.stringify({
        eventId: EVENT_ID,
        device: deviceId,
        scope: "playback",
      }),
      params,
    );

    if (tokenRes.status !== 200) {
      drmIssueFailed.add(true);
      bufferRatio.add(true);
      return;
    }
    drmIssueFailed.add(false);

    const token = JSON.parse(tokenRes.body).token;
    const t0 = Date.now();

    const manifestRes = http.get(MANIFEST_URL, {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept:
          "application/x-mpegURL,application/dash+xml,application/vnd.apple.mpegurl,text/plain,*/*",
      },
    });

    const startupMs = Date.now() - t0;
    startupTime.add(startupMs);

    const started = check(manifestRes, {
      "manifest success": (r) => r.status === 200 || r.status === 206,
      "startup < 3s": () => startupMs < 3000,
    });

    manifestFetchFailed.add(!started);
    bufferRatio.add(!started);
  });

  sleep(0.5 + Math.random());
}

export function handleSummary(data) {
  return {
    "load/results/playback_startup_summary.json": JSON.stringify(data, null, 2),
  };
}
