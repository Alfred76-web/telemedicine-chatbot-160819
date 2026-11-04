const express = require('express');
const router = express.Router();
const axios = require('axios');
const pool = require('../config/db');
const { verifyToken } = require('../middleware/auth');
const { sendConsultationSMS } = require('../services/smsService');
const { getMlTriage, combineTriage, escalationNote } = require('../services/mlTriageService');
require('dotenv').config();

// ── GEMINI MODELS (main first, backups after) — set in .env ───────────────
const GEMINI_MODELS = (process.env.GEMINI_MODELS || 'gemini-3.8-flash')
  .split(',').map(m => m.trim()).filter(Boolean);

// ── SYSTEM PROMPT ─────────────────────────────────────────────────────────
const SYSTEM_PROMPT = `You are a primary healthcare assistant for patients in Kenya. 
Your role is to help patients understand their symptoms and decide on the appropriate 
level of care. You only handle the following conditions: malaria, typhoid fever, 
respiratory infections, hypertension, type 2 diabetes, and urinary tract infections.

Always respond in the language you are instructed to use below.

Write in plain text only. Do not use markdown formatting such as ** or #. 
If you list items, start each line with "- ". Keep the response clear and concise.

At the end of every response, you MUST include a triage classification on its own line 
in exactly this format:
TRIAGE: self-care
or
TRIAGE: pharmacy
or
TRIAGE: clinic
or
TRIAGE: emergency

If the patient describes symptoms outside your defined scope, respond with:
"I am sorry, I can only assist with primary care conditions such as malaria, typhoid, 
respiratory infections, hypertension, diabetes, and UTIs. Please visit your nearest 
health facility for other concerns."
And classify as: TRIAGE: clinic

Never prescribe specific drug dosages. Never claim to be a human doctor. 
Always remind the patient that this is an AI assistant and not a substitute 
for emergency medical care.`;

// ── LANGUAGE DETECTION ────────────────────────────────────────────────────
const SWAHILI_WORDS = new Set([
  'nina', 'maumivu', 'homa', 'dawa', 'mganga', 'hospitali', 'dalili', 'niko', 'mimi',
  'kichwa', 'tumbo', 'kifua', 'baridi', 'joto', 'kukohoa', 'kupumua', 'kuumwa', 'ndiyo',
  'hapana', 'tafadhali', 'asante', 'sawa', 'pole', 'sana', 'na', 'ya', 'kwa', 'siku',
  'wiki', 'mwili', 'ninahisi', 'nahisi', 'najisikia', 'nimekuwa', 'kuharisha', 'kutapika',
  'kizunguzungu', 'uchovu', 'mgonjwa', 'damu', 'mkojo', 'koo', 'kikohozi', 'mafua',
  'jana', 'leo', 'tangu', 'mbili', 'tatu', 'sukari', 'presha', 'shinikizo', 'kali'
]);

const ENGLISH_WORDS = new Set([
  'i', 'have', 'has', 'had', 'my', 'the', 'and', 'is', 'am', 'a', 'an', 'pain', 'fever',
  'headache', 'head', 'stomach', 'cough', 'chest', 'since', 'for', 'days', 'day', 'week',
  'feel', 'feeling', 'with', 'of', 'been', 'sore', 'throat', 'vomiting', 'diarrhea',
  'tired', 'dizzy', 'blood', 'pressure', 'sugar', 'urine', 'body', 'severe'
]);

