const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { verifyAdmin } = require('../middleware/auth');

// Every route below requires a logged-in admin
router.use(verifyAdmin);

// ── Helpers ───────────────────────────────────────────────────────────────
async function logAdminAction(adminId, action, { targetUserId = null, targetConsultationId = null, notes = null } = {}) {
  try {
    await pool.query(
      `INSERT INTO admin_logs (admin_id, action, target_user_id, target_consultation_id, notes)
       VALUES ($1, $2, $3, $4, $5)`,
      [adminId, action, targetUserId, targetConsultationId, notes]
    );
  } catch (err) {
    console.error('Admin log error:', err.message);
  }
}

function pageParams(query) {
  const page = Math.max(parseInt(query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(query.limit, 10) || 20, 1), 100);
  return { page, limit, offset: (page - 1) * limit };
}

function handleError(res, err, label) {
  if (err.code === '22P02') return res.status(400).json({ error: 'Invalid ID or value.' });
  console.error(`Admin ${label} error:`, err.message);
  res.status(500).json({ error: `Server error (${label}).` });
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

// Builds WHERE clause for consultation filters (used by list + export)
function consultationFilters(query) {
  const conds = [`c.status = 'completed'`];
  const params = [];
  const add = (build, value) => {
    params.push(value);
    conds.push(build(`$${params.length}`));
  };

  const { from, to, triage, language, flagged, search } = query;
  if (from && DATE_RE.test(from)) add(p => `c.started_at >= ${p}::date`, from);
  if (to && DATE_RE.test(to)) add(p => `c.started_at < (${p}::date + INTERVAL '1 day')`, to);
  if (triage) add(p => `c.triage_outcome::text = ${p}`, triage);
  if (language) add(p => `c.language_used::text = ${p}`, language);
  if (flagged === 'true') conds.push('c.flagged = true');
  if (search && search.trim()) {
    add(p => `(u.name ILIKE ${p} OR u.email ILIKE ${p} OR hr.symptoms_reported ILIKE ${p})`, `%${search.trim()}%`);
  }
  return { where: `WHERE ${conds.join(' AND ')}`, params };
}

// ── DASHBOARD STATS ───────────────────────────────────────────────────────
router.get('/stats', async (req, res) => {
  try {
    const [totals, triage, language, daily] = await Promise.all([
      pool.query(`
        SELECT
          (SELECT COUNT(*) FROM users WHERE role = 'patient')::int AS patients,
          (SELECT COUNT(*) FROM users WHERE role = 'patient' AND is_active = false)::int AS inactive_patients,
          (SELECT COUNT(*) FROM consultations WHERE status = 'completed')::int AS consultations,
          (SELECT COUNT(*) FROM consultations WHERE status = 'completed' AND started_at >= CURRENT_DATE)::int AS consultations_today,
          (SELECT COUNT(*) FROM consultations WHERE triage_outcome = 'emergency')::int AS emergencies,
          (SELECT COUNT(*) FROM consultations WHERE flagged = true)::int AS flagged,
          (SELECT COUNT(*) FROM notifications WHERE status = 'sent')::int AS sms_sent
      `),
      pool.query(`
        SELECT triage_outcome::text AS name, COUNT(*)::int AS value
        FROM consultations
        WHERE status = 'completed' AND triage_outcome IS NOT NULL
        GROUP BY triage_outcome
      `),
      pool.query(`
        SELECT language_used::text AS name, COUNT(*)::int AS value
        FROM consultations
        WHERE status = 'completed'
        GROUP BY language_used
      `),
      pool.query(`
        SELECT TO_CHAR(d, 'YYYY-MM-DD') AS date, COALESCE(c.count, 0)::int AS count
        FROM generate_series(CURRENT_DATE - INTERVAL '13 days', CURRENT_DATE, INTERVAL '1 day') d
        LEFT JOIN (
          SELECT DATE(started_at) AS day, COUNT(*) AS count
          FROM consultations WHERE status = 'completed'
          GROUP BY DATE(started_at)
        ) c ON c.day = d::date
        ORDER BY d
      `),
    ]);

    res.json({
      totals: totals.rows[0],
      triage: triage.rows,
      language: language.rows,
      daily: daily.rows,
    });
  } catch (err) {
    handleError(res, err, 'stats');
  }
});

// ── USERS ─────────────────────────────────────────────────────────────────
router.get('/users', async (req, res) => {
  const { page, limit, offset } = pageParams(req.query);
  const search = (req.query.search || '').trim();
  const params = [];
  let where = '';

  if (search) {
    params.push(`%${search}%`);
    where = `WHERE u.name ILIKE $1 OR u.email ILIKE $1 OR u.phone ILIKE $1`;
  }
  params.push(limit, offset);

  try {
    const result = await pool.query(
      `SELECT u.id, u.name, u.email, u.phone, u.role, u.language_pref, u.is_active, u.created_at,
              (SELECT COUNT(*) FROM consultations c
                WHERE c.patient_id = u.id AND c.status = 'completed')::int AS consultation_count,
              COUNT(*) OVER()::int AS total_count
       FROM users u
       ${where}
       ORDER BY u.created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    res.json({
      users: result.rows.map(({ total_count, ...u }) => u),
      total: result.rows[0]?.total_count || 0,
      page,
      limit,
    });
  } catch (err) {
    handleError(res, err, 'users');
  }
});

router.patch('/users/:id/status', async (req, res) => {
  const { id } = req.params;
  const { is_active, reason } = req.body;

  if (typeof is_active !== 'boolean') {
    return res.status(400).json({ error: 'is_active must be true or false.' });
  }
  if (String(id) === String(req.user.id)) {
    return res.status(400).json({ error: 'You cannot change the status of your own account.' });
  }

  try {
    const result = await pool.query(
      `UPDATE users SET is_active = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING id, name, email, is_active`,
      [is_active, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }

    await logAdminAction(req.user.id, is_active ? 'activate_user' : 'deactivate_user', {
      targetUserId: id,
      notes: reason || null,
    });

    res.json({
      message: is_active ? 'User activated.' : 'User deactivated.',
      user: result.rows[0],
    });
  } catch (err) {
    handleError(res, err, 'user status');
  }
});

// ── CONSULTATION LOGS ─────────────────────────────────────────────────────
router.get('/consultations', async (req, res) => {
  const { page, limit, offset } = pageParams(req.query);
  const { where, params } = consultationFilters(req.query);
  params.push(limit, offset);

  try {
    const result = await pool.query(
      `SELECT c.id, c.started_at, c.language_used, c.triage_outcome, c.flagged, c.flag_reason,
              u.id AS patient_id, u.name AS patient_name, u.email AS patient_email,
              hr.symptoms_reported,
              COUNT(*) OVER()::int AS total_count
       FROM consultations c
       JOIN users u ON u.id = c.patient_id
       LEFT JOIN health_records hr ON hr.consultation_id = c.id
       ${where}
       ORDER BY c.started_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    res.json({
      consultations: result.rows.map(({ total_count, ...c }) => c),
      total: result.rows[0]?.total_count || 0,
      page,
      limit,
    });
  } catch (err) {
    handleError(res, err, 'consultations');
  }
});

// Export filtered consultations as CSV (must be defined BEFORE /:id)
router.get('/consultations/export', async (req, res) => {
  const { where, params } = consultationFilters(req.query);

  try {
    const result = await pool.query(
      `SELECT c.started_at, u.name AS patient_name, u.email AS patient_email,
              c.language_used, c.triage_outcome, c.flagged, c.flag_reason,
              hr.symptoms_reported
       FROM consultations c
       JOIN users u ON u.id = c.patient_id
       LEFT JOIN health_records hr ON hr.consultation_id = c.id
       ${where}
       ORDER BY c.started_at DESC
       LIMIT 5000`,
      params
    );

    const esc = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`;
    const header = ['Date', 'Patient', 'Email', 'Language', 'Triage', 'Flagged', 'Flag reason', 'Symptoms'];
    const rows = result.rows.map(r => [
      new Date(r.started_at).toISOString(),
      r.patient_name, r.patient_email, r.language_used, r.triage_outcome,
      r.flagged ? 'yes' : 'no', r.flag_reason, r.symptoms_reported,
    ].map(esc).join(','));

    await logAdminAction(req.user.id, 'export_report', { notes: `${result.rows.length} consultations` });

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="consultations.csv"');
    res.send([header.join(','), ...rows].join('\n'));
  } catch (err) {
    handleError(res, err, 'export');
  }
});

router.get('/consultations/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const consultation = await pool.query(
      `SELECT c.id, c.started_at, c.ended_at, c.language_used, c.triage_outcome, c.status,
              c.flagged, c.flag_reason, c.flagged_at,
              u.id AS patient_id, u.name AS patient_name, u.email AS patient_email, u.phone AS patient_phone,
              hr.symptoms_reported, hr.advice_given
       FROM consultations c
       JOIN users u ON u.id = c.patient_id
       LEFT JOIN health_records hr ON hr.consultation_id = c.id
       WHERE c.id = $1`,
      [id]
    );
    if (consultation.rows.length === 0) {
      return res.status(404).json({ error: 'Consultation not found.' });
    }

    const [messages, notifications] = await Promise.all([
      pool.query(
        `SELECT sender, content, created_at FROM messages
         WHERE consultation_id = $1 ORDER BY created_at ASC`,
        [id]
      ),
      pool.query(
        `SELECT message_content, language, status, sent_at FROM notifications
         WHERE consultation_id = $1 ORDER BY sent_at ASC`,
        [id]
      ),
    ]);

    res.json({
      consultation: consultation.rows[0],
      messages: messages.rows,
      notifications: notifications.rows,
    });
  } catch (err) {
    handleError(res, err, 'consultation detail');
  }
});

// ── FLAGGING ──────────────────────────────────────────────────────────────
router.post('/consultations/:id/flag', async (req, res) => {
  const { id } = req.params;
  const reason = (req.body.reason || '').trim();

  if (!reason) {
    return res.status(400).json({ error: 'A reason is required to flag a consultation.' });
  }

  try {
    const result = await pool.query(
      `UPDATE consultations
       SET flagged = true, flag_reason = $1, flagged_at = NOW(), flagged_by = $2
       WHERE id = $3
       RETURNING id, patient_id, flagged, flag_reason, flagged_at`,
      [reason, req.user.id, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Consultation not found.' });
    }

    await logAdminAction(req.user.id, 'flag_consultation', {
      targetUserId: result.rows[0].patient_id,
      targetConsultationId: id,
      notes: reason,
    });

    res.json({ message: 'Consultation flagged.', consultation: result.rows[0] });
  } catch (err) {
    handleError(res, err, 'flag');
  }
});

router.delete('/consultations/:id/flag', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `UPDATE consultations
       SET flagged = false, flag_reason = NULL, flagged_at = NULL, flagged_by = NULL
       WHERE id = $1
       RETURNING id, patient_id, flagged`,
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Consultation not found.' });
    }

    await logAdminAction(req.user.id, 'unflag_consultation', {
      targetUserId: result.rows[0].patient_id,
      targetConsultationId: id,
    });

    res.json({ message: 'Flag removed.', consultation: result.rows[0] });
  } catch (err) {
    handleError(res, err, 'unflag');
  }
});

// ── AUDIT LOG ─────────────────────────────────────────────────────────────
router.get('/logs', async (req, res) => {
  const { page, limit, offset } = pageParams(req.query);

  try {
    const result = await pool.query(
      `SELECT l.id, l.action, l.notes, l.created_at,
              l.target_user_id, l.target_consultation_id,
              a.name AS admin_name, tu.name AS target_user_name,
              COUNT(*) OVER()::int AS total_count
       FROM admin_logs l
       LEFT JOIN users a ON a.id = l.admin_id
       LEFT JOIN users tu ON tu.id = l.target_user_id
       ORDER BY l.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    res.json({
      logs: result.rows.map(({ total_count, ...l }) => l),
      total: result.rows[0]?.total_count || 0,
      page,
      limit,
    });
  } catch (err) {
    handleError(res, err, 'logs');
  }
});

module.exports = router;