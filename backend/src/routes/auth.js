const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { verifyToken } = require('../middleware/auth');
require('dotenv').config();

const GENDERS = ['male', 'female', 'other']; // must match gender_type enum

// Shared query: full profile, with date_of_birth as plain 'YYYY-MM-DD' text
const PROFILE_SQL = `
  SELECT u.id, u.name, u.email, u.phone, u.role, u.language_pref, u.created_at,
         TO_CHAR(p.date_of_birth, 'YYYY-MM-DD') AS date_of_birth,
         p.gender, p.chronic_conditions
  FROM users u
  LEFT JOIN patient_profiles p ON u.id = p.user_id
  WHERE u.id = $1`;

// ── REGISTER ──────────────────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const { name, email, password, phone, language_pref } = req.body;

  if (!name || !email || !password || !phone) {
    return res.status(400).json({ error: 'Name, email, phone and password are required.' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters.' });
  }

  try {
    const existingUser = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'Email already registered.' });
    }

    const password_hash = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO users (name, email, password_hash, phone, role, language_pref)
       VALUES ($1, $2, $3, $4, 'patient', $5)
       RETURNING id, name, email, phone, role, language_pref, created_at`,
      [name, email, password_hash, phone, language_pref || 'en']
    );
    const newUser = result.rows[0];

    await pool.query('INSERT INTO patient_profiles (user_id) VALUES ($1)', [newUser.id]);

    const token = jwt.sign(
      { id: newUser.id, role: newUser.role, language: newUser.language_pref },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(201).json({ message: 'Account created successfully.', token, user: newUser });

  } catch (err) {
    if (err.code === '23505') {
      return res.status(400).json({ error: 'Email or phone number already registered.' });
    }
    console.error('Register error:', err.message);
    res.status(500).json({ error: 'Server error during registration.' });
  }
});

// ── LOGIN ─────────────────────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }

  try {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }
    const user = result.rows[0];

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    if (user.is_active === false) {
      return res.status(403).json({ error: 'This account has been deactivated. Contact support.' });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role, language: user.language_pref },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(200).json({
      message: 'Login successful.',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        language_pref: user.language_pref
      }
    });

  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Server error during login.' });
  }
});

// ── GET PROFILE ───────────────────────────────────────────────────────────
router.get('/profile', verifyToken, async (req, res) => {
  try {
    const result = await pool.query(PROFILE_SQL, [req.user.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }
    res.status(200).json({ user: result.rows[0] });
  } catch (err) {
    console.error('Profile error:', err.message);
    res.status(500).json({ error: 'Server error fetching profile.' });
  }
});

// ── UPDATE PROFILE ────────────────────────────────────────────────────────
router.put('/profile', verifyToken, async (req, res) => {
  const { name, phone, date_of_birth, gender, chronic_conditions } = req.body;

  if (!name || name.trim().length < 2) {
    return res.status(400).json({ error: 'Name is required.' });
  }
  if (!phone) {
    return res.status(400).json({ error: 'Phone number is required.' });
  }
  if (gender && !GENDERS.includes(gender)) {
    return res.status(400).json({ error: 'Invalid gender value.' });
  }
  if (date_of_birth && (!/^\d{4}-\d{2}-\d{2}$/.test(date_of_birth) || new Date(date_of_birth) > new Date())) {
    return res.status(400).json({ error: 'Invalid date of birth.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query(
      `UPDATE users SET name = $1, phone = $2, updated_at = NOW() WHERE id = $3`,
      [name.trim(), phone, req.user.id]
    );

    await client.query(
      `INSERT INTO patient_profiles (user_id, date_of_birth, gender, chronic_conditions)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id) DO UPDATE
       SET date_of_birth = EXCLUDED.date_of_birth,
           gender = EXCLUDED.gender,
           chronic_conditions = EXCLUDED.chronic_conditions`,
      [req.user.id, date_of_birth || null, gender || null, chronic_conditions?.trim() || null]
    );

    await client.query('COMMIT');

    const result = await pool.query(PROFILE_SQL, [req.user.id]);
    res.status(200).json({ message: 'Profile updated.', user: result.rows[0] });

  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') {
      return res.status(400).json({ error: 'That phone number is already in use.' });
    }
    console.error('Profile update error:', err.message);
    res.status(500).json({ error: 'Server error updating profile.' });
  } finally {
    client.release();
  }
});

// ── UPDATE LANGUAGE PREFERENCE ────────────────────────────────────────────
router.patch('/language', verifyToken, async (req, res) => {
  const { language_pref } = req.body;

  if (!['en', 'sw'].includes(language_pref)) {
    return res.status(400).json({ error: 'Language must be "en" or "sw".' });
  }

  try {
    const result = await pool.query(
      `UPDATE users SET language_pref = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING id, name, email, phone, role, language_pref`,
      [language_pref, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }
    res.status(200).json({ message: 'Language updated.', user: result.rows[0] });
  } catch (err) {
    console.error('Language update error:', err.message);
    res.status(500).json({ error: 'Server error updating language.' });
  }
});

module.exports = router;