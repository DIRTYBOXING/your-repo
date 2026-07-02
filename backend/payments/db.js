// backend/payments/db.js
// Simple Postgres client wrapper for reference implementation.
const { Client } = require('pg');

const conn = process.env.PG_CONN || 'postgres://user:pass@localhost:5432/dfc_test';

function getClient() {
  const client = new Client({ connectionString: conn });
  return client;
}

module.exports = { getClient };
