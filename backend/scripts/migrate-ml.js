// Phase 8.4 migration: adds hybrid-triage columns to consultations.
// Run from the backend folder:  node scripts/migrate-ml.js
require('dotenv').config();
const pool = require('../src/config/db');

const STATEMENTS = [
  `ALTER TABLE consultations ADD COLUMN IF NOT EXISTS gemini_triage    VARCHAR(20)`,
  `ALTER TABLE consultations ADD COLUMN IF NOT EXISTS ml_triage        VARCHAR(20)`,
  `ALTER TABLE consultations ADD COLUMN IF NOT EXISTS ml_confidence    NUMERIC(5,4)`,
  `ALTER TABLE consultations ADD COLUMN IF NOT EXISTS triage_agreement VARCHAR(20)`,
  `ALTER TABLE consultations ADD COLUMN IF NOT EXISTS ml_model_version VARCHAR(40)`,
  // Auto-flags are made by the system, not an admin, so flagged_by must allow NULL
  `ALTER TABLE consultations ALTER COLUMN flagged_by DROP NOT NULL`,
];

(async () => {
  try {
    const db = await pool.query('SELECT current_database() AS name');
    console.log(`Connected to database: ${db.rows[0].name}\n`);

    for (const sql of STATEMENTS) {
      await pool.query(sql);
      console.log('✔', sql.replace(/\s+/g, ' '));
    }

    const cols = await pool.query(
      `SELECT column_name, data_type
         FROM information_schema.columns
        WHERE table_name = 'consultations'
          AND column_name IN ('gemini_triage','ml_triage','ml_confidence','triage_agreement','ml_model_version','flagged_by')
        ORDER BY column_name`
    );
    console.log('\nColumns now on consultations:');
    console.table(cols.rows);
    console.log('\nMigration complete ✅');
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
})();