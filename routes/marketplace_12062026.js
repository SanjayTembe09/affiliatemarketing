const express = require('express');
const db = require('../db');
const router = express.Router();

// GET /api/marketplace - Get all active products
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM marketplace_products WHERE status = "active"');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/marketplace - Brand adds a product to the marketplace
router.post('/', async (req, res) => {
  const { brand_id, title, description, product_url, image_url, price, commission_percentage } = req.body;
  try {
    await db.query(
      'INSERT INTO marketplace_products (brand_id, title, description, product_url, image_url, price, commission_percentage) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [brand_id, title, description, product_url, image_url || null, price, commission_percentage]
    );
    res.json({ message: 'Affiliate product added to marketplace successfully!' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;