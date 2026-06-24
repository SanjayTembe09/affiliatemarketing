const express = require('express');
const db = require('../db');
const router = express.Router();

// GET /r/:product_id/:creator_id - Log affiliate metrics and redirect shopper seamlessly
router.get('/:product_id/:creator_id', async (req, res) => {
  const { product_id, creator_id } = req.params;

  try {
    // 1. Fetch destination context
    const [products] = await db.query('SELECT product_url FROM marketplace_products WHERE id = ?', [product_id]);
    
    if (!products.length) {
      return res.status(404).send('Product link expired or unavailable.');
    }

    // 2. Log performance metrics safely asynchronously
    await db.query('INSERT INTO affiliate_clicks (product_id, creator_id) VALUES (?, ?)', [product_id, creator_id]);

    // 3. Bounce browser straight to destination target
    res.redirect(products[0].product_url);
  } catch (err) {
    res.status(500).send('Redirection system handling error: ' + err.message);
  }
});

module.exports = router;