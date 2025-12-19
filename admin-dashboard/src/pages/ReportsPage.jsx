import { useEffect, useState } from "react";
import { Snackbar, Alert, Box, Typography, Paper, CircularProgress, Chip } from "@mui/material";
import ReportProblemIcon from '@mui/icons-material/ReportProblem';
import api from "../api/api.js";
import ReportTable from "../components/ReportTable.jsx";

export default function ReportsPage() {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [snack, setSnack] = useState({ open: false, message: "", severity: "success" });

  const notify = ({ type = "success", message = "" }) => {
    setSnack({ open: true, message, severity: type });
  };

  const fetchReports = async () => {
    try {
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

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress sx={{ color: '#6366f1' }} />
      </Box>
    );
  }

  return (
    <>
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
          <ReportProblemIcon sx={{ fontSize: 32, color: '#f59e0b' }} />
          <Typography variant="h4" component="h2" sx={{ fontWeight: 700, color: '#1e293b' }}>
            Báo cáo bình luận
          </Typography>
          {reports.length > 0 && (
            <Chip 
              label={`${reports.length} báo cáo`} 
              sx={{ 
                backgroundColor: 'rgba(239, 68, 68, 0.1)', 
                color: '#ef4444',
                fontWeight: 600 
              }} 
            />
          )}
        </Box>
        <Typography variant="body1" sx={{ color: '#64748b' }}>
          Quản lý và xử lý các báo cáo vi phạm từ người dùng
        </Typography>
      </Box>

      <Paper sx={{ borderRadius: 3, overflow: 'hidden', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
        <ReportTable
          reports={reports}
          onDeleteComment={handleDeleteComment}
          onDeleteUser={handleDeleteUser}
        />
      </Paper>

      <Snackbar
        open={snack.open}
        autoHideDuration={2500}
        onClose={() => setSnack((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
      >
        <Alert 
          severity={snack.severity} 
          onClose={() => setSnack((s) => ({ ...s, open: false }))}
          sx={{ borderRadius: 2 }}
        >
          {snack.message}
        </Alert>
      </Snackbar>
    </>
  );
}
