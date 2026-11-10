import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { CheckCircle2, ShieldAlert, Flag, Cpu } from 'lucide-react';
import api, { errorMessage } from '../api';
import StatCard from './StatCard';
import TriageBadge from './TriageBadge';
import { TRIAGE, formatDateTime } from '../utils/triage';

const LEVELS = Object.keys(TRIAGE);

export default function HybridTriagePanel({ refreshKey }) {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    api.get('/admin/ml/stats')
      .then((res) => { if (!cancelled) { setData(res.data); setError(''); } })
      .catch((err) => { if (!cancelled) setError(errorMessage(err)); });
    return () => { cancelled = true; };
  }, [refreshKey]);

  if (error) return <div className="alert alert-error">Hybrid triage stats: {error}</div>;
  if (!data) return <div className="card empty">Loading hybrid triage stats…</div>;

  const { totals, matrix, recentDisagreements, service } = data;
  const rate = totals.agreement_rate == null ? '—' : `${Math.round(totals.agreement_rate * 100)}%`;
  const cell = (g, m) => matrix.find((r) => r.gemini_triage === g && r.ml_triage === m)?.count || 0;
  const compared = totals.agree + totals.disagree;

  return (
    <div className="card hybrid-panel">
      <div className="card-header">
        <div>
          <h3 className="card-title">Hybrid triage: Gemini vs ML model</h3>
          <p className="muted small-text">
            {totals.evaluated} consultations checked by both systems since the ML model went live
          </p>
        </div>
      </div>

      <div className="stats-grid">
        <StatCard icon={CheckCircle2} label="AI / ML agreement" value={rate} color="#2e7d32"
          hint={`${totals.agree} of ${compared} compared`} />
        <StatCard icon={ShieldAlert} label="Safety escalations by ML" value={totals.escalations} color="#c62828"
          hint="ML raised Gemini's level" />
        <StatCard icon={Flag} label="Auto-flagged for review" value={totals.auto_flags} color="#ef6c00"
          hint={`${totals.ml_unavailable} without ML (service off)`} />
        <StatCard icon={Cpu} label="ML service"
          value={service.online ? 'Online' : 'Offline'}
          color={service.online ? '#01579b' : '#6b7a83'}
          hint={service.online
            ? `${service.model} · v${service.version}`
            : 'Start uvicorn on port 8000'} />
      </div>

      <div className="hybrid-grid">
        <div>
          <h4 className="sub-title">Agreement matrix</h4>
          {compared === 0 ? (
            <div className="chart-empty small">No consultations with both opinions yet</div>
          ) : (
            <div className="table-wrap">
              <table className="matrix">
                <thead>
                  <tr>
                    <th className="matrix-corner">Gemini ↓ / ML →</th>
                    {LEVELS.map((m) => <th key={m}>{TRIAGE[m].label}</th>)}
                  </tr>
                </thead>
                <tbody>
                  {LEVELS.map((g) => (
                    <tr key={g}>
                      <th>{TRIAGE[g].label}</th>
                      {LEVELS.map((m) => {
                        const n = cell(g, m);
                        const cls = n === 0 ? 'zero' : g === m ? 'agree' : 'disagree';
                        return <td key={m} className={`matrix-cell ${cls}`}>{n}</td>;
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          <p className="muted small-text">Green diagonal = both agreed. Orange = disagreement.</p>
        </div>

        <div>
          <h4 className="sub-title">Recent disagreements</h4>
          {recentDisagreements.length === 0 ? (
            <div className="chart-empty small">No disagreements yet</div>
          ) : (
            <ul className="disagree-list">
              {recentDisagreements.map((d) => (
                <li key={d.id}>
                  <Link to={`/consultations/${d.id}`} className="disagree-row">
                    <div>
                      <div className="cell-strong">#{d.id} · {d.patient_name}</div>
                      <div className="cell-sub">{formatDateTime(d.started_at)}</div>
                    </div>
                    <div className="disagree-badges">
                      <span className="cell-sub">Gemini</span> <TriageBadge triage={d.gemini_triage} />
                      <span className="cell-sub">ML</span> <TriageBadge triage={d.ml_triage} />
                      {d.flagged && <Flag size={15} className="flag-icon" />}
                    </div>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </div>
  );
}