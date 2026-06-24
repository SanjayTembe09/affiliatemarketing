const express = require('express');
const db = require('../db');
const router = express.Router();

// GET /api/blogs - List all active registered blog nodes
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM blog_sites WHERE status = "active"');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/blogs/match - Route contextual matches instantly 
router.get('/match', async (req, res) => {
  const category = req.query.category || 'travel';
  try {
    // Find active campaigns matching keyword descriptions or labels
    const [campaigns] = await db.query(
      'SELECT * FROM campaigns WHERE status = "active" AND (LOWER(title) LIKE ? OR LOWER(description) LIKE ?)',
      [`%${category}%`, `%${category}%`]
    );
    
    if (campaigns.length > 0) {
      res.json(campaigns);
    } else {
      // Fallback: grab any random active fallback campaign if niche is dry
      const [fallback] = await db.query('SELECT * FROM campaigns WHERE status = "active" LIMIT 5');
      res.json(fallback);
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;