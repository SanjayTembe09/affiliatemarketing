const express = require('express');
const db = require('../db');
const router = express.Router();

// ── GET /api/marketplace ───────────────────────────────────────
// Fetches all active products to display in creator and brand feeds
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM marketplace_products WHERE status = "active" ORDER BY created_at DESC'
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ MySQL Fetch Error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── POST /api/marketplace ──────────────────────────────────────
// Fired when a brand pushes a new item from brand.html
router.post('/', async (req, res) => {
  const { brand_id, title, description, product_url, image_url, price, commission_percentage } = req.body;

  // Structural check to prevent empty values from hitting NOT NULL columns
  if (!brand_id || !title || !description || !product_url || !price || !commission_percentage) {
    return res.status(400).json({ error: 'Missing required configuration entry fields.' });
  }

  try {
    // In promise-based mysql2, db.query returns [resultMetadata]
    const [result] = await db.query(
      `INSERT INTO marketplace_products 
      (brand_id, title, description, product_url, image_url, price, commission_percentage, status) 
      VALUES (?, ?, ?, ?, ?, ?, ?, 'active')`,
      [brand_id, title, description, product_url, image_url || null, price, commission_percentage]
    );

    // ✅ SUCCESS: MySQL provides the new row ID via result.insertId
    console.log(`\n✅ Product Row Saved! MySQL Generated ID: ${result.insertId}`);
    
    res.json({ 
      id: result.insertId, 
      success: true,
      message: 'Affiliate product added to marketplace successfully!' 
    });

  } catch (err) {
    // This logs the exact error details to your terminal window if a column crashes
    console.error("\n❌ CRITICAL MYSQL INSERTION CRASH:");
    console.error(err.message);
    
    res.status(500).json({ error: `Database rejection: ${err.message}` });
  }
});

module.exports = router;