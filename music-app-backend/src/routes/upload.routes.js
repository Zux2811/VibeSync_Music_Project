import express from "express";
import multer from "multer";
import { uploadSong, uploadAvatar } from "../controllers/upload.controller.js";
import authMiddleware from "../middleware/auth.middleware.js";

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// Route for uploading song files
router.post(
  "/song",
  authMiddleware, // Protect this route
  upload.fields([{ name: "audio" }, { name: "image" }]),
  uploadSong
);

// Route for uploading a user avatar
router.post(
  "/avatar",
  authMiddleware, // Protect this route
  upload.single("avatar"), // Expect a single file with the field name 'avatar'
  uploadAvatar
);

export default router;
