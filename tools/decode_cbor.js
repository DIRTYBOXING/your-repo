#!/usr/bin/env node
/**
 * CHUCKYA Radar — CBOR Decode Tool
 *
 * Decodes CBOR-encoded payloads from bracelet/phone logs for debugging.
 * Accepts hex string as CLI argument or reads from stdin.
 *
 * Usage:
 *   node tools/decode_cbor.js <hex_string>
 *   echo "a40102..." | node tools/decode_cbor.js
 *   node tools/decode_cbor.js --file raw_payload.bin
 *
 * Requires: npm install cbor  (in project root or globally)
 */

const fs = require("fs");

// CBOR integer key mapping (matches cbor_schema.json / firmware encoder)
const KEY_MAP = {
  1: "eventType",
  2: "timestamp",
  3: "deviceId",
  4: "nonce",
  5: "riskScore",
  6: "batteryPercent",
  7: "consentLocation",
  8: "consentImei",
};

async function decodeCbor(buffer) {
  let cbor;
  try {
    cbor = require("cbor");
  } catch (_e) {
    console.error("ERROR: cbor package not installed.");
    console.error("Run: npm install cbor");
    process.exit(2);
  }

  try {
    const decoded = cbor.decodeFirstSync(buffer);
    return decoded;
  } catch (err) {
    console.error("ERROR: Failed to decode CBOR:", err.message);
    process.exit(3);
  }
}

function mapKeys(obj) {
  if (typeof obj !== "object" || obj === null) return obj;
  const mapped = {};
  for (const [key, value] of Object.entries(obj)) {
    const numKey = Number(key);
    const name = KEY_MAP[numKey] || `unknown_${key}`;
    mapped[name] = value;
  }
  return mapped;
}

function hexToBuffer(hex) {
  const clean = hex.replace(/[\s\n\r0x,]/g, "");
  if (!/^[0-9a-fA-F]+$/.test(clean)) {
    console.error("ERROR: Input is not valid hex.");
    process.exit(4);
  }
  return Buffer.from(clean, "hex");
}

async function main() {
  const args = process.argv.slice(2);
  let buffer;

  if (args.includes("--file") || args.includes("-f")) {
    const fileIdx =
      args.indexOf("--file") !== -1
        ? args.indexOf("--file")
        : args.indexOf("-f");
    const filePath = args[fileIdx + 1];
    if (!filePath || !fs.existsSync(filePath)) {
      console.error(`ERROR: File not found: ${filePath}`);
      process.exit(2);
    }
    buffer = fs.readFileSync(filePath);
  } else if (args.length > 0 && args[0] !== "--help" && args[0] !== "-h") {
    // Treat remaining args as hex string
    buffer = hexToBuffer(args.join(""));
  } else if (!process.stdin.isTTY) {
    // Read from stdin
    const chunks = [];
    for await (const chunk of process.stdin) {
      chunks.push(chunk);
    }
    const input = Buffer.concat(chunks).toString("utf-8").trim();
    buffer = hexToBuffer(input);
  } else {
    console.log("CHUCKYA CBOR Decode Tool");
    console.log("");
    console.log("Usage:");
    console.log("  node tools/decode_cbor.js <hex_string>");
    console.log('  echo "a40102..." | node tools/decode_cbor.js');
    console.log("  node tools/decode_cbor.js --file raw_payload.bin");
    console.log("");
    console.log("Key mapping (integer → field name):");
    for (const [k, v] of Object.entries(KEY_MAP)) {
      console.log(`  ${k} → ${v}`);
    }
    process.exit(0);
  }

  console.log(`Input: ${buffer.length} bytes`);
  console.log("");

  const decoded = await decodeCbor(buffer);

  console.log("--- Raw decoded ---");
  console.log(JSON.stringify(decoded, null, 2));
  console.log("");

  if (typeof decoded === "object" && decoded !== null) {
    const mapped = mapKeys(decoded);
    console.log("--- Mapped fields ---");
    console.log(JSON.stringify(mapped, null, 2));

    // Highlight key values for operators
    console.log("");
    console.log("--- Summary ---");
    if (mapped.eventType !== undefined)
      console.log(`  Event type : ${mapped.eventType}`);
    if (mapped.timestamp !== undefined) {
      const dt = new Date(mapped.timestamp * 1000);
      console.log(`  Timestamp  : ${mapped.timestamp} (${dt.toISOString()})`);
    }
    if (mapped.deviceId !== undefined)
      console.log(`  Device ID  : ${mapped.deviceId}`);
    if (mapped.nonce !== undefined)
      console.log(`  Nonce      : ${mapped.nonce}`);
    if (mapped.riskScore !== undefined)
      console.log(`  Risk score : ${mapped.riskScore}`);
    if (mapped.batteryPercent !== undefined)
      console.log(`  Battery    : ${mapped.batteryPercent}%`);
    if (mapped.consentLocation !== undefined)
      console.log(`  GPS consent: ${mapped.consentLocation}`);
    if (mapped.consentImei !== undefined)
      console.log(`  IMEI consent: ${mapped.consentImei}`);
  }
}

main();
