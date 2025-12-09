// import express from "express";
// import { addComment, getComments, likeComment } from "../controllers/comment.controller.js";

// const router = express.Router();

// router.post("/", addComment);
// router.get("/", getComments);
// router.post("/:commentId/like", likeComment);

// export default router;

import express from "express";
import authMiddleware from "../middleware/auth.middleware.js";
import isAdmin from "../middleware/isAdmin.middleware.js";

import {
  addComment,
  getComments,
  likeComment,
  adminDeleteComment,
} from "../controllers/comment.controller.js";

const router = express.Router();

// User bình luận
router.post("/", authMiddleware, addComment);

// Lấy comment theo song hoặc playlist
router.get("/", getComments);

// User like comment
router.post("/:commentId/like", authMiddleware, likeComment);

// Admin xoá comment
router.delete("/:commentId", authMiddleware, isAdmin, adminDeleteComment);

export default router;
