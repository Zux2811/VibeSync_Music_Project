import { Navigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function ProtectedRoute({ children }) {
  const { admin } = useAuth();

  // If the admin object is not present in the context, redirect to login.
  // The AuthProvider handles initializing state from localStorage.
  if (!admin) {
    return <Navigate to="/login" replace />;
  }

  return children;
}
