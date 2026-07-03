import fs from "node:fs";
import path from "node:path";

const connectUrl = process.argv[2];
const subscriptionUrl = process.argv[3];

if (!connectUrl || !subscriptionUrl) {
  console.error(
    "Usage: node scripts/provision_stripe_connect_v2_webhooks.mjs <connectWebhookUrl> <subscriptionWebhookUrl>",
  );
  process.exit(1);
}

const repoRoot = process.cwd();
const envPath = path.join(repoRoot, "functions", ".env");
if (!fs.existsSync(envPath)) {
  console.error("functions/.env not found");
  process.exit(1);
}

const envText = fs.readFileSync(envPath, "utf8");
const envMap = new Map();
for (const line of envText.split(/\r?\n/)) {
  if (!line || line.trim().startsWith("#") || !line.includes("=")) continue;
  const index = line.indexOf("=");
  const key = line.slice(0, index).trim();
  const value = line.slice(index + 1);
  envMap.set(key, value);
}

const stripeSecretKey = envMap.get("STRIPE_SECRET_KEY");
if (!stripeSecretKey) {
  console.error("STRIPE_SECRET_KEY is missing from functions/.env");
  process.exit(1);
}

async function createWebhookEndpoint(url, description, enabledEvents) {
  const body = new URLSearchParams();
  body.set("url", url);
  body.set("description", description);
  for (const eventName of enabledEvents) {
    body.append("enabled_events[]", eventName);
  }

  const response = await fetch("https://api.stripe.com/v1/webhook_endpoints", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${stripeSecretKey}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(
      payload?.error?.message ||
        `Stripe API request failed (${response.status})`,
    );
  }

  return payload;
}

function setEnvValue(key, value) {
  const lines = fs.readFileSync(envPath, "utf8").split(/\r?\n/);
  let updated = false;
  const nextLines = lines.map((line) => {
    if (line.startsWith(`${key}=`)) {
      updated = true;
      return `${key}=${value}`;
    }
    return line;
  });
  if (!updated) {
    nextLines.push(`${key}=${value}`);
  }
  fs.writeFileSync(envPath, `${nextLines.join("\n").replace(/\n+$/, "")}\n`);
}

const connectEvents = ["account.updated"];

const subscriptionEvents = [
  "customer.subscription.created",
  "customer.subscription.updated",
  "customer.subscription.deleted",
  "invoice.paid",
  "invoice.payment_failed",
];

try {
  const connectWebhook = await createWebhookEndpoint(
    connectUrl,
    "DFC Stripe Connect account webhook",
    connectEvents,
  );
  const subscriptionWebhook = await createWebhookEndpoint(
    subscriptionUrl,
    "DFC Stripe subscription lifecycle webhook",
    subscriptionEvents,
  );

  if (!connectWebhook.secret || !subscriptionWebhook.secret) {
    throw new Error(
      "Stripe did not return webhook signing secrets on creation.",
    );
  }

  setEnvValue("STRIPE_WEBHOOK_SECRET_CONNECT", connectWebhook.secret);
  setEnvValue(
    "STRIPE_WEBHOOK_SECRET_SUBSCRIPTIONS",
    subscriptionWebhook.secret,
  );

  console.log(`Created connect webhook endpoint: ${connectWebhook.id}`);
  console.log(
    `Created subscription webhook endpoint: ${subscriptionWebhook.id}`,
  );
  console.log("Updated functions/.env with webhook signing secrets.");
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
