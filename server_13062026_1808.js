const express = require('express');
const cors = require('cors');
const path = require('path'); // ✅ Added built-in path utility for clean directory mapping
require('dotenv').config();

const authRoutes = require('./routes/auth');
const campaignRoutes = require('./routes/campaigns');
const submissionRoutes = require('./routes/submissions');
const marketplaceRoutes = require('./routes/marketplace'); // ✅ Added Marketplace Route
const redirectRoutes = require('./routes/redirect');       // ✅ Added Central Redirect Router
const blogRoutes = require('./routes/blogs');              // ✅ Added: Import Blog Router
const db = require('./db');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.static('public')); 

// SSE Clients storage for real-time notifications (for creators with the dashboard already open)
let sseClients = [];

app.get('/api/notifications/stream', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  sseClients.push(res);

  req.on('close', () => {
    sseClients = sseClients.filter(client => client !== res);
  });
});

function sendNotificationToCreators(data) {
  sseClients.forEach(client => {
    client.write(`data: ${JSON.stringify(data)}\n\n`);
  });
}

// ── ORIGINAL CLICK TRACKING REDIRECT ROUTE ──────────────────
/*app.get('/r/:campaignId', async (req, res) => {
  const { campaignId } = req.params;

  // Check if this parameter contains a slash or is routing to the marketplace handler instead
  // This safeguards local variable collision issues
  if (req.originalUrl.split('/').length > 3) {
    return next();
  }

  try {
    // 1. Fetch the campaign details from your database
    const [rows] = await db.query('SELECT title FROM campaigns WHERE id = ?', [campaignId]);
    const campaignTitle = rows.length > 0 ? rows[0].title : 'Active Campaign';

    const notificationPayload = {
      type: 'AD_CLICK',
      title: '🔥 New Ad Click!',
      message: `Someone just clicked your link for "${campaignTitle}" on the travel blog!`
    };

    // 2. Broadcast to creators who already have the dashboard open in another tab
    sendNotificationToCreators(notificationPayload);

    // 3. Redirect the current tab to the dashboard with the fallback URL parameters
    return res.redirect(`/?clicked=true&campaignTitle=${encodeURIComponent(campaignTitle)}`);
    
  } catch (err) {
    console.error('Redirect tracking error:', err);
    res.redirect('/');
  }
}); */

// ── 1. UPDATED AFFILIATE REDIRECT LINK ──────────────────────
app.get('/r/:campaignId', async (req, res) => {
  const { campaignId } = req.params;

  try {
    // Look up the campaign title to display it on the store layout
    const [rows] = await db.query('SELECT title FROM campaigns WHERE id = ?', [campaignId]);
    const campaignTitle = rows.length > 0 ? rows[0].title : 'Active Campaign';

    // Broadcast live click alert to listening dashboards via SSE
    sendNotificationToCreators({
      type: 'AD_CLICK',
      title: '🔥 New Ad Click!',
      message: `Someone just clicked your link for "${campaignTitle}"!`
    });

    // ROUTE TO THE SIMULATED E-COMMERCE PRODUCT PAGE WITH THE CAMPAIGN ID PASSED VIA QUERY
    return res.redirect(`/product.html?campaignId=${campaignId}&title=${encodeURIComponent(campaignTitle)}`);
    
  } catch (err) {
    console.error('Redirect tracking error:', err);
    res.redirect('/');
  }
});

// ── 2. NEW E-COMMERCE WEBHOOK CONVERSION ENDPOINT ───────────
app.post('/api/submissions/conversion', async (req, res) => {
  const { campaignId, orderTotal } = req.body;

  if (!campaignId) {
    return res.status(400).json({ success: false, message: "Missing required campaignId parameter." });
  }

  try {
    // Calculate commission payload metrics (e.g., 20% of order value)
    const commissionEarnings = orderTotal * 0.20; 

    // Find the creator's entry inside your submissions table and approve it
    // Note: In production, you would map this by matching tracking tokens or creator IDs
    const [result] = await db.query(
      `UPDATE submissions 
       SET status = 'approved', payout_amount = ? 
       WHERE campaign_id = ?`, 
      [commissionEarnings, campaignId]
    );

    if (result.affectedRows === 0) {
      // Fallback: If no submission existed yet, we log it seamlessly
      console.log(`⚠️ Conversion logged for campaign ${campaignId}, but no active influencer assignment record was modified.`);
    } else {
      console.log(`💰 [Conversion Engine] Approved commission of ₹${commissionEarnings} for campaign ID ${campaignId}`);
    }

    // Trigger another real-time alert telling the creator they made money!
    sendNotificationToCreators({
      type: 'CONVERSION_SUCCESS',
      title: '💰 Commission Earned!',
      message: `Excellent! A confirmed purchase earned you ₹${commissionEarnings.toFixed(2)}!`
    });

    res.status(200).json({ success: true, message: "Conversion registered successfully." });

  } catch (err) {
    console.error('❌ Webhook processor error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── DYNAMIC NATIVE BLOG ROUTE ────────────────────────────────
// ✅ IMPLEMENTED: Serves the single dynamic blog layout file for any category
app.get('/blogs', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'blog.html'));
});

// Standard Route Middlewares
app.use('/api/auth', authRoutes);
app.use('/api/campaigns', campaignRoutes);
app.use('/api/submissions', submissionRoutes);
app.use('/api/marketplace', marketplaceRoutes); // ✅ Mounted Marketplace API Router
app.use('/api/blogs', blogRoutes);              // ✅ Mounted Blog API Router (Fixes the Brand View UI)
app.use('/r', redirectRoutes);                  // ✅ Mounted Personalized Affiliate Redirect Router

app.get('/', (req, res) => {
  res.json({ message: 'Nano Influencer API is running!' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});