import express from "express";
import { getAllUsers, updateUser, deleteUser } from "../controllers/user.controller.js";
import authMiddleware from "../middleware/auth.middleware.js";

// NOTE: This route module is currently not mounted by server.js.
// If you need user admin endpoints, consider moving them under /api/admin
// and protecting with both authMiddleware and admin middleware.
const router = express.Router();

router.get("/", authMiddleware, getAllUsers);
router.put("/:id", authMiddleware, updateUser);
router.delete("/:id", authMiddleware, deleteUser);

export default router;
