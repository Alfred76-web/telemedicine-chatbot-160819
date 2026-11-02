const AfricasTalking = require('africastalking');
const pool = require('../config/db');
require('dotenv').config();

const at = AfricasTalking({
  username: process.env.AT_USERNAME,
  apiKey: process.env.AT_API_KEY,
});
const sms = at.SMS;

// ── Message text (kept GSM-safe & short: ~2 SMS max) ──────────────────────
const TEXT = {
  en: {
    labels: {
      'self-care': 'Self-care',
      pharmacy: 'Visit a pharmacy',
      clinic: 'Visit a clinic',
    },
    actions: {
      'self-care': 'Rest, drink fluids and monitor your symptoms.',
      pharmacy: 'A pharmacist can advise you on treatment.',
      clinic: 'Please visit a clinic or health centre within 24 hours.',
    },
    normal: ({ first, date, label, action, symptoms }) =>
      `Telemed: Hi ${first}, result of your ${date} consultation: ${label}. ${action} Symptoms: "${symptoms}". This is AI advice, not a diagnosis. Emergency? Call 999.`,
    emergency: ({ first, symptoms }) =>
      `URGENT - Telemed: ${first}, your symptoms ("${symptoms}") may need EMERGENCY care. Call 999 or go to the nearest hospital NOW.`,
  },
  sw: {
    labels: {
      'self-care': 'Kujitunza',
      pharmacy: 'Tembelea duka la dawa',
      clinic: 'Tembelea kliniki',
    },
    actions: {
      'self-care': 'Pumzika, kunywa maji na ufuatilie dalili zako.',
      pharmacy: 'Mfamasia anaweza kukushauri kuhusu matibabu.',
      clinic: 'Tafadhali tembelea kliniki au kituo cha afya ndani ya saa 24.',
    },
    normal: ({ first, date, label, action, symptoms }) =>
      `Telemed: Habari ${first}, matokeo ya mashauriano ya ${date}: ${label}. ${action} Dalili: "${symptoms}". Huu ni ushauri wa AI, si utambuzi. Dharura? Piga 999.`,
    emergency: ({ first, symptoms }) =>
      `DHARURA - Telemed: ${first}, dalili zako ("${symptoms}") zinaweza kuhitaji huduma ya DHARURA. Piga 999 au nenda hospitali iliyo karibu SASA.`,
  },
};

function cleanForSMS(text, max) {
  const plain = (text || '').replace(/[^\x20-\x7E]/g, '').replace(/\s+/g, ' ').trim();
  return plain.length > max ? plain.slice(0, max - 3) + '...' : plain;
}

// ── buildSMSMessage ───────────────────────────────────────────────────────
function buildSMSMessage({ name, triage, symptoms, language }) {
  const lang = language === 'sw' ? 'sw' : 'en';
  const t = TEXT[lang];
  const first = cleanForSMS((name || '').split(' ')[0], 20) || (lang === 'sw' ? 'Mgonjwa' : 'Patient');
  const shortSymptoms = cleanForSMS(symptoms, 50);
  const date = new Date().toLocaleDateString('en-GB', { timeZone: 'Africa/Nairobi' });

  if (triage === 'emergency') {
    return t.emergency({ first, symptoms: shortSymptoms });
  }
  const key = t.labels[triage] ? triage : 'clinic';
  return t.normal({
    first,
    date,
    label: t.labels[key],
    action: t.actions[key],
    symptoms: shortSymptoms,
  });
}

// ── logNotification ───────────────────────────────────────────────────────
async function logNotification({ patientId, consultationId, message, language, status }) {
  try {
    await pool.query(
      `INSERT INTO notifications (patient_id, consultation_id, message_content, language, status, sent_at)
       VALUES ($1, $2, $3, $4, $5, NOW())`,
      [patientId, consultationId || null, message, language === 'sw' ? 'sw' : 'en', status]
    );
  } catch (err) {
    console.error('Notification log error:', err.message);
  }
}

// ── sendSMS (+ log) ───────────────────────────────────────────────────────
async function sendConsultationSMS({ patientId, consultationId, name, phone, triage, symptoms, language }) {
  if (process.env.SMS_ENABLED === 'false') return { sent: false, reason: 'disabled' };
  if (!phone || !/^\+254[17]\d{8}$/.test(phone)) {
    console.warn(`SMS skipped: invalid phone "${phone}" for patient ${patientId}`);
    return { sent: false, reason: 'invalid phone' };
  }

  const message = buildSMSMessage({ name, triage, symptoms, language });
  let status = 'failed';

  try {
    const params = { to: [phone], message };
    if (process.env.AT_SENDER_ID) params.from = process.env.AT_SENDER_ID;

    const res = await sms.send(params);
    const recipient = res?.SMSMessageData?.Recipients?.[0];
    if (recipient && (recipient.statusCode === 101 || recipient.status === 'Success')) {
      status = 'sent';
    } else {
      console.warn('SMS not accepted:', JSON.stringify(res?.SMSMessageData));
    }
  } catch (err) {
    console.error('SMS error:', err.message || err);
  }

  await logNotification({ patientId, consultationId, message, language, status });
  return { sent: status === 'sent' };
}

module.exports = { buildSMSMessage, sendConsultationSMS, logNotification };