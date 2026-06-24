const express = require('express');
const db = require('../db');
const router = express.Router();

// ── GET /api/blogs ───────────────────────────────────────────
// List all active registered blog nodes for the brand dashboard
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM blog_sites WHERE status = "active"');
    res.json(rows);
  } catch (err) {
    console.error("❌ Error fetching blog sites:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/blogs/match ─────────────────────────────────────
// Route contextual matches instantly across campaigns and marketplace items
/*router.get('/match', async (req, res) => {
  // Normalize the query string to lowercase to ensure absolute matching parity
  const category = (req.query.category || 'travel').toLowerCase();
  
  try {
    // 1. Scan the campaigns table for contextually matching titles or descriptions
    const [campaigns] = await db.query(
      `SELECT id, title, description, price, 'campaign' AS source_type 
       FROM campaigns 
       WHERE status = 'active' AND (LOWER(title) LIKE ? OR LOWER(description) LIKE ?)`,
      [`%${category}%`, `%${category}%`]
    );
    
    // 2. Scan your new marketplace_products table for the exact same category keyword
    const [products] = await db.query(
      `SELECT id, title, description, price, 'marketplace' AS source_type 
       FROM marketplace_products 
       WHERE status = 'active' AND (LOWER(title) LIKE ? OR LOWER(description) LIKE ?)`,
      [`%${category}%`, `%${category}%`]
    );

    // 3. Unify both database streams into a singular array payload
    const combinedResults = [...campaigns, ...products];

    // Log the structural lookup matrix parameters into your nodemon terminal for tracking
    console.log(`\n🔍 Contextual Engine: Found ${combinedResults.length} true matches for category: "${category}"`);
    console.log(`   └─ Campaigns: ${campaigns.length} | Marketplace: ${products.length}`);

    // 4. Send back the accurate data stream (If empty, it cleanly returns [] without leaks!)
    res.json(combinedResults);

  } catch (err) {
    console.error('\n❌ CRITICAL CONTEXTUAL MATCHING ENGINE FAILURE:');
    console.error(err.message);
    res.status(500).json({ error: `Contextual lookup failed: ${err.message}` });
  }
}); */

// GET /api/blogs/match - Route contextual matches instantly across campaigns and marketplace items
router.get('/match', async (req, res) => {
  const category = (req.query.category || 'travel').toLowerCase();
  
  try {
    // 1. Scan campaigns table (We remove the hardcoded 'price' column and map a fallback instead)
    // Adjust '0 AS price' below to match your actual column name (e.g., 'payout AS price') if needed!
    const [campaigns] = await db.query(
      `SELECT id, title, description, 0 AS price, 'campaign' AS source_type 
       FROM campaigns 
       WHERE status = 'active' AND (LOWER(title) LIKE ? OR LOWER(description) LIKE ?)`,
      [`%${category}%`, `%${category}%`]
    );
    
    // 2. Scan your marketplace_products table (which explicitly contains the 'price' field)
    const [products] = await db.query(
      `SELECT id, title, description, price, 'marketplace' AS source_type 
       FROM marketplace_products 
       WHERE status = 'active' AND (LOWER(title) LIKE ? OR LOWER(description) LIKE ?)`,
      [`%${category}%`, `%${category}%`]
    );

    // 3. Merge both sets of data cleanly
    const combinedResults = [...campaigns, ...products];

    console.log(`\n🔍 Contextual Engine: Found ${combinedResults.length} true matches for category: "${category}"`);
    res.json(combinedResults);

  } catch (err) {
    console.error('\n❌ CRITICAL CONTEXTUAL MATCHING ENGINE FAILURE:');
    console.error(err.message);
    res.status(500).json({ error: `Contextual lookup failed: ${err.message}` });
  }
});

module.exports = router;