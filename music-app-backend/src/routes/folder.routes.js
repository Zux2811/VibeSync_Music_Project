import express from "express";
import verifyToken from "../middleware/auth.middleware.js";
import {
  createFolder,
  getFolders,
  updateFolder,
  deleteFolder,
} from "../controllers/folder.controller.js";

const router = express.Router();

// 🟢 Tạo folder mới
router.post("/", verifyToken, createFolder);

// 🟡 Lấy tất cả folder của user (kèm playlist)
router.get("/", verifyToken, getFolders);

// 🟠 Cập nhật folder theo ID
router.put("/:id", verifyToken, updateFolder);

// 🔴 Xóa folder
router.delete("/:id", verifyToken, deleteFolder);

export default router;
