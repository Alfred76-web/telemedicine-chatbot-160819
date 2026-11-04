// Hybrid triage: combines Gemini's triage with the project's own ML model.
//
// - The ML service (ml/app.py, FastAPI) is called with the patient's text.
// - The FINAL triage is the SAFER (more urgent) of the two opinions.
// - Disagreements are recorded and, when significant, the consultation is
//   auto-flagged for clinical review in the admin dashboard.
// - If the ML service is down, the system carries on with Gemini only.

const axios = require('axios');

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://127.0.0.1:8000';
const ML_ENABLED = process.env.ML_ENABLED !== 'false';
const ML_TIMEOUT_MS = Number(process.env.ML_TIMEOUT_MS || 4000);

// ML must be at least this confident before it can escalate Gemini's level
// or trigger a flag (an ML "emergency" always counts, for safety).
const ML_MIN_CONFIDENCE = Number(process.env.ML_MIN_CONFIDENCE || 0.5);

const SEVERITY = { 'self-care': 0, pharmacy: 1, clinic: 2, emergency: 3 };
const isLevel = (t) => Object.prototype.hasOwnProperty.call(SEVERITY, t);

async function getMlTriage(text) {
  if (!ML_ENABLED) return null;
  try {
    const { data } = await axios.post(
      `${ML_SERVICE_URL}/predict`,
      { text: String(text).slice(0, 2000) },
      { timeout: ML_TIMEOUT_MS }
    );
    if (!isLevel(data.triage)) return null;
    return {
      triage: data.triage,
      confidence: Number(data.confidence),
      probabilities: data.probabilities || {},
      emergencyRuleApplied: Boolean(data.emergency_rule_applied),
      version: data.model_version || null,
    };
  } catch (err) {
    console.warn('ML triage unavailable:', err.code || err.message);
    return null;
  }
}

/**
 * @param {string|null} geminiTriage  level parsed from Gemini's TRIAGE line
 * @param {object|null} ml            result of getMlTriage()
 * @returns {{finalTriage, geminiTriage, mlTriage, mlConfidence, mlVersion,
 *            agreement, escalatedByMl, flag, flagReason}}
 */
function combineTriage(geminiTriage, ml) {
  const gemini = isLevel(geminiTriage) ? geminiTriage : null;

  const base = {
    geminiTriage: gemini,
    mlTriage: ml ? ml.triage : null,
    mlConfidence: ml ? ml.confidence : null,
    mlVersion: ml ? ml.version : null,
    escalatedByMl: false,
    flag: false,
    flagReason: null,
  };

  // ML service down: Gemini only
  if (!ml) {
    return { ...base, finalTriage: gemini || 'clinic', agreement: 'ml_unavailable' };
  }

  // Gemini gave no usable level: use ML
  if (!gemini) {
    return {
      ...base,
      finalTriage: ml.triage,
      agreement: 'gemini_missing',
      flag: true,
      flagReason: `Auto-flag: Gemini returned no triage level; ML model chose ${ml.triage} (${pct(ml.confidence)}).`,
    };
  }

  if (gemini === ml.triage) {
    return { ...base, finalTriage: gemini, agreement: 'agree' };
  }

  // They disagree
  const mlTrusted = ml.triage === 'emergency' || ml.confidence >= ML_MIN_CONFIDENCE;
  const mlMoreUrgent = SEVERITY[ml.triage] > SEVERITY[gemini];
  const escalate = mlMoreUrgent && mlTrusted;
  const involvesEmergency = gemini === 'emergency' || ml.triage === 'emergency';
  // Low-confidence, non-emergency disagreements are recorded but not flagged
  const flag = mlTrusted || involvesEmergency;

  return {
    ...base,
    finalTriage: escalate ? ml.triage : gemini,
    agreement: 'disagree',
    escalatedByMl: escalate,
    flag,
    flagReason: flag
      ? `Auto-flag: AI/ML disagreement. Gemini: ${gemini}, ML model: ${ml.triage} (${pct(ml.confidence)}). ` +
        (escalate ? `Escalated to ${ml.triage} for safety.` : `Kept ${gemini}.`)
      : null,
  };
}

// Extra line added to the chatbot reply when the ML model raised the level
function escalationNote(finalTriage, language) {
  const notes = {
    en: {
      pharmacy: 'Safety check: based on an additional assessment, we recommend speaking to a pharmacist about these symptoms.',
      clinic: 'Safety check: based on an additional assessment, we recommend visiting a clinic or health centre to be examined.',
      emergency: 'Safety check: these symptoms may be serious. Please go to the nearest hospital or call 999 / 112 now.',
    },
    sw: {
      pharmacy: 'Ukaguzi wa usalama: kutokana na tathmini ya ziada, tunashauri uzungumze na mfamasia kuhusu dalili hizi.',
      clinic: 'Ukaguzi wa usalama: kutokana na tathmini ya ziada, tunashauri utembelee kliniki au kituo cha afya ili upimwe.',
      emergency: 'Ukaguzi wa usalama: dalili hizi zinaweza kuwa hatari. Tafadhali nenda hospitali iliyo karibu au piga 999 / 112 sasa.',
    },
  };
  return (notes[language] || notes.en)[finalTriage] || '';
}

function pct(x) {
  return `${Math.round(Number(x) * 100)}%`;
}

module.exports = { getMlTriage, combineTriage, escalationNote, SEVERITY };
