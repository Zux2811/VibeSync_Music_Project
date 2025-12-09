import { useEffect, useState } from "react";
import { Snackbar, Alert } from "@mui/material";
import api from "../api/api.js";
import ReportTable from "../components/ReportTable.jsx";

export default function ReportsPage() {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(false);
  const [snack, setSnack] = useState({ open: false, message: "", severity: "success" });

  const notify = ({ type = "success", message = "" }) => {
    setSnack({ open: true, message, severity: type });
  };

  const fetchReports = async () => {
    try {
      setLoading(true);
      const res = await api.get("/reports");
      setReports(res.data || []);
    } catch (e) {
      console.error("Failed to fetch reports:", e);
      notify({
        type: "error",
        message: e.response?.data?.message || "Không thể tải danh sách báo cáo",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteComment = async (commentId) => {
    if (!commentId) return;
    if (!window.confirm("Xóa bình luận (kèm các trả lời) và toàn bộ báo cáo liên quan?")) return;
    try {
      await api.delete(`/reports/comment/${commentId}`);
      await fetchReports();
      notify({
        type: "success",
        message: "Đã xóa bình luận và các báo cáo liên quan",
      });
    } catch (e) {
      console.error("Failed to delete comment:", e);
      notify({
        type: "error",
        message: e.response?.data?.message || "Xóa bình luận thất bại",
      });
    }
  };

  const handleDeleteUser = async (userId) => {
    if (!userId) return;
    if (!window.confirm("Xóa tài khoản người bị báo cáo?")) return;
    try {
      await api.delete(`/admin/users/${userId}`);
      await fetchReports();
      notify({
        type: "success",
        message: "Đã xóa tài khoản người bị báo cáo",
      });
    } catch (e) {
      console.error("Failed to delete user:", e);
      notify({
        type: "error",
        message: e.response?.data?.message || "Xóa tài khoản thất bại",
      });
    }
  };

  useEffect(() => {
    fetchReports();
  }, []);

  return (
    <>
      <h2>Báo cáo bình luận</h2>
      {loading ? (
        <p>Đang tải...</p>
      ) : (
        <ReportTable
          reports={reports}
          onDeleteComment={handleDeleteComment}
          onDeleteUser={handleDeleteUser}
        />
      )}

      <Snackbar
        open={snack.open}
        autoHideDuration={2500}
        onClose={() => setSnack((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
      >
        <Alert severity={snack.severity} onClose={() => setSnack((s) => ({ ...s, open: false }))}>
          {snack.message}
        </Alert>
      </Snackbar>
    </>
  );
}
