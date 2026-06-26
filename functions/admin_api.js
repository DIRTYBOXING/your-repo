const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Initialize Postgres Pool for SQL Data
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

const db = admin.heathewart();

// ═══════════════════════════════════════════════════════════════════════════
// SECURITY MIDDLEWARE
// ═══════════════════════════════════════════════════════════════════════════
/* Uncomment for Production to secure the admin panel
app.use(async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1];
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  try {
    req.user = await admin.auth().verifyIdToken(token);
    // Add custom claims check here if needed: if (!req.user.admin) throw error;
    next();
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});
*/

// ═══════════════════════════════════════════════════════════════════════════
// SQL ENDPOINTS (Structured Data)
// ═══════════════════════════════════════════════════════════════════════════

// --- FIGHTERS ---
app.get('/fighters', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM fighters ORDER BY created_at DESC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/fighters', async (req, res) => {
  const { id, first_name, last_name, nickname, weight_class, gym_id, promotion_id, profile_image_url, status } = req.body;
  try {
    const { rows } = await pool.query(
      `INSERT INTO fighters (id, first_name, last_name, nickname, weight_class, gym_id, promotion_id, profile_image_url, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       ON CONFLICT (id) DO UPDATE SET
         first_name = EXCLUDED.first_name,
         last_name = EXCLUDED.last_name,
         nickname = EXCLUDED.nickname,
         weight_class = EXCLUDED.weight_class,
         gym_id = EXCLUDED.gym_id,
         promotion_id = EXCLUDED.promotion_id,
         profile_image_url = EXCLUDED.profile_image_url,
         status = EXCLUDED.status,
         updated_at = NOW()
       RETURNING *`,
      [id, first_name, last_name, nickname, weight_class, gym_id, promotion_id, profile_image_url, status || 'active']
    );
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- GYMS ---
app.get('/gyms', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM gyms ORDER BY name ASC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// FIRESTORE ENDPOINTS (Real-time / CMS Data)
// ═══════════════════════════════════════════════════════════════════════════

// --- EDITORIAL CMS ---
app.post('/editorial/:slug', async (req, res) => {
  const { body } = req.body;
  try {
    await db.collection('editorial').doc(req.params.slug).set({
      body,
      updatedAt: Date.now(),
    }, { merge: true });
    res.json({ success: true, slug: req.params.slug });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/editorial/:slug', async (req, res) => {
  try {
    const doc = await db.collection('editorial').doc(req.params.slug).get();
    if (!doc.exists) return res.status(404).json({ error: 'Not found' });
    res.json(doc.data());
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- PPV REVENUE & PURCHASES ---
app.get('/ppv/revenue', async (req, res) => {
  try {
    // Aggregate from ppv_events collection where we track totalRevenueCents
    const eventsSnap = await db.collection('ppv_events').get();
    let totalRevenueCents = 0;
    let totalPurchases = 0;
    let topEvent = 'None';
    let maxSales = 0;

    eventsSnap.forEach(doc => {
      const data = doc.data();
      const rev = data.totalRevenueCents || 0;
      const purchases = data.purchaseCount || 0;
      totalRevenueCents += rev;
      totalPurchases += purchases;

      if (purchases > maxSales) {
        maxSales = purchases;
        topEvent = data.name || doc.id;
      }
    });

    res.json({
      totalRevenue: (totalRevenueCents / 100).toFixed(2),
      totalPurchases,
      topEvent
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/ppv/purchases', async (req, res) => {
  try {
    const snap = await db.collection('ppv_purchases').orderBy('purchasedAt', 'desc').limit(100).get();
    const purchases = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ purchases });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Export the Express App wrapped as a Cloud Function
exports.adminApi = functions.https.onRequest(app);
