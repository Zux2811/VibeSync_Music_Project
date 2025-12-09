import express from "express";
import multer from "multer";
import cloudinary from "../config/cloudinary.js"; // use centralized Cloudinary config
import streamifier from "streamifier";
import { Song } from "../models/index.js";
import authMiddleware from "../middleware/auth.middleware.js";
import adminAuth from "../middleware/admin.middleware.js";
import { getSongsByIds } from "../controllers/song.controller.js";



const router = express.Router();
const upload = multer();

const uploadBuffer = (buffer, opts = {}) =>
  new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(opts, (err, result) => {
      if (err) return reject(err);
      resolve(result);
    });

    streamifier.createReadStream(buffer).pipe(stream);
  });

// Helper: extract public_id from a Cloudinary secure_url
const getPublicIdFromUrl = (url) => {
  if (!url) return null;
  try {
    // Remove query string
    const clean = url.split("?")[0];
    // Find segment after '/upload/'
    const parts = clean.split("/upload/");
    if (parts.length < 2) return null;
    let rest = parts[1]; // e.g. v1700000000/music_app/images/abc.jpg
    // Remove leading version 'v1234567890/' if present
    rest = rest.replace(/^v\d+\//, "");
    // Remove file extension
    rest = rest.replace(/\.[a-zA-Z0-9]+$/, "");
    return rest; // e.g. music_app/images/abc
  } catch (e) {
    return null;
  }
};

const destroyIfExists = async (url, resourceType) => {
  const publicId = getPublicIdFromUrl(url);
  if (!publicId) return;
  const normalizedType = resourceType === "image" ? "image" : "video"; // only allow image or video
  try {
    await cloudinary.uploader.destroy(publicId, { resource_type: normalizedType });
  } catch (e) {
    // log only; resource may already be gone
    console.warn(`Cloudinary destroy failed for ${publicId} (${normalizedType}):`, e?.message || e);
  }
};

router.post(
  "/upload",
  authMiddleware,
  upload.fields([{ name: "audio" }, { name: "image" }]),
  async (req, res) => {
    try {
      const files = req.files || {};
      let audioUrl = null;
      let imageUrl = null;
      let audioDuration = 0;

      if (files.audio?.[0]) {
        const result = await uploadBuffer(files.audio[0].buffer, {
          resource_type: "video", // explicit for audio files
          folder: "music_app/audio",
        });
        audioUrl = result.secure_url;
        if (result && typeof result.duration !== "undefined") {
          const dur = Number(result.duration);
          if (!Number.isNaN(dur) && dur > 0) {
            audioDuration = Math.round(dur);
          }
        }
      }

      if (files.image?.[0]) {
        const result = await uploadBuffer(files.image[0].buffer, {
          resource_type: "image", // explicit for cover art
          folder: "music_app/images",
        });
        imageUrl = result.secure_url;
      }

      const { title, artist, album } = req.body;

      const song = await Song.create({
        title,
        artist,
        album,
        audioUrl,
        imageUrl,
        duration: audioDuration,
      });

      res.status(201).json({ message: "Uploaded", song });
    } catch (err) {
      console.error("Upload error:", err);
      return res.status(500).json({ error: err.message });
    }
  }
);

// Update a song (admin only)
router.put(
  "/:id",
  authMiddleware,
  adminAuth,
  upload.fields([{ name: "audio" }, { name: "image" }]),
  async (req, res) => {
    try {
      const { id } = req.params;
      const song = await Song.findByPk(id);
      if (!song) return res.status(404).json({ message: "Song not found" });

      const updates = {};
      const { title, artist, album } = req.body;
      if (title !== undefined) updates.title = title;
      if (artist !== undefined) updates.artist = artist;
      if (album !== undefined) updates.album = album;

      const files = req.files || {};

      // handle audio replacement
      if (files.audio?.[0]) {
        const up = await uploadBuffer(files.audio[0].buffer, {
          resource_type: "video", // explicit for audio
          folder: "music_app/audio",
        });
        // delete old
        if (song.audioUrl) await destroyIfExists(song.audioUrl, "video");
        updates.audioUrl = up.secure_url;
        if (up && typeof up.duration !== "undefined") {
          const dur = Number(up.duration);
          if (!Number.isNaN(dur) && dur > 0) {
            updates.duration = Math.round(dur);
          }
        }
      }

      // handle image replacement
      if (files.image?.[0]) {
        const up = await uploadBuffer(files.image[0].buffer, {
          resource_type: "image", // explicit for cover art
          folder: "music_app/images",
        });
        if (song.imageUrl) await destroyIfExists(song.imageUrl, "image");
        updates.imageUrl = up.secure_url;
      }

      await song.update(updates);
      res.json({ message: "Song updated", song });
    } catch (err) {
      console.error("Update song error:", err);
      res.status(500).json({ message: "Update failed", error: err.message });
    }
  }
);

// Delete a song (admin only)
router.delete("/:id", authMiddleware, adminAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const song = await Song.findByPk(id);
    if (!song) return res.status(404).json({ message: "Song not found" });

    // best-effort delete resources
    if (song.imageUrl) await destroyIfExists(song.imageUrl, "image");
    if (song.audioUrl) await destroyIfExists(song.audioUrl, "video");

    await song.destroy();
    res.json({ message: "Song deleted" });
  } catch (err) {
    console.error("Delete song error:", err);
    res.status(500).json({ message: "Delete failed", error: err.message });
  }
});

router.get("/by-ids", getSongsByIds);

router.get("/", async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || "1", 10), 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit || "50", 10), 1), 200);
    const offset = (page - 1) * limit;

    const { rows, count } = await Song.findAndCountAll({
      order: [["id", "DESC"]],
      limit,
      offset,
    });

    const totalPages = Math.ceil(count / limit) || 1;
    res.json({
      items: rows,
      page,
      limit,
      total: count,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1,
    });
  } catch (e) {
    res.status(500).json({ message: "Failed to fetch songs", error: e.message });
  }
});

export default router;
