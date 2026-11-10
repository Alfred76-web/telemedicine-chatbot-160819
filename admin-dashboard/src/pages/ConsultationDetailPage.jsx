import { useCallback, useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  ArrowLeft, Flag, FlagOff, User, Bot, Phone, Mail, Clock, Languages, MessageSquareText,
} from 'lucide-react';
import api, { errorMessage } from '../api';
import TriageBadge from '../components/TriageBadge';
import FlagDialog from '../components/FlagDialog';
import HybridTriageCard from '../components/HybridTriageCard';
import { LANGUAGE_LABELS, formatDateTime } from '../utils/triage';

const isPatient = (m) => ['patient', 'user'].includes((m.sender || m.sender_type || m.role || '').toLowerCase());
const msgText = (m) => m.content || m.message || m.text || '';
const msgTime = (m) => m.sent_at || m.created_at || m.timestamp;

function duration(start, end) {
  if (!start || !end) return '—';
  const secs = Math.max(0, Math.round((new Date(end) - new Date(start)) / 1000));
  return secs < 60 ? `${secs}s` : `${Math.floor(secs / 60)}m ${secs % 60}s`;
}

export default function ConsultationDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [refreshKey, setRefreshKey] = useState(0);

  const [flagOpen, setFlagOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    setRefreshKey((k) => k + 1);
    try {
      const res = await api.get(`/admin/consultations/${id}`);
      setData(res.data);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    if (!toast) return undefined;
    const t = setTimeout(() => setToast(''), 3000);
    return () => clearTimeout(t);
  }, [toast]);

  async function flag(reason) {
    setBusy(true);
    setActionError('');
    try {
      await api.post(`/admin/consultations/${id}/flag`, { reason });
      setFlagOpen(false);
      setToast('Consultation flagged for review.');
      await load();
    } catch (err) {
      setActionError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  async function unflag() {
    setBusy(true);
    setActionError('');
    try {
      await api.delete(`/admin/consultations/${id}/flag`);
      setToast('Flag removed.');
      await load();
    } catch (err) {
      setActionError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  const goBack = () => (window.history.length > 1 ? navigate(-1) : navigate('/consultations'));

  if (loading && !data) {
    return <div className="page"><div className="card empty">Loading consultation…</div></div>;
  }
  if (error && !data) {
    return (
      <div className="page">
        <button className="btn btn-outline back-btn" onClick={goBack}><ArrowLeft size={16} /> Back</button>
        <div className="alert alert-error">{error}</div>
      </div>
    );
  }

  const c = data.consultation || data;
  const messages = data.messages || [];
  const notifications = data.notifications || [];
  const autoFlag = (c.flag_reason || '').startsWith('Auto-flag');

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <button className="btn btn-outline back-btn" onClick={goBack}><ArrowLeft size={16} /> Back</button>
          <h1>Consultation #{c.id}</h1>
          <p className="muted">{formatDateTime(c.started_at)}</p>
        </div>
        <div className="header-actions">
          {c.flagged ? (
            <button className="btn btn-outline" onClick={unflag} disabled={busy}>
              <FlagOff size={16} /> {busy ? 'Saving…' : 'Remove flag'}
            </button>
          ) : (
            <button className="btn btn-warning" onClick={() => { setActionError(''); setFlagOpen(true); }}>
              <Flag size={16} /> Flag for review
            </button>
          )}
        </div>
      </div>

      {toast && <div className="alert alert-success">{toast}</div>}
      {actionError && !flagOpen && <div className="alert alert-error">{actionError}</div>}

      {c.flagged && (
        <div className="flag-banner">
          <Flag size={18} />
          <div>
            <strong>{autoFlag ? 'Automatically flagged by the hybrid triage check' : 'Flagged for clinical review'}</strong>
            <div>{c.flag_reason || 'No reason given'}</div>
            {c.flagged_at && <div className="cell-sub">Flagged {formatDateTime(c.flagged_at)}</div>}
          </div>
        </div>
      )}

      <div className="detail-grid">
        {/* ── Transcript ── */}
        <div className="card">
          <h3 className="card-title">Conversation transcript</h3>
          {messages.length === 0 ? (
            <div className="chart-empty small">No messages saved</div>
          ) : (
            <div className="transcript">
              {messages.map((m, i) => {
                const mine = isPatient(m);
                return (
                  <div key={m.id || i} className={`msg ${mine ? 'msg-patient' : 'msg-bot'}`}>
                    <div className="msg-avatar">{mine ? <User size={16} /> : <Bot size={16} />}</div>
                    <div className="msg-body">
                      <div className="msg-bubble">{msgText(m)}</div>
                      <div className="msg-meta">
                        {mine ? 'Patient' : 'AI assistant'} · {formatDateTime(msgTime(m))}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* ── Side panel ── */}
        <div className="side-col">
          <div className="card">
            <h3 className="card-title">Triage result</h3>
            <div className="triage-big"><TriageBadge triage={c.triage_outcome} /></div>
            <dl className="info-list">
              <div><dt><Languages size={14} /> Language</dt><dd>{LANGUAGE_LABELS[c.language_used] || c.language_used || '—'}</dd></div>
              <div><dt><Clock size={14} /> Duration</dt><dd>{duration(c.started_at, c.ended_at)}</dd></div>
              <div><dt>Status</dt><dd className="capitalize">{c.status || '—'}</dd></div>
            </dl>
          </div>

          <HybridTriageCard id={id} refreshKey={refreshKey} />

          <div className="card">
            <h3 className="card-title">Patient</h3>
            <div className="cell-strong patient-name">{c.patient_name || '—'}</div>
            <dl className="info-list">
              <div><dt><Mail size={14} /> Email</dt><dd>{c.patient_email || '—'}</dd></div>
              <div><dt><Phone size={14} /> Phone</dt><dd>{c.patient_phone || c.phone_number || '—'}</dd></div>
              {c.gender && <div><dt>Gender</dt><dd className="capitalize">{c.gender}</dd></div>}
              {c.age != null && <div><dt>Age</dt><dd>{c.age}</dd></div>}
            </dl>
          </div>

          <div className="card">
            <h3 className="card-title"><MessageSquareText size={16} /> SMS notifications</h3>
            {notifications.length === 0 ? (
              <div className="cell-sub">No SMS sent for this consultation</div>
            ) : (
              <ul className="sms-list">
                {notifications.map((n, i) => (
                  <li key={n.id || i}>
                    <span className={`status ${n.status === 'sent' ? 'status-on' : 'status-off'}`}>
                      {n.status}
                    </span>
                    <span className="cell-sub">{formatDateTime(n.sent_at || n.created_at)}</span>
                    {(n.message || n.content) && <p className="sms-text">{n.message || n.content}</p>}
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      </div>

      {flagOpen && (
        <FlagDialog
          busy={busy}
          error={actionError}
          onCancel={() => setFlagOpen(false)}
          onConfirm={flag}
        />
      )}
    </div>
  );
}