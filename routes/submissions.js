const express = require('express');
const db = require('../db');
const router = express.Router();

// Helper: extract tweet ID from URL
function extractTweetId(url) {
  const match = url.match(/status\/(\d+)/);
  return match ? match[1] : null;
}

// Helper: verify tweet (MOCK MODE)
async function verifyTweet(tweetId, requiredHashtag, productUrl) {
  console.log(`[MOCK] Verifying tweet ID: ${tweetId}`);
  console.log(`[MOCK] Required hashtag: ${requiredHashtag}`);
  console.log(`[MOCK] Product URL: ${productUrl}`);

  return {
    valid: true,
    metrics: {
      retweet_count: 5,
      reply_count: 2,
      like_count: 10,
      impression_count: 100
    }
  };
}

// ⚠️ IMPORTANT: /tweets/:handle MUST come BEFORE /:creator_id
// otherwise Express matches "tweets" as a creator_id

// GET /api/submissions/tweets/:handle  (MOCK)
router.get('/tweets/:handle', async (req, res) => {
  const handle = req.params.handle;
  res.json([
    {
      id: '2062152114357538905',
      text: 'Adding this Thai Jasmine Rice Face Serum to my daily skincare routine! 🧼 It\'s so gentle on sensitive skin. #skincare #beauty #ad #nanotest',
      created_at: new Date().toISOString(),
      url: `https://x.com/${handle}/status/2062152114357538905`
    },
    {
      id: '2061766521186074624',
      text: 'Check out Thai Jasmine Rice Face Serum: http://localhost:3000/r/7673c878 #nanotest',
      created_at: new Date().toISOString(),
      url: `https://x.com/${handle}/status/2061766521186074624`
    }
  ]);
});

// POST /api/submissions — Submit a post for a campaign
router.post('/', async (req, res) => {
  const { creator_id, campaign_id, post_url } = req.body;
  try {
    const [campaigns] = await db.query('SELECT * FROM campaigns WHERE id = ?', [campaign_id]);
    if (!campaigns.length) return res.status(404).json({ error: 'Campaign not found' });

    const campaign = campaigns[0];
    const tweetId = extractTweetId(post_url);
    if (!tweetId) return res.status(400).json({ error: 'Invalid tweet URL' });

    const result = await verifyTweet(tweetId, campaign.required_hashtag, campaign.product_url);
    if (!result.valid) return res.status(400).json({ error: result.reason });

    // 80% to creator, 20% app commission
    const payout = campaign.payout_per_post * 0.8;

    await db.query(
      'INSERT INTO submissions (creator_id, campaign_id, post_url, status, payout_amount) VALUES (?, ?, ?, "approved", ?)',
      [creator_id, campaign_id, post_url, payout]
    );

    res.json({
      message: 'Post verified and approved!',
      payout_amount: payout,
      metrics: result.metrics,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── FIXED ENDPOINT: GET /api/submissions/:creator_id ──────────
// Unifies both Brand Campaigns and Marketplace conversions for the dashboard UI
router.get('/:creator_id', async (req, res) => {
  const creatorId = req.params.creator_id;
  try {
    // We match the columns perfectly so the frontend template can loop over them seamlessly
    const [rows] = await db.query(
      `SELECT 
        s.id AS id,
        s.creator_id AS creator_id,
        s.campaign_id AS campaign_id,
        s.post_url AS post_url,
        s.status AS status,
        s.payout_amount AS payout_amount,
        s.submitted_at AS submitted_at,
        c.title AS campaign_title,
        'Direct' AS source_type
       FROM submissions s 
       JOIN campaigns c ON s.campaign_id = c.id 
       WHERE s.creator_id = ?
       
       UNION ALL
       
       SELECT 
        m.id AS id,
        m.creator_id AS creator_id,
        m.product_id AS campaign_id,
        'Marketplace Sale Link' AS post_url,
        m.status AS status,
        m.payout_amount AS payout_amount,
        m.submitted_at AS submitted_at,
        p.title AS campaign_title,
        'Marketplace' AS source_type
       FROM marketplace_submissions m
       JOIN marketplace_products p ON m.product_id = p.id
       WHERE m.creator_id = ?`,
      [creatorId, creatorId]
    );
    
    res.json(rows);
  } catch (err) {
    console.error("❌ Dashboard compilation query error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;