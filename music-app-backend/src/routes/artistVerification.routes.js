import express from "express";
import multer from "multer";
import { authMiddleware, requireRole } from "../middleware/auth.middleware.js";
import {
  submitVerificationRequest,
  getMyVerificationRequests,
  getAllVerificationRequests,
  getVerificationRequestById,
  approveVerificationRequest,
  rejectVerificationRequest,
  getVerificationStats
} from "../controllers/artistVerification.controller.js";

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// ========== USER ROUTES ==========

// Submit verification request
router.post(
  "/request",
  authMiddleware,
  upload.fields([
    { name: 'idDocument', maxCount: 1 },
    { name: 'authorizationDoc', maxCount: 1 },
    { name: 'profileImage', maxCount: 1 }
  ]),
  submitVerificationRequest
);

// Get my verification requests
router.get("/my-requests", authMiddleware, getMyVerificationRequests);

// ========== ADMIN ROUTES ==========

// Get all verification requests
router.get("/admin/requests", authMiddleware, requireRole(['admin']), getAllVerificationRequests);

// Get verification stats
router.get("/admin/stats", authMiddleware, requireRole(['admin']), getVerificationStats);

// Get verification request by ID
router.get("/admin/requests/:id", authMiddleware, requireRole(['admin']), getVerificationRequestById);

// Approve verification request
router.post("/admin/requests/:id/approve", authMiddleware, requireRole(['admin']), approveVerificationRequest);

// Reject verification request
router.post("/admin/requests/:id/reject", authMiddleware, requireRole(['admin']), rejectVerificationRequest);

export default router;
