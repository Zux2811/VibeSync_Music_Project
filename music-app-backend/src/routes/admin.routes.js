import express from "express";
import authMiddleware from "../middleware/auth.middleware.js";
import adminAuth from "../middleware/admin.middleware.js";

import {
  loginAdmin,
  getAllUsers,
  deleteUser
} from "../controllers/admin.controller.js";
import { adminGetUserPlaylists } from "../controllers/playlist.controller.js";

const router = express.Router();

// login admin
router.post("/login", loginAdmin);

// protected routes (JWT verified first, then admin role checked)
router.get("/users", authMiddleware, adminAuth, getAllUsers);
router.delete("/users/:id", authMiddleware, adminAuth, deleteUser);

// admin can view a specific user's playlists
router.get("/users/:userId/playlists", authMiddleware, adminAuth, adminGetUserPlaylists);
// Reports endpoints have been migrated to /api/reports (report.controller.js)

export default router;
