import express from "express";
import authMiddleware from "../middleware/auth.middleware.js";
import {
  addSongToPlaylist,
  removeSongFromPlaylist,
  getSongsInPlaylist,
} from "../controllers/playlistSong.controller.js";

// NOTE: This legacy route module is superseded by playlist.routes.js which
// already exposes endpoints for adding/removing songs and listing songs in a playlist.
// It is kept for backward compatibility but not mounted in server.js.
const router = express.Router();

// 🎵 Thêm bài hát vào playlist
router.post("/:playlistId/songs", authMiddleware, addSongToPlaylist);

// ❌ Xóa bài hát khỏi playlist
router.delete("/:playlistId/songs/:songId", authMiddleware, removeSongFromPlaylist);

// 📜 Lấy danh sách bài hát trong playlist
router.get("/:playlistId/songs", authMiddleware, getSongsInPlaylist);

export default router;
