require('dotenv').config();
const bcrypt = require('bcrypt');
const pool = require('../src/config/db');

(async () => {
  const [name, email, password, phone] = process.argv.slice(2);
  if (!name || !email || !password || !phone) {
    console.log('Usage: node scripts/create-admin.js "Full Name" email password +2547XXXXXXXX');
    process.exit(1);
  }
  try {
    const hash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `INSERT INTO users (name, email, password_hash, phone, role, language_pref, is_active)
       VALUES ($1, $2, $3, $4, 'admin', 'en', true)
       ON CONFLICT (email) DO UPDATE
         SET role = 'admin', password_hash = EXCLUDED.password_hash, is_active = true
       RETURNING id, name, email, role`,
      [name, email, hash, phone]
    );
    console.log('✅ Admin ready:', result.rows[0]);
  } catch (err) {
    console.error('❌ Could not create admin:', err.message);
  } finally {
    await pool.end();
  }
})();