function detectLanguage(text, fallback = 'en') {
  const words = text.toLowerCase().match(/[a-z']+/g) || [];
  let sw = 0;
  let en = 0;
  for (const w of words) {
    if (SWAHILI_WORDS.has(w)) sw++;
    if (ENGLISH_WORDS.has(w)) en++;
  }
  if (sw > en) return 'sw';
  if (en > sw) return 'en';
  return fallback;
}

// ── EXTRACT TRIAGE FROM RESPONSE ──────────────────────────────────────────
// Returns null when Gemini gives no TRIAGE line, so the hybrid logic can
// fall back to the ML model (and flag it) instead of silently using 'clinic'.
function extractTriage(responseText) {
  const match = responseText.match(/TRIAGE:\s*(self-care|pharmacy|clinic|emergency)/i);
  return match ? match[1].toLowerCase() : null;
}

// ── HELPERS ───────────────────────────────────────────────────────────────
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
const withTimeout = (promise, ms, fallback) =>
  Promise.race([promise, new Promise(r => setTimeout(() => r(fallback), ms))]);

// ── CALL GEMINI: RETRY ON BUSY/NETWORK ERRORS, THEN FALL BACK TO NEXT MODEL ──
async function callGemini(body) {
  const retryableStatus = [429, 500, 503, 504];
  const retryableCodes = ['ECONNRESET', 'ETIMEDOUT', 'ECONNABORTED', 'EAI_AGAIN', 'ENOTFOUND', 'ECONNREFUSED'];
  let lastError;

  for (const model of GEMINI_MODELS) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${process.env.GEMINI_API_KEY}`;

    for (let attempt = 1; attempt <= 2; attempt++) {
      try {
        const res = await axios.post(url, body, { timeout: 30000 });
        if (model !== GEMINI_MODELS[0] || attempt > 1) {
          console.log(`Gemini succeeded with ${model} (attempt ${attempt})`);
        }
        return res;
      } catch (err) {
        lastError = err;
        const status = err.response?.status;
        const retryable = status ? retryableStatus.includes(status) : retryableCodes.includes(err.code);
        if (!retryable) throw err;
        console.warn(`Gemini ${model} attempt ${attempt} failed (${status || err.code})`);
        if (attempt < 2) await sleep(1500);
      }
    }
    console.warn(`Model ${model} unavailable, trying next model...`);
  }
  throw lastError;
}

// ── START CONSULTATION ────────────────────────────────────────────────────
router.post('/start', verifyToken, async (req, res) => {
  const { symptoms, language } = req.body;
  const patientId = req.user.id;
  let consultationId = null;

  if (!symptoms || !symptoms.trim()) {
    return res.status(400).json({ error: 'Symptoms are required.' });
  }

  try {
    // 1. Detect language (falls back to the patient's preference)
    const fallbackLanguage = ['en', 'sw'].includes(language)
      ? language
      : (req.user.language || 'en');
    const detectedLanguage = detectLanguage(symptoms, fallbackLanguage);
    const languageName = detectedLanguage === 'sw' ? 'Kiswahili' : 'English';

    // 1b. Ask the ML triage model now, so it runs at the same time as Gemini.
    //     getMlTriage never throws: it resolves to null if the ML service is down.
    const mlPromise = getMlTriage(symptoms);

    // 2. Create consultation record
    const consultation = await pool.query(
      `INSERT INTO consultations (patient_id, language_used, status)
       VALUES ($1, $2, 'active')
       RETURNING id, started_at`,
      [patientId, detectedLanguage]
    );
    consultationId = consultation.rows[0].id;

    // 3. Load last 3 health records for context
    const history = await pool.query(
      `SELECT symptoms_reported, triage_outcome, advice_given, created_at
       FROM health_records
       WHERE patient_id = $1
       ORDER BY created_at DESC
       LIMIT 3`,
      [patientId]
    );

    // 4. Build context from profile + history
    const profile = await pool.query(
      `SELECT gender, chronic_conditions,
              DATE_PART('year', AGE(date_of_birth))::int AS age
       FROM patient_profiles WHERE user_id = $1`,
      [patientId]
    );

    let historyContext = '';
    const p = profile.rows[0];
    if (p && (p.age || p.gender || p.chronic_conditions)) {
      historyContext += '\n\nPatient profile (for context only):\n';
      if (p.age) historyContext += `- Age: ${p.age}\n`;
      if (p.gender) historyContext += `- Gender: ${p.gender}\n`;
      if (p.chronic_conditions) historyContext += `- Known chronic conditions: ${p.chronic_conditions}\n`;
    }

    if (history.rows.length > 0) {
      historyContext += '\nPatient prior consultation history (for context only):\n';
      history.rows.forEach((record, i) => {
        historyContext += `${i + 1}. Symptoms: ${record.symptoms_reported} | Triage: ${record.triage_outcome} | Date: ${record.created_at.toDateString()}\n`;
      });
    }

    // 5. Save patient message
    await pool.query(
      `INSERT INTO messages (consultation_id, sender, content)
       VALUES ($1, 'patient', $2)`,
      [consultationId, symptoms]
    );

    // 6. Call Gemini API (with retry + model fallback)
    const geminiResponse = await callGemini({
      contents: [
        {
          role: 'user',
          parts: [{
            text: `${SYSTEM_PROMPT}${historyContext}\n\nRespond in ${languageName}.\n\nPatient symptoms: ${symptoms}`
          }]
        }
      ],
      generationConfig: {
        temperature: 0.3,
        maxOutputTokens: 2048,
      }
    });

    // 7. Extract AI response safely, then clean it for display
    const parts = geminiResponse.data?.candidates?.[0]?.content?.parts || [];
    const aiText = parts.map(p => p.text || '').join('').trim();
    if (!aiText) {
      throw new Error('Gemini returned an empty response');
    }

    const geminiTriage = extractTriage(aiText);
    let cleanText = aiText
      .replace(/^\s*TRIAGE:.*$/im, '')
      .replace(/\*\*/g, '')
      .replace(/^#+\s*/gm, '')
      .replace(/^\s*\*\s+/gm, '- ')
      .trim();

    // 7b. Hybrid triage: combine Gemini with the ML model (the safer level wins)
    const ml = await mlPromise;
    const hybrid = combineTriage(geminiTriage, ml);
    const triageOutcome = hybrid.finalTriage;

    if (hybrid.escalatedByMl) {
      cleanText += `\n\n${escalationNote(triageOutcome, detectedLanguage)}`;
    }

    console.log(
      `Triage #${consultationId}: Gemini=${geminiTriage || '-'} ML=${ml ? `${ml.triage} (${Math.round(ml.confidence * 100)}%)` : 'unavailable'}` +
      ` -> final=${triageOutcome} [${hybrid.agreement}]${hybrid.flag ? ' FLAGGED' : ''}`
    );

    // 8. Save bot message
    await pool.query(
      `INSERT INTO messages (consultation_id, sender, content)
       VALUES ($1, 'bot', $2)`,
      [consultationId, cleanText]
    );

    // 9. Close consultation (with both triage opinions; auto-flag if needed) and save health record
    await pool.query(
      `UPDATE consultations
       SET status = 'completed',
           triage_outcome = $1,
           ended_at = NOW(),
           gemini_triage = $2,
           ml_triage = $3,
           ml_confidence = $4,
           triage_agreement = $5,
           ml_model_version = $6,
           flagged     = CASE WHEN $7::boolean THEN TRUE  ELSE flagged     END,
           flag_reason = CASE WHEN $7::boolean THEN $8::text ELSE flag_reason END,
           flagged_at  = CASE WHEN $7::boolean THEN NOW() ELSE flagged_at  END
       WHERE id = $9`,
      [
        triageOutcome,
        hybrid.geminiTriage,
        hybrid.mlTriage,
        hybrid.mlConfidence,
        hybrid.agreement,
        hybrid.mlVersion,
        hybrid.flag,
        hybrid.flagReason,
        consultationId,
      ]
    );

    await pool.query(
      `INSERT INTO health_records
       (patient_id, consultation_id, symptoms_reported, triage_outcome, advice_given)
       VALUES ($1, $2, $3, $4, $5)`,
      [patientId, consultationId, symptoms, triageOutcome, cleanText]
    );

    // 10. Send SMS summary (Africa's Talking) — wait max 8s so the reply isn't delayed
    const userRow = await pool.query('SELECT name, phone FROM users WHERE id = $1', [patientId]);
    const { name, phone } = userRow.rows[0] || {};
    const smsResult = await withTimeout(
      sendConsultationSMS({
        patientId,
        consultationId,
        name,
        phone,
        triage: triageOutcome,
        symptoms,
        language: detectedLanguage,
      }),
      8000,
      { sent: false, reason: 'timeout' }
    );

    // 11. Return response to patient
    res.status(200).json({
      consultationId,
      language: detectedLanguage,
      triage: triageOutcome,
      response: cleanText,
      smsSent: smsResult.sent,
      ml: {
        geminiTriage: hybrid.geminiTriage,
        mlTriage: hybrid.mlTriage,
        mlConfidence: hybrid.mlConfidence,
        agreement: hybrid.agreement,
        escalated: hybrid.escalatedByMl,
        flagged: hybrid.flag,
      }
    });

  } catch (err) {
    console.error('Consultation error:', err.message);
    if (err.response) {
      console.error('Gemini status:', err.response.status);
      console.error('Gemini said:', JSON.stringify(err.response.data, null, 2));
    }

    if (consultationId) {
      try {
        await pool.query('DELETE FROM messages WHERE consultation_id = $1', [consultationId]);
        await pool.query('DELETE FROM consultations WHERE id = $1', [consultationId]);
      } catch (cleanupErr) {
        console.error('Cleanup error:', cleanupErr.message);
      }
    }

    if ([429, 503].includes(err.response?.status)) {
      return res.status(503).json({ error: 'The AI assistant is busy right now. Please try again in a minute.' });
    }
    res.status(500).json({ error: 'Error processing consultation.' });
  }
});

