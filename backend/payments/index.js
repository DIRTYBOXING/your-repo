// backend/payments/index.js
const express = require('express');
const bodyParser = require('body-parser');
const webhookHandler = require('./webhook_handler');
const verifyHandler = require('./verify_session');

const app = express();
app.use(bodyParser.json({ limit: '1mb' }));

// Public webhook endpoint (provider -> backend)
app.post('/payments/webhook', webhookHandler);

// Internal idempotent verify endpoint (replay script and webhook handler call this)
app.post('/internal/payments/verify-session', verifyHandler);

const port = process.env.PORT || 8080;
if (require.main === module) {
  app.listen(port, () => {
    console.log(`Payments reference server listening on ${port}`);
  });
}

module.exports = app;
