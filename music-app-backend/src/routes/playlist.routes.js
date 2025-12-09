import express from "express";
import multer from "multer";
import {
  createPlaylist,
  getUserPlaylists,
  updatePlaylist,
  deletePlaylist,
  addSongToPlaylist,
  getSongsInPlaylist,
  removeSongFromPlaylist, // ✅ thêm import hàm xóa bài hát
  updatePlaylistImage, // 🖼️ cập nhật ảnh playlist
} from "../controllers/playlist.controller.js";
import verifyToken from "../middleware/auth.middleware.js";

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// 🆕 Tạo playlist mới
router.post("/", verifyToken, createPlaylist);

// 🔍 Lấy tất cả playlist của user đang đăng nhập
router.get("/me", verifyToken, getUserPlaylists);

// ✏️ Cập nhật playlist (đổi tên/di chuyển)
router.put("/:id", verifyToken, updatePlaylist);

// 🖼️ Cập nhật ảnh playlist (multipart field: image)
router.put("/:id/image", verifyToken, upload.single('image'), updatePlaylistImage);

// ❌ Xóa playlist
router.delete("/:id", verifyToken, deletePlaylist);

// 🎵 Lấy danh sách bài hát trong playlist
router.get("/:id/songs", verifyToken, getSongsInPlaylist);

// ➕ Thêm bài hát vào playlist (dễ test hơn, dùng params)
router.post("/:playlistId/songs/:songId", verifyToken, addSongToPlaylist);

// ➖ Xóa bài hát khỏi playlist
router.delete("/:playlistId/songs/:songId", verifyToken, removeSongFromPlaylist);

export default router;
