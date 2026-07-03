// tests/testJti.js
"use strict";

const {
  markJtiConsumed,
  isJtiConsumed,
  revokeJti,
  close,
} = require("../jtiStore");

(async () => {
  const jti = "test-jti-" + Date.now();

  console.log("initial consumed?", await isJtiConsumed(jti)); // false
  const ok = await markJtiConsumed(jti, 10);
  console.log("mark consumed ok?", ok); // true
  console.log("after consumed?", await isJtiConsumed(jti)); // true
  const ok2 = await markJtiConsumed(jti, 10);
  console.log("second mark attempt (should be false):", ok2); // false
  await revokeJti(jti);
  console.log("after revoke consumed?", await isJtiConsumed(jti)); // false

  await close();
  console.log("done");
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
