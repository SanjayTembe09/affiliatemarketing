const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const campaignRoutes = require('./routes/campaigns');
const submissionRoutes = require('./routes/submissions');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.static('public')); // ← ADD THIS LINE

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/campaigns', campaignRoutes);
app.use('/api/submissions', submissionRoutes);

// Health check
app.get('/', (req, res) => {
  res.json({ message: 'Nano Influencer API is running!' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});