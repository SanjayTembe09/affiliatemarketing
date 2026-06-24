const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const router = express.Router();

// Register
router.post('/register', async (req, res) => {
  const { name, email, password, role, twitter_handle } = req.body;
  try {
    const hashed = await bcrypt.hash(password, 10);
    await db.query(
      'INSERT INTO users (name, email, password, role, twitter_handle) VALUES (?, ?, ?, ?, ?)',
      [name, email, hashed, role, twitter_handle]
    );
    res.json({ message: 'User registered successfully' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  // 👇 ADD THIS TEMPORARY RESET BLOCK 👇
 /* if (email === 'rmworkzcom@gmail.com') {
     const tempHash = await bcrypt.hash('rmworkzAffiliate@2026', 10);
     await db.query('UPDATE users SET password = ? WHERE email = ?', [tempHash, 'rmworkzcom@gmail.com']);
     console.log("Password successfully synchronized natively!");
  } */  
  // 👆 END OF TEMPORARY RESET BLOCK 👆

  try {
    const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (!rows.length) return res.status(404).json({ error: 'User not found' });

    const valid = await bcrypt.compare(password, rows[0].password);
    if (!valid) return res.status(401).json({ error: 'Wrong password' });

    const token = jwt.sign(
      { id: rows[0].id, role: rows[0].role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    res.json({ token, user: { id: rows[0].id, name: rows[0].name, role: rows[0].role } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;