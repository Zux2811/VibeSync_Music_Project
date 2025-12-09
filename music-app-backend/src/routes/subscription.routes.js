import express from "express";
import authMiddleware from "../middleware/auth.middleware.js";
import { listActiveTiers, getMySubscription, upgradeToPro } from "../controllers/subscription.controller.js";

const router = express.Router();

// Public
router.get("/tiers", listActiveTiers);

// Protected
router.get("/me", authMiddleware, getMySubscription);
router.post("/upgrade", authMiddleware, upgradeToPro);

export default router;

