import { useCallback, useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Search, RefreshCw, Download, Flag, X, FilterX } from 'lucide-react';
import api, { errorMessage } from '../api';
import TriageBadge from '../components/TriageBadge';
import { TRIAGE, LANGUAGE_LABELS, formatDateTime } from '../utils/triage';

const PAGE_SIZE = 15;
const FILTER_KEYS = ['from', 'to', 'triage', 'language', 'flagged', 'search'];

export default function ConsultationsPage() {
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();

  const filters = Object.fromEntries(FILTER_KEYS.map((k) => [k, params.get(k) || '']));
  const page = Number(params.get('page') || 1);

  const [searchText, setSearchText] = useState(filters.search);
  const [rows, setRows] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [error, setError] = useState('');

  // Update one or more URL params; any filter change goes back to page 1
  const update = useCallback((changes) => {
    setParams((prev) => {
      const next = new URLSearchParams(prev);
      Object.entries(changes).forEach(([k, v]) => (v ? next.set(k, v) : next.delete(k)));
      if (!('page' in changes)) next.delete('page');
      return next;
    });
  }, [setParams]);

  // Debounce the search box
  useEffect(() => {
    const t = setTimeout(() => {
      if (searchText.trim() !== filters.search) update({ search: searchText.trim() });
    }, 400);
    return () => clearTimeout(t);
  }, [searchText]); // eslint-disable-line react-hooks/exhaustive-deps

  const queryParams = () => {
    const q = {};
    FILTER_KEYS.forEach((k) => { if (filters[k]) q[k] = filters[k]; });
    return q;
  };

  const paramsKey = params.toString();

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/admin/consultations', {
        params: { ...queryParams(), page, limit: PAGE_SIZE },
      });
      const data = res.data;
      const list = Array.isArray(data) ? data : data.consultations || [];
      setRows(list);
      setTotal(Number(data.total ?? list[0]?.total_count ?? list.length));
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }, [paramsKey]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { load(); }, [load]);

  async function exportCsv() {
    setExporting(true);
    setError('');
    try {
      const res = await api.get('/admin/consultations/export', {
        params: queryParams(),
        responseType: 'blob',
      });
      const url = URL.createObjectURL(new Blob([res.data], { type: 'text/csv' }));
      const a = document.createElement('a');
      a.href = url;
      a.download = `consultations-${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (err) {
      setError('Export failed. ' + errorMessage(err));
    } finally {
      setExporting(false);
    }
  }

  const activeFilters = FILTER_KEYS.some((k) => filters[k]);
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h1>Consultations</h1>
          <p className="muted">Review AI consultations, transcripts and triage decisions</p>
        </div>
        <div className="header-actions">
          <button className="btn btn-outline" onClick={load} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'spin' : ''} /> Refresh
          </button>
          <button className="btn btn-primary" onClick={exportCsv} disabled={exporting || total === 0}>
            <Download size={16} /> {exporting ? 'Exporting…' : 'Export CSV'}
          </button>
        </div>
      </div>

      <div className="card">
        {/* ── Filters ── */}
        <div className="filters">
          <div className="search-box">
            <Search size={16} />
            <input
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              placeholder="Search patient or symptoms…"
            />
            {searchText && (
              <button className="icon-btn" onClick={() => setSearchText('')}><X size={14} /></button>
            )}
          </div>

          <label className="filter">
            <span>From</span>
            <input type="date" value={filters.from} max={filters.to || undefined}
              onChange={(e) => update({ from: e.target.value })} />
          </label>
          <label className="filter">
            <span>To</span>
            <input type="date" value={filters.to} min={filters.from || undefined}
              onChange={(e) => update({ to: e.target.value })} />
          </label>
          <label className="filter">
            <span>Triage</span>
            <select value={filters.triage} onChange={(e) => update({ triage: e.target.value })}>
              <option value="">All levels</option>
              {Object.entries(TRIAGE).map(([key, t]) => <option key={key} value={key}>{t.label}</option>)}
            </select>
          </label>
          <label className="filter">
            <span>Language</span>
            <select value={filters.language} onChange={(e) => update({ language: e.target.value })}>
              <option value="">All</option>
              <option value="en">English</option>
              <option value="sw">Kiswahili</option>
            </select>
          </label>
          <label className="filter-check">
            <input type="checkbox" checked={filters.flagged === 'true'}
              onChange={(e) => update({ flagged: e.target.checked ? 'true' : '' })} />
            <Flag size={14} /> Flagged only
          </label>

          {activeFilters && (
            <button className="btn btn-sm btn-outline" onClick={() => { setSearchText(''); setParams({}); }}>
              <FilterX size={14} /> Clear
            </button>
          )}
        </div>

        <div className="result-count muted">
          {loading ? 'Loading…' : `${total} consultation${total === 1 ? '' : 's'}${activeFilters ? ' match your filters' : ''}`}
        </div>

        {/* ── Table ── */}
        {error ? (
          <div className="alert alert-error">{error}</div>
        ) : !loading && rows.length === 0 ? (
          <div className="chart-empty small">No consultations found</div>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Patient</th>
                  <th>Symptoms</th>
                  <th>Lang</th>
                  <th>Triage</th>
                  <th>Flag</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((c) => (
                  <tr key={c.id} className="row-link" onClick={() => navigate(`/consultations/${c.id}`)}>
                    <td className="nowrap">{formatDateTime(c.started_at)}</td>
                    <td>
                      <div className="cell-strong">{c.patient_name}</div>
                      <div className="cell-sub">{c.patient_email}</div>
                    </td>
                    <td><div className="truncate">{c.symptoms_reported}</div></td>
                    <td>
                      <span className="pill" title={LANGUAGE_LABELS[c.language_used]}>
                        {(c.language_used || '').toUpperCase()}
                      </span>
                    </td>
                    <td><TriageBadge triage={c.triage_outcome} /></td>
                    <td>{c.flagged && <Flag size={16} className="flag-icon" />}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {totalPages > 1 && (
          <div className="pagination">
            <button className="btn btn-sm btn-outline" disabled={page <= 1 || loading}
              onClick={() => update({ page: String(page - 1) })}>← Previous</button>
            <span className="muted">Page {page} of {totalPages}</span>
            <button className="btn btn-sm btn-outline" disabled={page >= totalPages || loading}
              onClick={() => update({ page: String(page + 1) })}>Next →</button>
          </div>
        )}
      </div>
    </div>
  );
}