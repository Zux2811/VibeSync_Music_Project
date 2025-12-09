import { Outlet } from "react-router-dom";
import Sidebar from "../components/Sidebar.jsx";
import Topbar from "../components/Topbar.jsx";

export default function DashboardLayout() {
  return (
    <div className="dashboard">
      <Sidebar />
      <div className="content">
        <Topbar />
        <div className="main">
          <Outlet />
        </div>
      </div>
    </div>
  );
}
