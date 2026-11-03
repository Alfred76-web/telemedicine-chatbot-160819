export default function StatCard({ icon: Icon, label, value, color = '#00796b', hint }) {
  return (
    <div className="stat-card">
      <div className="stat-icon" style={{ color, background: `${color}1a` }}>
        <Icon size={22} />
      </div>
      <div>
        <div className="stat-value">{value ?? '—'}</div>
        <div className="stat-label">{label}</div>
        {hint && <div className="stat-hint">{hint}</div>}
      </div>
    </div>
  );
}