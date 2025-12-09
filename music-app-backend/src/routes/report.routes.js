import express from "express";
import authMiddleware from "../middleware/auth.middleware.js";
import adminAuth from "../middleware/admin.middleware.js";
import {
  reportComment,
  getAllReports,
  getReportedComments,
  deleteReport,
  deleteCommentByAdmin,
} from "../controllers/report.controller.js";

const router = express.Router();

// User báo cáo comment
router.post("/:commentId", authMiddleware, reportComment);

// Admin xem tất cả report (yêu cầu JWT + role admin)
router.get("/", authMiddleware, adminAuth, getAllReports);

// Admin xem comment bị báo cáo + số report
router.get("/group", authMiddleware, adminAuth, getReportedComments);

// Admin xoá 1 report
router.delete("/:id", authMiddleware, adminAuth, deleteReport);

// Admin xoá comment + report liên quan
router.delete("/comment/:commentId", authMiddleware, adminAuth, deleteCommentByAdmin);

export default router;
