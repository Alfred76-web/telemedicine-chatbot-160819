import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { HeartPulse, Mail, Lock } from 'lucide-react';
import { useAuth } from '../auth/AuthContext';
import { errorMessage } from '../api';

export default function LoginPage() {
  const { admin, login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  if (admin) return <Navigate to="/" replace />;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email.trim(), password);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <div className="login-hero">
        <div className="orb orb-1" />
        <div className="orb orb-2" />
        <div className="hero-content">
          <div className="hero-logo"><HeartPulse size={40} /></div>
          <h1>AI Telemedicine Chatbot</h1>
          <p>Administrator dashboard for monitoring consultations, managing users and reviewing AI triage quality.</p>
        </div>
      </div>

      <div className="login-panel">
        <form className="login-card" onSubmit={handleSubmit}>
          <h2>Admin sign in</h2>
          <p className="muted">Use your administrator account.</p>

          {error && <div className="alert alert-error">{error}</div>}

          <label className="field">
            <span>Email</span>
            <div className="input-icon">
              <Mail size={18} />
              <input type="email" value={email} onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@telemed.com" required />
            </div>
          </label>

          <label className="field">
            <span>Password</span>
            <div className="input-icon">
              <Lock size={18} />
              <input type="password" value={password} onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••" required />
            </div>
          </label>

          <button className="btn btn-primary full" disabled={loading}>
            {loading ? 'Signing in…' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  );
}