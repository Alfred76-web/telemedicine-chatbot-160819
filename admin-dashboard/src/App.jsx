import { Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import Placeholder from './pages/Placeholder';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';
import OverviewPage from './pages/OverviewPage';
import UsersPage from './pages/UsersPage';
import ConsultationsPage from './pages/ConsultationsPage';
import ConsultationDetailPage from './pages/ConsultationDetailPage';

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<ProtectedRoute />}>
        <Route element={<Layout />}>
          <Route path="/" element={<OverviewPage />} />
          <Route path="/consultations" element={<ConsultationsPage />} />
          <Route path="/consultations/:id" element={<ConsultationDetailPage />} />
          <Route path="/users" element={<UsersPage />} />
          <Route path="/logs" element={<Placeholder title="Audit log" />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}