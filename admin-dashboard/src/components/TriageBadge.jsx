import { triageInfo } from '../utils/triage';

export default function TriageBadge({ triage }) {
  const info = triageInfo(triage);
  return (
    <span className="badge" style={{ color: info.color, background: info.bg }}>
      <span className="dot" style={{ background: info.color }} />
      {info.label}
    </span>
  );
}