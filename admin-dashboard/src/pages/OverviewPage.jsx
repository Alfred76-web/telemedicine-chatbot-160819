import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Users, MessagesSquare, CalendarClock, Siren, Flag, MessageSquareText, RefreshCw,
} from 'lucide-react';
import {
  ResponsiveContainer, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
  PieChart, Pie, Cell, Legend,
} from 'recharts';
import api, { errorMessage } from '../api';
import StatCard from '../components/StatCard';
import TriageBadge from '../components/TriageBadge';
import { TRIAGE, LANGUAGE_LABELS, formatDateTime } from '../utils/triage';

const LANGUAGE_COLORS = { en: '#00796b', sw: '#01579b' };

function DonutChart({ data }) {
  if (data.length === 0) return <div className="chart-empty">No data yet</div>;
  return (
    <ResponsiveContainer width="100%" height={260}>
      <PieChart>
        <Pie data={data} dataKey="value" nameKey="name" innerRadius={60} outerRadius={95} paddingAngle={3}>
          {data.map((d) => <Cell key={d.name} fill={d.color} />)}
        </Pie>
        <Tooltip />
        <Legend verticalAlign="bottom" height={36} iconType="circle" />
      </PieChart>
    </ResponsiveContainer>
  );
}

export default function OverviewPage() {
  const [stats, setStats] = useState(null);
  const [recent, setRecent] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [statsRes, recentRes] = await Promise.all([
        api.get('/admin/stats'),
        api.get('/admin/consultations', { params: { limit: 6 } }),
      ]);
      setStats(statsRes.data);
      setRecent(recentRes.data.consultations);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  if (loading && !stats) {
    return <div className="page"><div className="card empty">Loading dashboard…</div></div>;
  }
  if (error && !stats) {
    return (
      <div className="page">
        <div className="alert alert-error">{error}</div>
        <div><button className="btn btn-outline" onClick={load}>Retry</button></div>
      </div>
    );
  }

  const totals = stats.totals;
  const emergencyRate = totals.consultations
    ? Math.round((totals.emergencies / totals.consultations) * 100)
    : 0;

  const daily = stats.daily.map((d) => ({
    ...d,
    label: new Date(`${d.date}T00:00:00`).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }),
  }));

  const triageData = Object.keys(TRIAGE)
    .map((key) => ({
      name: TRIAGE[key].label,
      value: stats.triage.find((t) => t.name === key)?.value || 0,
      color: TRIAGE[key].color,
    }))
    .filter((d) => d.value > 0);

  const languageData = stats.language.map((l) => ({
    name: LANGUAGE_LABELS[l.name] || l.name,
    value: l.value,
    color: LANGUAGE_COLORS[l.name] || '#90a4ae',
  }));

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h1>Overview</h1>
          <p className="muted">System activity and AI triage outcomes</p>
        </div>
        <button className="btn btn-outline" onClick={load} disabled={loading}>
          <RefreshCw size={16} className={loading ? 'spin' : ''} /> Refresh
        </button>
      </div>

      {/* ── Stat cards ── */}
      <div className="stats-grid">
        <StatCard icon={Users} label="Registered patients" value={totals.patients}
          color="#00796b" hint={`${totals.inactive_patients} deactivated`} />
        <StatCard icon={MessagesSquare} label="Total consultations" value={totals.consultations} color="#01579b" />
        <StatCard icon={CalendarClock} label="Consultations today" value={totals.consultations_today} color="#6a1b9a" />
        <StatCard icon={Siren} label="Emergency triages" value={totals.emergencies}
          color="#c62828" hint={`${emergencyRate}% of consultations`} />
        <StatCard icon={Flag} label="Flagged for review" value={totals.flagged} color="#ef6c00" />
        <StatCard icon={MessageSquareText} label="SMS summaries sent" value={totals.sms_sent} color="#2e7d32" />
      </div>

      {/* ── Charts + recent ── */}
      <div className="charts-grid">
        <div className="card wide">
          <h3 className="card-title">Consultations — last 14 days</h3>
          <ResponsiveContainer width="100%" height={260}>
            <AreaChart data={daily} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="fillTeal" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#00796b" stopOpacity={0.35} />
                  <stop offset="100%" stopColor="#00796b" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e3e8ea" />
              <XAxis dataKey="label" tick={{ fontSize: 12 }} />
              <YAxis allowDecimals={false} tick={{ fontSize: 12 }} />
              <Tooltip />
              <Area type="monotone" dataKey="count" name="Consultations"
                stroke="#00796b" strokeWidth={2.5} fill="url(#fillTeal)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="card">
          <h3 className="card-title">Triage outcomes</h3>
          <DonutChart data={triageData} />
        </div>

        <div className="card">
          <h3 className="card-title">Consultation language</h3>
          <DonutChart data={languageData} />
        </div>

        <div className="card wide">
          <div className="card-header">
            <h3 className="card-title">Recent consultations</h3>
            <Link to="/consultations" className="link">View all →</Link>
          </div>
          {recent.length === 0 ? (
            <div className="chart-empty small">No consultations yet</div>
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
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {recent.map((c) => (
                    <tr key={c.id}>
                      <td className="nowrap">{formatDateTime(c.started_at)}</td>
                      <td>
                        <div className="cell-strong">{c.patient_name}</div>
                        <div className="cell-sub">{c.patient_email}</div>
                      </td>
                      <td><div className="truncate">{c.symptoms_reported}</div></td>
                      <td><span className="pill">{(c.language_used || '').toUpperCase()}</span></td>
                      <td><TriageBadge triage={c.triage_outcome} /></td>
                      <td>{c.flagged && <Flag size={16} className="flag-icon" />}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}