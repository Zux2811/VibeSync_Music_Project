import { useEffect, useMemo, useState } from "react";
import { Snackbar, Alert, TablePagination, Box, Typography, Paper, InputAdornment, TextField, Chip, CircularProgress } from "@mui/material";
import SearchIcon from '@mui/icons-material/Search';
import MusicNoteIcon from '@mui/icons-material/MusicNote';
import api from "../api/api";
import SongTable from "../components/SongTable";
import SongEditModal from "../components/SongEditModal";

export default function SongsPage() {
  const [songs, setSongs] = useState([]);
  const [editingSong, setEditingSong] = useState(null);
  const [loading, setLoading] = useState(false);
  const [initialLoading, setInitialLoading] = useState(true);
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  const [snack, setSnack] = useState({ open: false, message: "", severity: "success" });
  const notify = ({ type = "success", message = "" }) => setSnack({ open: true, message, severity: type });

  const fetchSongs = async () => {
    try {
      const res = await api.get("/songs");
      setSongs(res.data.items || []);
    } catch (err) {
      console.error(err);
      notify({ type: "error", message: "Không thể tải danh sách bài hát" });
    } finally {
      setInitialLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!confirm("Bạn chắc chắn muốn xóa bài hát này?")) return;
    try {
      setLoading(true);
      await api.delete(`/songs/${id}`);
      notify({ type: "success", message: "Đã xóa bài hát" });
      fetchSongs();
    } catch (err) {
      console.error(err);
      notify({ type: "error", message: err.response?.data?.message || "Xóa thất bại" });
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (song) => setEditingSong(song);

  useEffect(() => {
    fetchSongs();
  }, []);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return songs;
    return songs.filter((s) =>
      (s.title || "").toLowerCase().includes(q) ||
      (s.artist || "").toLowerCase().includes(q) ||
      (s.album || "").toLowerCase().includes(q)
    );
  }, [songs, query]);

  const paginated = useMemo(() => {
    const start = page * rowsPerPage;
    return filtered.slice(start, start + rowsPerPage);
  }, [filtered, page, rowsPerPage]);

  const handleChangePage = (_e, newPage) => setPage(newPage);
  const handleChangeRowsPerPage = (e) => {
    setRowsPerPage(parseInt(e.target.value, 10));
    setPage(0);
  };

  if (initialLoading) {
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
          <MusicNoteIcon sx={{ fontSize: 32, color: '#6366f1' }} />
          <Typography variant="h4" component="h2" sx={{ fontWeight: 700, color: '#1e293b' }}>
            Quản lý bài hát
          </Typography>
        </Box>
        <Typography variant="body1" sx={{ color: '#64748b' }}>
          Xem, chỉnh sửa và quản lý tất cả bài hát trong hệ thống
        </Typography>
      </Box>

      <Paper sx={{ p: 3, borderRadius: 3, mb: 3, boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
        <Box sx={{ display: "flex", gap: 2, alignItems: "center", flexWrap: 'wrap' }}>
          <TextField
            placeholder="Tìm theo tiêu đề, nghệ sĩ, album..."
            value={query}
            onChange={(e) => { setQuery(e.target.value); setPage(0); }}
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
          <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
            <Chip 
              label={`${filtered.length} bài hát`} 
              sx={{ 
                backgroundColor: 'rgba(99, 102, 241, 0.1)', 
                color: '#6366f1',
                fontWeight: 600 
              }} 
            />
            {loading && <CircularProgress size={20} sx={{ color: '#6366f1' }} />}
          </Box>
        </Box>
      </Paper>

      <Paper sx={{ borderRadius: 3, overflow: 'hidden', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
        <SongTable songs={paginated} onEdit={handleEdit} onDelete={handleDelete} />
        
        <Box sx={{ 
          display: "flex", 
          justifyContent: "flex-end", 
          borderTop: '1px solid #e2e8f0',
          backgroundColor: '#f8fafc'
        }}>
          <TablePagination
            component="div"
            count={filtered.length}
            page={page}
            onPageChange={handleChangePage}
            rowsPerPage={rowsPerPage}
            onRowsPerPageChange={handleChangeRowsPerPage}
            rowsPerPageOptions={[5, 10, 25, 50]}
            labelRowsPerPage="Hàng mỗi trang"
          />
        </Box>
      </Paper>

      {editingSong && (
        <SongEditModal
          song={editingSong}
          onClose={() => setEditingSong(null)}
          onSaved={fetchSongs}
          onNotify={notify}
        />
      )}

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
