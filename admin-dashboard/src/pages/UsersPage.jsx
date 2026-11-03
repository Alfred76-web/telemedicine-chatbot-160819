import { useCallback, useEffect, useMemo, useState } from 'react';
import { Search, RefreshCw, UserCheck, UserX, ShieldCheck, X } from 'lucide-react';
import api, { errorMessage } from '../api';
import { LANGUAGE_LABELS, formatDateTime } from '../utils/triage';

const PAGE_SIZE = 15;

// Works with slightly different field names from the API
function normalize(u) {
  return {
    id: u.id,
    name: u.full_name || u.name || '—',
    email: u.email || '—',
    phone: u.phone_number || u.phone || '—',
    role: u.role || 'patient',
    language: u.language_pref || u.language_preference || u.language || 'en',
    consultations: Number(u.consultation_count ?? u.consultations_count ?? u.consultations ?? 0),
    isActive: u.is_active !== false,
    createdAt: u.created_at,
  };
}

function initials(name) {
  return name.split(' ').filter(Boolean).slice(0, 2).map((p) => p[0].toUpperCase()).join('') || '?';
}

function currentAdminId() {
  try {
    return JSON.parse(localStorage.getItem('admin_user'))?.id;
  } catch {
    return null;
  }
}

function ConfirmDialog({ user, onCancel, onConfirm, busy, error }) {
  const [reason, setReason] = useState('');
  const deactivating = user.isActive;

  return (
    <div className="modal-backdrop" onClick={busy ? undefined : onCancel}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>{deactivating ? 'Deactivate account?' : 'Reactivate account?'}</h3>
          <button className="icon-btn" onClick={onCancel} disabled={busy}><X size={18} /></button>
        </div>

        <p className="muted">
          {deactivating
            ? <>
                <strong>{user.name}</strong> will no longer be able to log in to the mobile app.
                Their consultation history is kept.
              </>
            : <>
                <strong>{user.name}</strong> will be able to log in to the mobile app again.
              </>}
        </p>

        <label className="field-label" htmlFor="reason">Reason (optional, saved to the audit log)</label>
        <textarea
          id="reason"
          className="textarea"
          rows={3}
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          placeholder={deactivating ? 'e.g. Duplicate account, misuse of the service' : 'e.g. Patient request verified'}
          disabled={busy}
        />

        {error && <div className="alert alert-error">{error}</div>}

        <div className="modal-actions">
          <button className="btn btn-outline" onClick={onCancel} disabled={busy}>Cancel</button>
          <button
            className={`btn ${deactivating ? 'btn-danger' : 'btn-success'}`}
            onClick={() => onConfirm(reason.trim())}
            disabled={busy}
          >
            {busy ? 'Saving…' : deactivating ? 'Deactivate' : 'Reactivate'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [debounced, setDebounced] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');

  const [target, setTarget] = useState(null);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState('');

  const myId = currentAdminId();

  // Wait 400 ms after typing before searching
  useEffect(() => {
    const t = setTimeout(() => { setDebounced(search.trim()); setPage(1); }, 400);
    return () => clearTimeout(t);
  }, [search]);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/admin/users', {
        params: { search: debounced || undefined, page, limit: PAGE_SIZE },
      });
      const data = res.data;
      const list = Array.isArray(data) ? data : data.users || [];
      setUsers(list.map(normalize));
      setTotal(Number(data.total ?? list.length));
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }, [debounced, page]);

  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    if (!toast) return undefined;
    const t = setTimeout(() => setToast(''), 3000);
    return () => clearTimeout(t);
  }, [toast]);

  const visible = useMemo(() => {
    if (statusFilter === 'active') return users.filter((u) => u.isActive);
    if (statusFilter === 'inactive') return users.filter((u) => !u.isActive);
    return users;
  }, [users, statusFilter]);

  const counts = useMemo(() => ({
    all: users.length,
    active: users.filter((u) => u.isActive).length,
    inactive: users.filter((u) => !u.isActive).length,
  }), [users]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  async function confirmToggle(reason) {
    setSaving(true);
    setSaveError('');
    const next = !target.isActive;
    try {
      await api.patch(`/admin/users/${target.id}/status`, {
        is_active: next,
        reason: reason || undefined,
      });
      setUsers((prev) => prev.map((u) => (u.id === target.id ? { ...u, isActive: next } : u)));
      setToast(`${target.name} was ${next ? 'reactivated' : 'deactivated'}.`);
      setTarget(null);
    } catch (err) {
      setSaveError(errorMessage(err));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h1>Users</h1>
          <p className="muted">Manage patient accounts and access</p>
        </div>
        <button className="btn btn-outline" onClick={load} disabled={loading}>
          <RefreshCw size={16} className={loading ? 'spin' : ''} /> Refresh
        </button>
      </div>

      {toast && <div className="alert alert-success">{toast}</div>}

      <div className="card">
        <div className="toolbar">
          <div className="search-box">
            <Search size={16} />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by name, email or phone…"
            />
            {search && (
              <button className="icon-btn" onClick={() => setSearch('')}><X size={14} /></button>
            )}
          </div>

          <div className="tabs">
            {[
              ['all', 'All'],
              ['active', 'Active'],
              ['inactive', 'Deactivated'],
            ].map(([key, label]) => (
              <button
                key={key}
                className={`tab ${statusFilter === key ? 'active' : ''}`}
                onClick={() => setStatusFilter(key)}
              >
                {label} <span className="tab-count">{counts[key]}</span>
              </button>
            ))}
          </div>
        </div>

        {error ? (
          <div className="alert alert-error">{error}</div>
        ) : loading && users.length === 0 ? (
          <div className="chart-empty small">Loading users…</div>
        ) : visible.length === 0 ? (
          <div className="chart-empty small">No users match your search</div>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>User</th>
                  <th>Phone</th>
                  <th>Role</th>
                  <th>Language</th>
                  <th>Consultations</th>
                  <th>Status</th>
                  <th>Joined</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {visible.map((u) => {
                  const isMe = String(u.id) === String(myId);
                  return (
                    <tr key={u.id} className={u.isActive ? '' : 'row-inactive'}>
                      <td>
                        <div className="user-cell">
                          <div className={`avatar ${u.role === 'admin' ? 'avatar-admin' : ''}`}>
                            {initials(u.name)}
                          </div>
                          <div>
                            <div className="cell-strong">{u.name}{isMe && <span className="you-tag">You</span>}</div>
                            <div className="cell-sub">{u.email}</div>
                          </div>
                        </div>
                      </td>
                      <td className="nowrap">{u.phone}</td>
                      <td>
                        {u.role === 'admin'
                          ? <span className="role role-admin"><ShieldCheck size={13} /> Admin</span>
                          : <span className="role">Patient</span>}
                      </td>
                      <td>{LANGUAGE_LABELS[u.language] || u.language}</td>
                      <td><span className="count-pill">{u.consultations}</span></td>
                      <td>
                        <span className={`status ${u.isActive ? 'status-on' : 'status-off'}`}>
                          {u.isActive ? 'Active' : 'Deactivated'}
                        </span>
                      </td>
                      <td className="nowrap cell-sub">{formatDateTime(u.createdAt)}</td>
                      <td className="nowrap">
                        {isMe ? (
                          <span className="cell-sub">—</span>
                        ) : u.isActive ? (
                          <button className="btn btn-sm btn-danger-outline" onClick={() => { setSaveError(''); setTarget(u); }}>
                            <UserX size={14} /> Deactivate
                          </button>
                        ) : (
                          <button className="btn btn-sm btn-success-outline" onClick={() => { setSaveError(''); setTarget(u); }}>
                            <UserCheck size={14} /> Activate
                          </button>
                        )}
                      </td>
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
            <span className="muted">Page {page} of {totalPages} · {total} users</span>
            <button className="btn btn-sm btn-outline" disabled={page >= totalPages || loading} onClick={() => setPage((p) => p + 1)}>
              Next →
            </button>
          </div>
        )}
      </div>

      {target && (
        <ConfirmDialog
          user={target}
          busy={saving}
          error={saveError}
          onCancel={() => setTarget(null)}
          onConfirm={confirmToggle}
        />
      )}
    </div>
  );
}