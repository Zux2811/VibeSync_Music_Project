import express from "express";
import { createOrUpdateProfile, getProfile } from "../controllers/userProfile.controller.js";

const router = express.Router();

router.post("/", createOrUpdateProfile);
router.get("/:userId", getProfile);

export default router;
