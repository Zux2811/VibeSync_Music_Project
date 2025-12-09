import { v2 as cloudinary } from "cloudinary";
import streamifier from "streamifier";
import Song from "../models/song.model.js";
import UserProfile from "../models/userProfile.model.js";
import logger from "../utils/logger.js";

// Upload buffer lên Cloudinary bằng stream
const uploadBuffer = (buffer, options) => {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(options, (err, result) => {
      if (err) reject(err);
      else resolve(result);
    });
    streamifier.createReadStream(buffer).pipe(stream);
  });
};
export const uploadSong = async (req, res) => {
  try {
    const { title, artist, album } = req.body;

    if (!title || !artist) {
      return res.status(400).json({ error: "title và artist là bắt buộc" });
    }

    let audioUrl = null;
    let imageUrl = null;

    // Upload audio
    if (req.files && req.files.audio && req.files.audio[0]) {
      const result = await uploadBuffer(req.files.audio[0].buffer, {
        resource_type: "video", // Bắt buộc cho audio/mp3
        folder: "music_app/audio",
      });
      audioUrl = result.secure_url;
    }

    // Upload image
    if (req.files && req.files.image && req.files.image[0]) {
      const result = await uploadBuffer(req.files.image[0].buffer, {
        resource_type: "image",
        folder: "music_app/images",
      });
      imageUrl = result.secure_url;
    }

    // Save to database using Sequelize model
    const song = await Song.create({
      title,
      artist,
      album,
      imageUrl,
      audioUrl,
    });

    logger.info("Song uploaded successfully", { songId: song.id, title });

    return res.json({
      message: "Uploaded successfully",
      song,
      audioUrl,
      imageUrl,
    });
  } catch (error) {
    logger.error("Upload error", error);
    return res.status(500).json({ error: error.message });
  }
};

export const uploadAvatar = async (req, res) => {
  try {
    const userId = req.user.id; // From authMiddleware
    const file = req.file;

    if (!file) {
      logger.warn("Avatar upload failed: No file provided", { userId });
      return res.status(400).json({ message: "No file uploaded." });
    }

    logger.debug("Uploading avatar to Cloudinary for user", { userId });
    const result = await uploadBuffer(file.buffer, {
      folder: `avatars/${userId}`,
      resource_type: 'image'
    });

    // Update the user's profile with the new avatar URL
    const [updateCount] = await UserProfile.update(
      { avatarUrl: result.secure_url },
      { where: { userId: userId } }
    );

    if (updateCount === 0) {
      logger.warn(`No profile found to update for user ${userId}. A new one will be created.`);
      // If no profile existed, create one. This is a fallback.
      await UserProfile.create({
        userId: userId,
        avatarUrl: result.secure_url,
      });
    }

    logger.info("Avatar uploaded and profile updated successfully", { userId, avatarUrl: result.secure_url });

    return res.json({
      message: "Avatar uploaded successfully",
      avatarUrl: result.secure_url
    });
  } catch (error) {
    logger.error("Avatar upload error", { userId: req.user?.id, error });
    return res.status(500).json({ message: "Error uploading avatar", error: error.message });
  }
};
