import { Routes, Route } from "react-router-dom";
import LoginPage from "./pages/LoginPage.jsx";
import DashboardLayout from "./layout/DashboardLayout.jsx";
import DashboardHome from "./pages/DashboardHome.jsx";
import UsersPage from "./pages/UsersPage.jsx";
import SongsPage from "./pages/SongsPage.jsx";
import UploadSongPage from "./pages/UploadSongPage.jsx";
import ReportsPage from "./pages/ReportsPage.jsx";
import ProtectedRoute from "./middleware/ProtectedRoute.jsx";

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />

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
      </Route>
    </Routes>
  );
}
