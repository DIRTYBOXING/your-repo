// tools/sign_payload.js
// Sign a JSON payload with an RSA private key and output a JWT token.
// Usage: node sign_payload.js <private_key.pem> <payload.json>
const fs = require("fs");
const jwt = require("jsonwebtoken");

const privateKeyPath = process.argv[2];
const payloadPath = process.argv[3];

if (!privateKeyPath || !payloadPath) {
  console.error("Usage: node sign_payload.js <private_key.pem> <payload.json>");
  process.exit(1);
}

const privateKey = fs.readFileSync(privateKeyPath, "utf8");
const payload = JSON.parse(fs.readFileSync(payloadPath, "utf8"));

const token = jwt.sign(payload, privateKey, {
  algorithm: "RS256",
  expiresIn: "5m",
});
console.log(token);