// ── GET CONSULTATION HISTORY ──────────────────────────────────────────────
router.get('/history', verifyToken, async (req, res) => {
  const patientId = req.user.id;

  try {
    const result = await pool.query(
      `SELECT hr.id, hr.consultation_id, hr.symptoms_reported, hr.triage_outcome,
              hr.advice_given, hr.created_at, c.language_used
       FROM health_records hr
       JOIN consultations c ON hr.consultation_id = c.id
       WHERE hr.patient_id = $1
       ORDER BY hr.created_at DESC`,
      [patientId]
    );

    res.status(200).json({
      count: result.rows.length,
      consultations: result.rows
    });

  } catch (err) {
    console.error('History error:', err.message);
    res.status(500).json({ error: 'Error fetching consultation history.' });
  }
});

// ── GET SINGLE CONSULTATION DETAIL ────────────────────────────────────────
router.get('/:consultationId/messages', verifyToken, async (req, res) => {
  const { consultationId } = req.params;
  const patientId = req.user.id;

  try {
    const check = await pool.query(
      'SELECT id FROM consultations WHERE id = $1 AND patient_id = $2',
      [consultationId, patientId]
    );
    if (check.rows.length === 0) {
      return res.status(403).json({ error: 'Access denied.' });
    }

    const messages = await pool.query(
      `SELECT sender, content, created_at
       FROM messages
       WHERE consultation_id = $1
       ORDER BY created_at ASC`,
      [consultationId]
    );

    res.status(200).json({ messages: messages.rows });

  } catch (err) {
    console.error('Messages error:', err.message);
    res.status(500).json({ error: 'Error fetching messages.' });
  }
});

module.exports = router;