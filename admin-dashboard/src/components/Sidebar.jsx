import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { useTheme } from "../context/ThemeContext";
import DashboardIcon from '@mui/icons-material/Dashboard';
import PeopleIcon from '@mui/icons-material/People';
import MusicNoteIcon from '@mui/icons-material/MusicNote';
import CloudUploadIcon from '@mui/icons-material/CloudUpload';
import ReportIcon from '@mui/icons-material/Report';
import VerifiedUserIcon from '@mui/icons-material/VerifiedUser';
import LogoutIcon from '@mui/icons-material/Logout';

export default function Sidebar() {
  const navigate = useNavigate();
  const { logout } = useAuth();
  const { isDarkMode } = useTheme();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  const navItems = [
    { to: "/", icon: <DashboardIcon />, label: "Dashboard" },
    { to: "/users", icon: <PeopleIcon />, label: "Người dùng" },
    { to: "/songs", icon: <MusicNoteIcon />, label: "Bài hát" },
    { to: "/upload", icon: <CloudUploadIcon />, label: "Tải bài hát" },
    { to: "/reports", icon: <ReportIcon />, label: "Báo cáo" },
    { to: "/verifications", icon: <VerifiedUserIcon />, label: "Xác minh Artist" },
  ];

  return (
    <aside className={`sidebar ${isDarkMode ? 'dark' : 'light'}`}>
      <div className="sidebar-logo">
        <img src="/upload/logo/logo_splash.jpg" alt="VibeSync" className="sidebar-logo-img" />
        <div>
          <h2>VibeSync</h2>
          <p className="sidebar-subtitle">Music Admin</p>
        </div>
      </div>

      <nav>
        {navItems.map((item) => (
          <NavLink key={item.to} to={item.to} end={item.to === "/"}>
            {item.icon}
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <button className="logout-btn" onClick={handleLogout}>
        <LogoutIcon />
        <span>Đăng xuất</span>
      </button>
    </aside>
  );
}
