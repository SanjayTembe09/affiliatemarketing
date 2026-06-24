const express = require('express');
const db = require('../db');
const router = express.Router();
//const fetch = require('node-fetch'); // add this if not already there

// Helper: extract tweet ID from URL
function extractTweetId(url) {
  const match = url.match(/status\/(\d+)/);
  return match ? match[1] : null;
}

// Helper: verify tweet via X API
/*async function verifyTweet(tweetId, requiredHashtag, productUrl) {
  const response = await fetch(
    `https://api.twitter.com/2/tweets/${tweetId}?tweet.fields=text,public_metrics`,
    {
      headers: { Authorization: `Bearer ${process.env.X_BEARER_TOKEN}` },
    }
  );
  const data = await response.json();
  if (!data.data) return { valid: false, reason: 'Tweet not found' };

  const text = data.data.text.toLowerCase();
  if (!text.includes(requiredHashtag.toLowerCase()))
    return { valid: false, reason: `Missing hashtag ${requiredHashtag}` };
  if (!text.includes(productUrl.toLowerCase()))
    return { valid: false, reason: 'Product URL not found in tweet' };

  return { valid: true, metrics: data.data.public_metrics };
} */

async function verifyTweet(tweetId, requiredHashtag, productUrl) {
  // ⚠️ MOCK MODE - Replace with real version when X API credits are added
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

// Submit a post for a campaign
router.post('/', async (req, res) => {
  const { creator_id, campaign_id, post_url } = req.body;
  try {
    // Get campaign details
    const [campaigns] = await db.query('SELECT * FROM campaigns WHERE id = ?', [campaign_id]);
    if (!campaigns.length) return res.status(404).json({ error: 'Campaign not found' });

    const campaign = campaigns[0];
    const tweetId = extractTweetId(post_url);
    if (!tweetId) return res.status(400).json({ error: 'Invalid tweet URL' });

    // Verify the tweet
    const result = await verifyTweet(tweetId, campaign.required_hashtag, campaign.product_url);
    if (!result.valid) return res.status(400).json({ error: result.reason });

    // Calculate payout (80% to creator, 20% app commission)
    const payout = campaign.payout_per_post * 0.8;

    // Save submission
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

// Get all submissions for a creator
router.get('/:creator_id', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT s.*, c.title as campaign_title FROM submissions s JOIN campaigns c ON s.campaign_id = c.id WHERE s.creator_id = ?',
      [req.params.creator_id]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Fetch latest tweets for a user
router.get('/tweets/:handle', async (req, res) => {
  try {
    const handle = req.params.handle;

    // Step 1: Get user ID from handle
    const userRes = await fetch(
      `https://api.twitter.com/2/users/by/username/${handle}`,
      {
        headers: {
          Authorization: `Bearer ${process.env.X_BEARER_TOKEN}`
        }
      }
    );
    const userData = await userRes.json();

    if (!userData.data) {
      return res.status(404).json({ error: 'Twitter user not found' });
    }

    const userId = userData.data.id;

    // Step 2: Get their latest 10 tweets
    const tweetsRes = await fetch(
      `https://api.twitter.com/2/users/${userId}/tweets?max_results=10&tweet.fields=text,created_at`,
      {
        headers: {
          Authorization: `Bearer ${process.env.X_BEARER_TOKEN}`
        }
      }
    );
    const tweetsData = await tweetsRes.json();

    if (!tweetsData.data) {
      return res.status(404).json({ error: 'No tweets found' });
    }

    // Step 3: Format and return
    const tweets = tweetsData.data.map(tweet => ({
      id: tweet.id,
      text: tweet.text,
      created_at: tweet.created_at,
      url: `https://x.com/${handle}/status/${tweet.id}`
    }));

    res.json(tweets);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

module.exports = router;