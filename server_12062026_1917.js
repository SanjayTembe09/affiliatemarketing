const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const campaignRoutes = require('./routes/campaigns');
const submissionRoutes = require('./routes/submissions');
const marketplaceRoutes = require('./routes/marketplace'); // ✅ Added Marketplace Route
const redirectRoutes = require('./routes/redirect');       // ✅ Added Central Redirect Router
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
app.get('/r/:campaignId', async (req, res) => {
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
});

// Standard Route Middlewares
app.use('/api/auth', authRoutes);
app.use('/api/campaigns', campaignRoutes);
app.use('/api/submissions', submissionRoutes);
app.use('/api/marketplace', marketplaceRoutes); // ✅ Mounted Marketplace API Router
app.use('/r', redirectRoutes);                  // ✅ Mounted Personalized Affiliate Redirect Router

app.get('/', (req, res) => {
  res.json({ message: 'Nano Influencer API is running!' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});