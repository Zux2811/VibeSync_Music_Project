import { Routes, Route, Navigate } from "react-router-dom";
import DashboardLayout from "./layout/DashboardLayout.jsx";
import DashboardHome from "./pages/DashboardHome.jsx";
import UsersPage from "./pages/UsersPage.jsx";
import SongsPage from "./pages/SongsPage.jsx";
import UploadSongPage from "./pages/UploadSongPage.jsx";
import ReportsPage from "./pages/ReportsPage.jsx";
import VerificationsPage from "./pages/VerificationsPage.jsx";
import ProtectedRoute from "./middleware/ProtectedRoute.jsx";

export default function App() {
  // Get token from URL params (passed from Flutter web app)
  const urlParams = new URLSearchParams(window.location.search);
  const tokenFromUrl = urlParams.get('token');
  
  // If token is passed via URL, store it
  if (tokenFromUrl) {
    localStorage.setItem('admin_token', tokenFromUrl);
    // Clean URL
    window.history.replaceState({}, document.title, window.location.pathname);
  }

  return (
    <Routes>
      {/* Redirect /login to home - login is now handled via Flutter web app */}
      <Route path="/login" element={<Navigate to="/" replace />} />

      <Route
        path="/"
        element={
          <ProtectedRoute>
            <DashboardLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<DashboardHome />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="songs" element={<SongsPage />} />
        <Route path="upload" element={<UploadSongPage />} />
        <Route path="reports" element={<ReportsPage />} />
        <Route path="verifications" element={<VerificationsPage />} />
      </Route>
    </Routes>
  );
}
