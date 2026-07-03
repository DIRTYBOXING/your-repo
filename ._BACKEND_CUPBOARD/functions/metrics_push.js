"use strict";

const PUSH_TIMEOUT_MS = 10_000;

async function pushMetricsSnapshot({
  jobName = "dfc_functions",
  groupingKey = {},
  pushgatewayUrl = process.env.PUSHGATEWAY_URL,
  registry,
} = {}) {
  if (!pushgatewayUrl) {
    return { status: "skipped", reason: "PUSHGATEWAY_URL not set" };
  }

  let promClient = null;
  try {
    promClient = require("prom-client");
  } catch {
    return { status: "skipped", reason: "prom-client dependency not installed" };
  }

  const effectiveRegistry = registry || promClient.register;
  const metricsBody = await effectiveRegistry.metrics();
  const groupingPath = Object.entries(groupingKey)
    .map(([key, value]) => `/${encodeURIComponent(key)}/${encodeURIComponent(String(value))}`)
    .join("");
  const targetUrl = `${pushgatewayUrl.replace(/\/$/, "")}/metrics/job/${encodeURIComponent(jobName)}${groupingPath}`;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), PUSH_TIMEOUT_MS);

  try {
    const response = await fetch(targetUrl, {
      method: "POST",
      headers: { "Content-Type": promClient.register.contentType },
      body: metricsBody,
      signal: controller.signal,
    });

    if (!response.ok) {
      const detail = await response.text().catch(() => "");
      throw new Error(`Pushgateway responded ${response.status}: ${detail}`);
    }

    return { status: "ok", url: targetUrl };
  } finally {
    clearTimeout(timeout);
  }
}

module.exports = { pushMetricsSnapshot };