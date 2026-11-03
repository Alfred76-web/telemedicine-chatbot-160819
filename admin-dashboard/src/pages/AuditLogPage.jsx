import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  RefreshCw, Search, X, LogIn, UserX, UserCheck, Flag, FlagOff, Download, Activity, ShieldCheck,
} from 'lucide-react';
import api, { errorMessage } from '../api';
import { formatDateTime } from '../utils/triage';

const PAGE_SIZE = 20;

const ACTIONS = {
  login:               { label: 'Admin login',          icon: LogIn,     color: '#01579b', bg: '#e3f2fd' },
  deactivate_user:     { label: 'Deactivated user',     icon: UserX,     color: '#c62828', bg: '#ffebee' },
  activate_user:       { label: 'Activated user',       icon: UserCheck, color: '#2e7d32', bg: '#e8f5e9' },
  flag_consultation:   { label: 'Flagged consultation', icon: Flag,      color: '#ef6c00', bg: '#fff3e0' },
  unflag_consultation: { label: 'Removed flag',         icon: FlagOff,   color: '#6d4c41', bg: '#efebe9' },
  export_report:       { label: 'Exported CSV report',  icon: Download,  color: '#6a1b9a', bg: '#f3e5f5' },
};

const actionInfo = (a) =>
  ACTIONS[a] || { label: (a || 'unknown').replace(/_/g, ' '), icon: Activity, color: '#546e7a', bg: '#eceff1' };

// Accept slightly different field names from the API
function normalize(l) {
  let details = l.details ?? l.detail ?? l.description ?? l.metadata ?? null;
  if (typeof details === 'string') {
    try { details = JSON.parse(details); } catch { /* plain text, keep as is */ }
  }
  return {
    id: l.id,
    action: l.action,
    adminName: l.admin_name || l.full_name || 'Admin',
    adminEmail: l.admin_email || l.email || '',
    targetUserId: l.target_user_id,
    targetUserName: l.target_user_name || l.target_name || null,
    targetConsultationId: l.target_consultation_id,
    details,
    createdAt: l.created_at || l.timestamp,
  };
}

function DetailsCell({ details }) {
  if (details == null || details === '') return <span className="cell-sub">—</span>;
  if (typeof details !== 'object') return <span className="log-details">{String(details)}</span>;

  const entries = Object.entries(details).filter(([, v]) => v !== null && v !== '' && v !== undefined);
  if (entries.length === 0) return <span className="cell-sub">—</span>;
  return (
    <div className="log-details">
      {entries.map(([k, v]) => (
        <div key={k}>
          <span className="log-key">{k.replace(/_/g, ' ')}:</span>{' '}
          {typeof v === 'object' ? JSON.stringify(v) : String(v)}
        </div>
      ))}
    </div>
  );
}

export default function AuditLogPage() {
  const [logs, setLogs] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [action, setAction] = useState('');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/admin/logs', {
        params: { page, limit: PAGE_SIZE, action: action || undefined },
      });
      const data = res.data;
      const list = Array.isArray(data) ? data : data.logs || [];
      setLogs(list.map(normalize));
      setTotal(Number(data.total ?? list[0]?.total_count ?? list.length));
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }, [page, action]);

  useEffect(() => { load(); }, [load]);

  // Filter on this page too, in case the API ignores the action param
  const visible = useMemo(() => {
    const q = search.trim().toLowerCase();
    return logs.filter((l) => {
      if (action && l.action !== action) return false;
      if (!q) return true;
      return [l.adminName, l.adminEmail, l.targetUserName, actionInfo(l.action).label, JSON.stringify(l.details)]
        .filter(Boolean)
        .some((s) => s.toLowerCase().includes(q));
    });
  }, [logs, action, search]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h1>Audit log</h1>
          <p className="muted">Every administrative action, for accountability and data-protection compliance</p>
        </div>
        <button className="btn btn-outline" onClick={load} disabled={loading}>
          <RefreshCw size={16} className={loading ? 'spin' : ''} /> Refresh
        </button>
      </div>

      <div className="card">
        <div className="filters">
          <div className="search-box">
            <Search size={16} />
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search admin, user or details…" />
            {search && <button className="icon-btn" onClick={() => setSearch('')}><X size={14} /></button>}
          </div>
          <label className="filter">
            <span>Action</span>
            <select value={action} onChange={(e) => { setAction(e.target.value); setPage(1); }}>
              <option value="">All actions</option>
              {Object.entries(ACTIONS).map(([key, a]) => <option key={key} value={key}>{a.label}</option>)}
            </select>
          </label>
        </div>

        <div className="result-count muted">
          <ShieldCheck size={14} style={{ verticalAlign: '-2px' }} />{' '}
          {loading ? 'Loading…' : `${total} recorded action${total === 1 ? '' : 's'}`}
        </div>

        {error ? (
          <div className="alert alert-error">{error}</div>
        ) : !loading && visible.length === 0 ? (
          <div className="chart-empty small">No audit entries found</div>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>When</th>
                  <th>Action</th>
                  <th>Admin</th>
                  <th>Target</th>
                  <th>Details</th>
                </tr>
              </thead>
              <tbody>
                {visible.map((l) => {
                  const info = actionInfo(l.action);
                  const Icon = info.icon;
                  return (
                    <tr key={l.id}>
                      <td className="nowrap cell-sub">{formatDateTime(l.createdAt)}</td>
                      <td>
                        <span className="log-action" style={{ color: info.color, background: info.bg }}>
                          <Icon size={14} /> {info.label}
                        </span>
                      </td>
                      <td>
                        <div className="cell-strong">{l.adminName}</div>
                        {l.adminEmail && <div className="cell-sub">{l.adminEmail}</div>}
                      </td>
                      <td className="nowrap">
                        {l.targetConsultationId ? (
                          <Link className="link" to={`/consultations/${l.targetConsultationId}`}>
                            Consultation #{l.targetConsultationId}
                          </Link>
                        ) : l.targetUserId ? (
                          <span>{l.targetUserName || `User #${l.targetUserId}`}</span>
                        ) : (
                          <span className="cell-sub">—</span>
                        )}
                      </td>
                      <td><DetailsCell details={l.details} /></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {totalPages > 1 && (
          <div className="pagination">
            <button className="btn btn-sm btn-outline" disabled={page <= 1 || loading} onClick={() => setPage((p) => p - 1)}>
              ← Previous
            </button>
            <span className="muted">Page {page} of {totalPages}</span>
            <button className="btn btn-sm btn-outline" disabled={page >= totalPages || loading} onClick={() => setPage((p) => p + 1)}>
              Next →
            </button>
          </div>
        )}
      </div>
    </div>
  );
}