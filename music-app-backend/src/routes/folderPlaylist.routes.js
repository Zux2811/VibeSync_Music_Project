import express from "express";
import authMiddleware from "../middleware/auth.middleware.js";
import {
  addPlaylistToFolder,
  getPlaylistsInFolder,
  removePlaylistFromFolder,
} from "../controllers/folderPlaylist.controller.js";

// NOTE: This route module is legacy and largely superseded by playlist.routes.js
// which supports updating a playlist's folderId directly. We keep it available
// for backward compatibility but it may be removed in the future.
const router = express.Router();

// 🟢 Thêm playlist vào folder
router.post(
  "/:folderId/playlists/:playlistId",
  authMiddleware,
  addPlaylistToFolder
);

// 🟡 Lấy danh sách playlist trong folder
router.get(
  "/:folderId/playlists",
  authMiddleware,
  getPlaylistsInFolder
);

// 🔴 Gỡ playlist khỏi folder
router.delete(
  "/playlists/:playlistId",
  authMiddleware,
  removePlaylistFromFolder
);

export default router;
