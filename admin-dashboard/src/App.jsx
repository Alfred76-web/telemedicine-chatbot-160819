import { Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import Placeholder from './pages/Placeholder';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<ProtectedRoute />}>
        <Route element={<Layout />}>
          <Route path="/" element={<Placeholder title="Overview" />} />
          <Route path="/consultations" element={<Placeholder title="Consultations" />} />
          <Route path="/users" element={<Placeholder title="Users" />} />
          <Route path="/logs" element={<Placeholder title="Audit log" />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}