import { useState } from 'react';
import { X } from 'lucide-react';

export default function FlagDialog({ onCancel, onConfirm, busy, error }) {
  const [reason, setReason] = useState('');

  return (
    <div className="modal-backdrop" onClick={busy ? undefined : onCancel}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>Flag for clinical review</h3>
          <button className="icon-btn" onClick={onCancel} disabled={busy}><X size={18} /></button>
        </div>

        <p className="muted">
          Flag this consultation if the AI advice or triage level looks wrong or unsafe. The reason is saved
          with the consultation and in the audit log.
        </p>

        <label className="field-label" htmlFor="flag-reason">Reason *</label>
        <textarea
          id="flag-reason"
          className="textarea"
          rows={3}
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          placeholder="e.g. Chest pain was triaged as pharmacy, should be emergency"
          disabled={busy}
          autoFocus
        />

        {error && <div className="alert alert-error">{error}</div>}

        <div className="modal-actions">
          <button className="btn btn-outline" onClick={onCancel} disabled={busy}>Cancel</button>
          <button
            className="btn btn-warning"
            onClick={() => onConfirm(reason.trim())}
            disabled={busy || reason.trim().length < 3}
          >
            {busy ? 'Saving…' : 'Flag consultation'}
          </button>
        </div>
      </div>
    </div>
  );
}