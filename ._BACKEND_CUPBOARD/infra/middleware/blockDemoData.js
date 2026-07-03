// infra/middleware/blockDemoData.js
// Express middleware to block demo/test tokens in production writes
const bannedRegex = /(demo_|test_|edu_|sample_|example|placeholder)/i;

function blockDemoData(options = {}) {
  const logger = options.auditLogger || defaultAuditLogger;
  return function (req, res, next) {
    try {
      const envHeader = (req.headers["x-environment"] || "")
        .toString()
        .toLowerCase();
      const bodyEnv =
        req.body && req.body.environment
          ? String(req.body.environment).toLowerCase()
          : "";
      const environment =
        envHeader || bodyEnv || process.env.NODE_ENV || "production";

      // Only enforce in production environment
      if (environment === "production") {
        const payload = JSON.stringify(req.body || {});
        if (bannedRegex.test(payload)) {
          // Log audit entry for blocked attempt
          logger({
            actor: req.user && req.user.id ? req.user.id : "service",
            action: "blocked_demo_data",
            resource: req.path,
            details: { ip: req.ip, payloadSample: payload.slice(0, 100) },
            timestamp: new Date().toISOString(),
          });

          return res.status(400).json({
            error:
              "Demo or test data detected. Writes containing demo/test tokens are not allowed in production.",
          });
        }
      }
      return next();
    } catch (err) {
      // Fail safe: if middleware errors, block the request and alert ops
      console.error("blockDemoData middleware error", err);
      // Optionally log to audit
      try {
        logger({
          actor: req.user && req.user.id ? req.user.id : "service",
          action: "block_middleware_error",
          resource: req.path,
          details: { error: String(err) },
          timestamp: new Date().toISOString(),
        });
      } catch (e) {
        /* swallow */
      }
      return res.status(500).json({ error: "Server middleware error" });
    }
  };
}

// Default audit logger that writes to console. Replace with your audit store integration.
function defaultAuditLogger(entry) {
  // Minimal shape: actor, action, resource, details, timestamp
  console.log("[AUDIT]", JSON.stringify(entry));
}

module.exports = blockDemoData;
