import { useEffect, useState } from 'react';
import { Cpu } from 'lucide-react';
import api from '../api';
import TriageBadge from './TriageBadge';

const AGREEMENT = {
  agree:          { label: 'Agreed',               cls: 'status-on' },
  disagree:       { label: 'Disagreed',            cls: 'status-warn' },
  ml_unavailable: { label: 'ML service was off',   cls: 'status-off' },
  gemini_missing: { label: 'Gemini gave no level', cls: 'status-warn' },
};

export default function HybridTriageCard({ id, refreshKey }) {
  const [d, setD] = useState(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    let cancelled = false;
    api.get(`/admin/ml/consultations/${id}`)
      .then((res) => { if (!cancelled) setD(res.data); })
      .catch(() => { if (!cancelled) setFailed(true); });
    return () => { cancelled = true; };
  }, [id, refreshKey]);

  return (
    <div className="card">
      <h3 className="card-title"><Cpu size={16} /> Hybrid triage</h3>

      {failed ? (
        <div className="cell-sub">Could not load hybrid triage details.</div>
      ) : !d ? (
        <div className="cell-sub">Loading…</div>
      ) : !d.triage_agreement ? (
        <div className="cell-sub">
          Not recorded. This consultation happened before the ML model was connected.
        </div>
      ) : (
        <>
          <dl className="info-list">
            <div><dt>Gemini</dt><dd>{d.gemini_triage ? <TriageBadge triage={d.gemini_triage} /> : '—'}</dd></div>
            <div><dt>ML model</dt><dd>{d.ml_triage ? <TriageBadge triage={d.ml_triage} /> : '—'}</dd></div>
            {d.ml_confidence != null && (
              <div className="confidence-row">
                <dt>ML confidence</dt>
                <dd>
                  <div className="confidence-bar">
                    <span style={{ width: `${Math.round(d.ml_confidence * 100)}%` }} />
                  </div>
                  {Math.round(d.ml_confidence * 100)}%
                </dd>
              </div>
            )}
            <div><dt>Final (safer) level</dt><dd><TriageBadge triage={d.triage_outcome} /></dd></div>
            <div>
              <dt>Result</dt>
              <dd>
                <span className={`status ${(AGREEMENT[d.triage_agreement] || {}).cls || ''}`}>
                  {(AGREEMENT[d.triage_agreement] || {}).label || d.triage_agreement}
                </span>
              </dd>
            </div>
          </dl>
          {d.gemini_triage && d.triage_outcome !== d.gemini_triage && (
            <p className="escalation-note">
              The ML model raised the level from <strong>{d.gemini_triage}</strong> to{' '}
              <strong>{d.triage_outcome}</strong> for safety.
            </p>
          )}
          {d.ml_model_version && <div className="cell-sub">Model version {d.ml_model_version}</div>}
        </>
      )}
    </div>
  );
}