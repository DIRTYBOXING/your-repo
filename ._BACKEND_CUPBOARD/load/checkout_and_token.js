/**
 * DFC k6 Load Test — PPV Store + DRM Token + CDN Token
 * Run: k6 run load/checkout_and_token.js
 * Options: k6 run --vus 100 --duration 2m load/checkout_and_token.js
 */
import http from "k6/http";
import { check, group, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

// Custom metrics
const tokenIssueFailed = new Rate("token_issue_failed");
const cdnTokenFailed = new Rate("cdn_token_failed");
const storeFailed = new Rate("store_request_failed");
const issueDuration = new Trend("token_issue_duration", true);
const cdnDuration = new Trend("cdn_token_duration", true);
const storeDuration = new Trend("store_request_duration", true);

export const options = {
  scenarios: {
    checkout_spike: {
      executor: "ramping-vus",
      startVUs: 5,
      stages: [
        { duration: "15s", target: 25 },
        { duration: "30s", target: 50 },
        { duration: "15s", target: 100 },
        { duration: "30s", target: 100 },
        { duration: "15s", target: 50 },
        { duration: "15s", target: 0 },
      ],
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.02"],
    http_req_duration: ["p(95)<2000", "p(99)<4000"],
    token_issue_duration: ["p(95)<700"],
    cdn_token_duration: ["p(95)<700"],
    store_request_duration: ["p(95)<1200"],
    token_issue_failed: ["rate<0.01"],
    cdn_token_failed: ["rate<0.01"],
    store_request_failed: ["rate<0.02"],
  },
};

const FUNCTIONS_BASE_URL =
  __ENV.FUNCTIONS_BASE_URL ||
  "http://127.0.0.1:5001/datafightcentral/australia-southeast1";
const STOREFRONT_URL = __ENV.STOREFRONT_URL || "http://localhost:7357/#/ppv/store";
const EVENT_ID = __ENV.EVENT_ID || "bkfc-newcastle-2026";
const FIREBASE_ID_TOKEN = __ENV.FIREBASE_ID_TOKEN || "";
const CDN_ASSET_URL =
  __ENV.CDN_ASSET_URL ||
  "https://cdn.datafightcentral.com/posters/bkfc-newcastle-2026/poster.jpg";

const authHeaders = {
  Authorization: `Bearer ${FIREBASE_ID_TOKEN}`,
  "Content-Type": "application/json",
};

export default function checkoutAndTokenScenario() {
  const deviceId = `dev-${__VU}`;
  let drmToken;

  group("PPV Storefront Reachability", () => {
    const res = http.get(STOREFRONT_URL, { redirects: 2 });
    storeDuration.add(res.timings.duration);

    const ok = check(res, {
      "store status < 400": (r) => r.status > 0 && r.status < 400,
      "store latency < 1200ms": (r) => r.timings.duration < 1200,
    });

    storeFailed.add(!ok);
  });

  group("Issue DRM Playback Token", () => {
    const payload = JSON.stringify({
      eventId: EVENT_ID,
      device: deviceId,
      scope: "playback",
    });

    const res = http.post(
      `${FUNCTIONS_BASE_URL}/drmTokenApi`,
      payload,
      { headers: authHeaders },
    );
    issueDuration.add(res.timings.duration);

    const ok = check(res, {
      "drm status 200": (r) => r.status === 200,
      "drm has token": (r) => {
        try {
          return !!JSON.parse(r.body).token;
        } catch {
          return false;
        }
      },
      "drm latency < 700ms": (r) => r.timings.duration < 700,
    });

    tokenIssueFailed.add(!ok);

    if (ok) {
      drmToken = JSON.parse(res.body).token;
    }
  });

  if (drmToken) {
    group("Issue CDN Edge Token", () => {
      const payload = JSON.stringify({
        assetUrl: CDN_ASSET_URL,
        ttlSeconds: 900,
      });
      const res = http.post(
        `${FUNCTIONS_BASE_URL}/cdnTokenApi`,
        payload,
        { headers: authHeaders },
      );
      cdnDuration.add(res.timings.duration);

      const ok = check(res, {
        "cdn token status 200": (r) => r.status === 200,
        "cdn token has signed url": (r) => {
          try {
            return !!JSON.parse(r.body).signedAssetUrl;
          } catch {
            return false;
          }
        },
        "cdn token latency < 700ms": (r) => r.timings.duration < 700,
      });

      cdnTokenFailed.add(!ok);
    });
  }

  sleep(0.2 + Math.random() * 0.3);
}

export function handleSummary(data) {
  return {
    "load/results/checkout_token_summary.json": JSON.stringify(data, null, 2),
    stdout: textSummary(data),
  };
}

function textSummary(data) {
  const lines = ["=== DFC Load Test Summary ==="];
  for (const [name, metric] of Object.entries(data.metrics || {})) {
    if (metric.values) {
      const v = metric.values;
      lines.push(
        `${name}: avg=${v.avg?.toFixed(2) || "-"} p95=${v["p(95)"]?.toFixed(2) || "-"} max=${v.max?.toFixed(2) || "-"}`,
      );
    }
  }
  return lines.join("\n");
}
