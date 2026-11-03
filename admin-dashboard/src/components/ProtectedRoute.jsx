import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

export default function ProtectedRoute() {
  const { admin } = useAuth();
  return admin ? <Outlet /> : <Navigate to="/login" replace />;
}