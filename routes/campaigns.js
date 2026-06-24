const express = require('express');
const db = require('../db');
const router = express.Router();

// Get all active campaigns
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM campaigns WHERE status = "active"');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/*// Create a campaign (brand only)
router.post('/', async (req, res) => {
  const { brand_id, title, description, product_url, payout_per_post, required_hashtag } = req.body;
  try {
    await db.query(
      'INSERT INTO campaigns (brand_id, title, description, product_url, payout_per_post, required_hashtag) VALUES (?, ?, ?, ?, ?, ?)',
      [brand_id, title, description, product_url, payout_per_post, required_hashtag]
    );
    res.json({ message: 'Campaign created successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}); */

// Create a campaign (brand only)
router.post('/', async (req, res) => {
  const { brand_id, title, description, product_url, payout_per_post, required_hashtag } = req.body;
  try {
    const [result] = await db.query(
      'INSERT INTO campaigns (brand_id, title, description, product_url, payout_per_post, required_hashtag, status) VALUES (?, ?, ?, ?, ?, ?, "active")',
      [brand_id, title, description, product_url, payout_per_post, required_hashtag]
    );
    res.json({ 
      id: result.insertId, 
      message: 'Campaign created successfully' 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;