#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");
const sgMail = require("@sendgrid/mail");

function loadEnvFile(envPath) {
  if (!fs.existsSync(envPath)) {
    return {};
  }

  const result = {};
  for (const line of fs.readFileSync(envPath, "utf8").split(/\r?\n/)) {
    if (!line || line.trimStart().startsWith("#") || !line.includes("=")) {
      continue;
    }

    const index = line.indexOf("=");
    const key = line.slice(0, index).trim();
    const value = line.slice(index + 1);
    result[key] = value;
  }

  return result;
}

function parseArgs(argv) {
  const options = {
    to: "",
    subject: "DFC SendGrid Test",
    dryRun: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--to") {
      options.to = argv[index + 1] || "";
      index += 1;
    } else if (arg === "--subject") {
      options.subject = argv[index + 1] || options.subject;
      index += 1;
    } else if (arg === "--dry-run") {
      options.dryRun = true;
    } else if (!options.to && !arg.startsWith("--")) {
      options.to = arg;
    }
  }

  return options;
}

async function main() {
  const repoRoot = path.resolve(__dirname, "..", "..");
  const envPath = path.join(repoRoot, "functions", ".env");
  const envFile = loadEnvFile(envPath);
  const sendGridApiKey =
    process.env.SENDGRID_API_KEY || envFile.SENDGRID_API_KEY || "";
  const fromEmail =
    process.env.FROM_EMAIL ||
    envFile.FROM_EMAIL ||
    "legal@datafightcentral.com";
  const options = parseArgs(process.argv.slice(2));

  if (!sendGridApiKey) {
    throw new Error(
      "SENDGRID_API_KEY is missing. Add it to functions/.env or your shell environment.",
    );
  }

  if (!options.to) {
    throw new Error("Recipient missing. Pass --to someone@example.com");
  }

  sgMail.setApiKey(sendGridApiKey);

  const message = {
    to: options.to,
    from: {
      email: fromEmail,
      name: "DFC Test Mailer",
    },
    subject: options.subject,
    text: [
      "This is a DFC SendGrid test email.",
      "",
      "If you received this, the SENDGRID_API_KEY and FROM_EMAIL configuration is working.",
      "",
      `Repo: Data Fight Central`,
      `Timestamp: ${new Date().toISOString()}`,
    ].join("\n"),
    html: [
      '<div style="font-family:Arial,sans-serif;max-width:640px;margin:0 auto;padding:24px;background:#0f172a;color:#e2e8f0;border-radius:16px;">',
      '<h1 style="color:#00d9ff;">DFC SendGrid Test</h1>',
      "<p>If you received this, the <strong>SENDGRID_API_KEY</strong> and <strong>FROM_EMAIL</strong> configuration is working.</p>",
      `<p><strong>Repo:</strong> Data Fight Central<br /><strong>Timestamp:</strong> ${new Date().toISOString()}</p>`,
      "</div>",
    ].join(""),
  };

  if (options.dryRun) {
    console.log(
      `Ready to send SendGrid test email to ${options.to} from ${fromEmail}`,
    );
    return;
  }

  await sgMail.send(message);
  console.log(`SendGrid test email sent to ${options.to} from ${fromEmail}`);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
