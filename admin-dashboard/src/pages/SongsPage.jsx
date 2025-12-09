import { useEffect, useMemo, useState } from "react";
import { Snackbar, Alert, TablePagination } from "@mui/material";
import api from "../api/api";
import SongTable from "../components/SongTable";
import SongEditModal from "../components/SongEditModal";

export default function SongsPage() {
  const [songs, setSongs] = useState([]);
  const [editingSong, setEditingSong] = useState(null);
  const [loading, setLoading] = useState(false);
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  const [snack, setSnack] = useState({ open: false, message: "", severity: "success" });
  const notify = ({ type = "success", message = "" }) => setSnack({ open: true, message, severity: type });

  const fetchSongs = async () => {
    const res = await api.get("/songs");
    // The backend returns a pagination object, we need the 'items' array
    setSongs(res.data.items || []);
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

  // filter + paginate
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

  return (
    <>
      <h2>Danh sách bài hát</h2>

      <div style={{ display: "flex", gap: 12, alignItems: "center", marginBottom: 12 }}>
        <input
          placeholder="Tìm theo tiêu đề, nghệ sĩ, album..."
          value={query}
          onChange={(e) => { setQuery(e.target.value); setPage(0); }}
          style={{ flex: 1, padding: 8 }}
        />
        {loading && <span>Đang xử lý...</span>}
      </div>

      <SongTable songs={paginated} onEdit={handleEdit} onDelete={handleDelete} />

      <div style={{ display: "flex", justifyContent: "flex-end" }}>
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
      </div>

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
        <Alert severity={snack.severity} onClose={() => setSnack((s) => ({ ...s, open: false }))}>
          {snack.message}
        </Alert>
      </Snackbar>
    </>
  );
}
