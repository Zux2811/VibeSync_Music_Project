import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function Sidebar() {
  const navigate = useNavigate();
  const { logout } = useAuth();

  const handleLogout = () => {
    // Xóa đúng các key mà app đang dùng và reset context
    logout();
    navigate("/login");
  };

  return (
    <aside className="sidebar">
      <h2>Admin Panel</h2>

      <nav>
        <NavLink to="/">Dashboard</NavLink>
        <NavLink to="/users">Người dùng</NavLink>
        <NavLink to="/songs">Bài hát</NavLink>
        <NavLink to="/upload">Tải bài hát</NavLink>
        <NavLink to="/reports">Báo cáo</NavLink>
      </nav>

      <button className="logout-btn" onClick={handleLogout}>
        Đăng xuất
      </button>
    </aside>
  );
}
