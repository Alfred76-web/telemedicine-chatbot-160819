// Admin endpoints for the hybrid (Gemini + ML) triage — Phase 8.5
// Mounted at /api/admin/ml in server.js
const express = require('express');
const axios = require('axios');
const pool = require('../config/db');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken, verifyAdmin);

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://127.0.0.1:8000';

function handleError(res, err, label) {
  console.error(`${label}:`, err.message);
  if (err.code === '22P02') return res.status(400).json({ error: 'Invalid id.' });
  return res.status(500).json({ error: `Error loading ${label.toLowerCase()}.` });
}

// ── GET /api/admin/ml/stats ───────────────────────────────────────────────
router.get('/stats', async (req, res) => {
  try {
    const [totals, matrix, recent, service] = await Promise.all([
      pool.query(`
        SELECT
          COUNT(*) FILTER (WHERE triage_agreement IS NOT NULL)::int                      AS evaluated,
          COUNT(*) FILTER (WHERE triage_agreement = 'agree')::int                        AS agree,
          COUNT(*) FILTER (WHERE triage_agreement = 'disagree')::int                     AS disagree,
          COUNT(*) FILTER (WHERE triage_agreement = 'ml_unavailable')::int               AS ml_unavailable,
          COUNT(*) FILTER (WHERE triage_agreement = 'gemini_missing')::int               AS gemini_missing,
          COUNT(*) FILTER (WHERE gemini_triage IS NOT NULL
                             AND triage_outcome <> gemini_triage)::int                   AS escalations,
          COUNT(*) FILTER (WHERE flag_reason LIKE 'Auto-flag%')::int                     AS auto_flags,
          ROUND(AVG(ml_confidence) FILTER (WHERE ml_confidence IS NOT NULL), 4)::float  AS avg_confidence
        FROM consultations
        WHERE status = 'completed'`),
      pool.query(`
        SELECT gemini_triage, ml_triage, COUNT(*)::int AS count
        FROM consultations
        WHERE gemini_triage IS NOT NULL AND ml_triage IS NOT NULL
        GROUP BY gemini_triage, ml_triage`),
      pool.query(`
        SELECT c.id, c.started_at, c.gemini_triage, c.ml_triage, c.ml_confidence::float AS ml_confidence,
               c.triage_outcome, c.flagged, u.name AS patient_name
        FROM consultations c
        JOIN users u ON u.id = c.patient_id
        WHERE c.triage_agreement = 'disagree'
        ORDER BY c.started_at DESC
        LIMIT 5`),
      axios.get(`${ML_SERVICE_URL}/health`, { timeout: 2000 })
        .then((r) => ({ online: true, ...r.data }))
        .catch(() => ({ online: false })),
    ]);

    const t = totals.rows[0];
    const compared = t.agree + t.disagree;
    res.json({
      totals: {
        ...t,
        agreement_rate: compared ? t.agree / compared : null,
      },
      matrix: matrix.rows,
      recentDisagreements: recent.rows,
      service,
    });
  } catch (err) {
    handleError(res, err, 'ML stats');
  }
});

// ── GET /api/admin/ml/consultations/:id ───────────────────────────────────
router.get('/consultations/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, triage_outcome, gemini_triage, ml_triage, ml_confidence::float AS ml_confidence,
              triage_agreement, ml_model_version
       FROM consultations WHERE id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Consultation not found.' });
    res.json(result.rows[0]);
  } catch (err) {
    handleError(res, err, 'ML consultation details');
  }
});

module.exports = router;