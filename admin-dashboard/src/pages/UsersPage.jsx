import { useEffect, useState } from "react";
import { Box, Typography, Paper, CircularProgress, Chip, Snackbar, Alert, TextField, InputAdornment } from "@mui/material";
import PeopleIcon from '@mui/icons-material/People';
import SearchIcon from '@mui/icons-material/Search';
import api from "../api/api";
import UserTable from "../components/UserTable";

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState("");
  const [snack, setSnack] = useState({ open: false, message: "", severity: "success" });

  const notify = ({ type = "success", message = "" }) => setSnack({ open: true, message, severity: type });

  const fetchUsers = async () => {
    try {
      console.log("Fetching users...");
      const token = localStorage.getItem("jwt_token");
      console.log("Token exists:", !!token);
      
      const res = await api.get("/admin/users");
      console.log("Response:", res.data);
      setUsers(res.data || []);
    } catch (err) {
      console.error("Error fetching users:", err);
      console.error("Error response:", err.response?.data);
      console.error("Error status:", err.response?.status);
      
      const errorMsg = err.response?.data?.message || 
                       (err.response?.status === 401 ? "Token không hợp lệ, vui lòng đăng nhập lại" :
                        err.response?.status === 403 ? "Bạn không có quyền admin" :
                        "Không thể tải danh sách người dùng");
      notify({ type: "error", message: errorMsg });
    } finally {
      setLoading(false);
    }
  };

  const deleteUser = async (id) => {
    if (confirm("Bạn chắc chắn muốn xóa người dùng này?")) {
      try {
        await api.delete(`/admin/users/${id}`);
        notify({ type: "success", message: "Đã xóa người dùng" });
        fetchUsers();
      } catch (err) {
        notify({ type: "error", message: err.response?.data?.message || "Xóa thất bại" });
      }
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const filtered = users.filter((u) => {
    const q = query.toLowerCase();
    return (
      (u.username || "").toLowerCase().includes(q) ||
      (u.email || "").toLowerCase().includes(q)
    );
  });

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
          <PeopleIcon sx={{ fontSize: 32, color: '#6366f1' }} />
          <Typography variant="h4" component="h2" sx={{ fontWeight: 700, color: '#1e293b' }}>
            Quản lý người dùng
          </Typography>
        </Box>
        <Typography variant="body1" sx={{ color: '#64748b' }}>
          Xem và quản lý tài khoản người dùng trong hệ thống
        </Typography>
      </Box>

      <Paper sx={{ p: 3, borderRadius: 3, mb: 3, boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
        <Box sx={{ display: "flex", gap: 2, alignItems: "center", flexWrap: 'wrap' }}>
          <TextField
            placeholder="Tìm theo tên, email..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            size="small"
            sx={{ 
              flex: 1, 
              minWidth: 300,
              '& .MuiOutlinedInput-root': {
                borderRadius: 2,
                '&.Mui-focused fieldset': { borderColor: '#6366f1' },
              }
            }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon sx={{ color: '#94a3b8' }} />
                </InputAdornment>
              ),
            }}
          />
          <Chip 
            label={`${filtered.length} người dùng`} 
            sx={{ 
              backgroundColor: 'rgba(99, 102, 241, 0.1)', 
              color: '#6366f1',
              fontWeight: 600 
            }} 
          />
        </Box>
      </Paper>

      <Paper sx={{ borderRadius: 3, overflow: 'hidden', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
        <UserTable users={filtered} onDelete={deleteUser} />
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
