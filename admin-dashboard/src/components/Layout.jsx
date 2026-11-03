import { NavLink, Outlet } from 'react-router-dom';
import { LayoutDashboard, Users, MessagesSquare, ScrollText, LogOut, HeartPulse } from 'lucide-react';
import { useAuth } from '../auth/AuthContext';

const links = [
  { to: '/', label: 'Overview', icon: LayoutDashboard, end: true },
  { to: '/consultations', label: 'Consultations', icon: MessagesSquare },
  { to: '/users', label: 'Users', icon: Users },
  { to: '/logs', label: 'Audit log', icon: ScrollText },
];

export default function Layout() {
  const { admin, logout } = useAuth();
  const initials = (admin?.name || 'A')
    .split(' ')
    .map((p) => p[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-logo"><HeartPulse size={22} /></div>
          <div>
            <div className="brand-name">Telemed Admin</div>
            <div className="brand-sub">Clinical oversight</div>
          </div>
        </div>

        <nav className="nav">
          {links.map(({ to, label, icon: Icon, end }) => (
            <NavLink key={to} to={to} end={end}
              className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
              <Icon size={18} />
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="admin-chip">
            <div className="avatar">{initials}</div>
            <div className="admin-info">
              <div className="admin-name">{admin?.name}</div>
              <div className="admin-email">{admin?.email}</div>
            </div>
          </div>
          <button className="btn btn-ghost full" onClick={logout}>
            <LogOut size={16} /> Log out
          </button>
        </div>
      </aside>

      <main className="main">
        <Outlet />
      </main>
    </div>
  );
}