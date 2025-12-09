// import Song from "../models/song.model.js";
// import User from "../models/user.model.js";
// import Playlist from "../models/playlist.model.js";

// // ===============================
// // 🎵 Lấy tất cả bài hát
// // ===============================
// export const getAllSongs = async (req, res) => {
//   try {
//     const songs = await Song.findAll();
//     res.json(songs);
//   } catch (error) {
//     console.error("Error fetching songs:", error);
//     res.status(500).json({ message: "Error fetching songs", error: error.message });
//   }
// };

// // ===============================
// // ➕ Upload bài hát (Cloudinary)
// // ===============================
// export const addSong = async (req, res) => {
//   try {
//     const { title, artist, album } = req.body;
//     const { imageUrl, audioUrl } = req.uploadedFiles;

//     if (!audioUrl) {
//       return res.status(400).json({ message: "Audio file is required" });
//     }

//     const newSong = await Song.create({
//       title,
//       artist,
//       album,
//       url: audioUrl,
//       imageUrl: imageUrl || null,
//     });

//     res.status(201).json({
//       message: "Song uploaded successfully",
//       song: newSong,
//     });
//   } catch (error) {
//     res.status(500).json({
//       message: "Error adding song",
//       error: error.message,
//     });
//   }
// };

// // ===============================
// // ✏️ Cập nhật bài hát
// // ===============================
// export const updateSong = async (req, res) => {
//   try {
//     const { id } = req.params;
//     const { title, artist, album, audioUrl, imageUrl } = req.body;

//     const song = await Song.findByPk(id);
//     if (!song) return res.status(404).json({ message: "Song not found" });

//     Object.assign(song, { title, artist, album, audioUrl, imageUrl });
//     await song.save();

//     res.json({ message: "Song updated successfully", song });
//   } catch (error) {
//     console.error("Error updating song:", error);
//     res.status(500).json({ message: "Error updating song", error: error.message });
//   }
// };

// // ===============================
// // ❌ Xóa bài hát
// // ===============================
// export const deleteSong = async (req, res) => {
//   try {
//     const { id } = req.params;
//     const song = await Song.findByPk(id);

//     if (!song) return res.status(404).json({ message: "Song not found" });

//     await song.destroy();
//     res.json({ message: "Song deleted successfully" });
//   } catch (error) {
//     console.error("Error deleting song:", error);
//     res.status(500).json({ message: "Error deleting song", error: error.message });
//   }
// };

// // ===============================
// // 🎧 Lấy bài hát theo playlist
// // ===============================
// export const getSongsByPlaylist = async (req, res) => {
//   try {
//     const { playlistId } = req.params;

//     const playlist = await Playlist.findByPk(playlistId, {
//       include: { model: Song, through: { attributes: [] } },
//     });

//     if (!playlist) return res.status(404).json({ message: "Playlist not found" });

//     res.json(playlist.Songs || []);
//   } catch (error) {
//     console.error("Error getting songs by playlist:", error);
//     res.status(500).json({ message: "Server error", error: error.message });
//   }
// };

// // ===============================
// // 👤 Lấy bài hát theo user
// // ===============================
// export const getSongsByUser = async (req, res) => {
//   try {
//     const { userId } = req.params;

//     const user = await User.findByPk(userId, {
//       include: [
//         {
//           model: Playlist,
//           include: [{ model: Song, through: { attributes: [] } }],
//         },
//       ],
//     });

//     if (!user) return res.status(404).json({ message: "User not found" });

//     const allSongs =
//       user.Playlists.flatMap((playlist) => playlist.Songs || []) || [];

//     res.json(allSongs);
//   } catch (error) {
//     console.error("Error in getSongsByUser:", error);
//     res.status(500).json({ message: "Server error", error: error.message });
//   }
// };

import Song from "../models/song.model.js";
import User from "../models/user.model.js";
import Playlist from "../models/playlist.model.js";
import cloudinary from "../config/cloudinary.js";
import { Readable } from "stream";
import logger from "../utils/logger.js";

// Convert buffer → stream (Cloudinary yêu cầu)
function bufferToStream(buffer) {
  const readable = new Readable();
  readable.push(buffer);
  readable.push(null);
  return readable;
}

// ===============================
// 🎵 Lấy tất cả bài hát (với pagination)
// ===============================
export const getAllSongs = async (req, res) => {
  try {
    // Parse pagination parameters from query string
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;

    // Validate pagination parameters
    if (page < 1 || limit < 1) {
      logger.warn("Invalid pagination parameters", { page, limit });
      return res.status(400).json({ message: "page and limit must be positive integers" });
    }

    const offset = (page - 1) * limit;

    logger.info("Fetching songs with pagination", { page, limit, offset });

    // Use findAndCountAll to get both count and rows
    const { count, rows: songs } = await Song.findAndCountAll({
      offset,
      limit,
      order: [['id', 'ASC']], // Optional: sort by ID for consistent ordering
    });

    const totalPages = Math.ceil(count / limit);
    const hasNext = page < totalPages;
    const hasPrev = page > 1;

    logger.debug("Found songs", { count, returned: songs.length, page, totalPages });

    res.json({
      items: songs,
      page,
      limit,
      total: count,
      totalPages,
      hasNext,
      hasPrev,
    });
  } catch (error) {
    logger.error("Error fetching songs", error);
    res.status(500).json({ message: "Error fetching songs", error: error.message });
  }
};

// ===============================
// ➕ Upload bài hát (Cloudinary)
// ===============================
export const addSong = async (req, res) => {
  try {
    logger.info("Received song upload request");
    const { title, artist, album } = req.body;
    logger.debug("Song details", { title, artist, album });

    if (!req.files || !req.files.audio) {
      logger.warn("Song upload failed: Audio file is required");
      return res.status(400).json({ message: "Audio file is required" });
    }

    logger.debug("Files received", {
      hasAudio: !!req.files.audio,
      hasImage: !!req.files.image,
      audioSize: req.files.audio[0]?.size,
      imageSize: req.files.image?.[0]?.size,
    });

    const audioBuffer = req.files.audio[0].buffer;
    const imageBuffer = req.files.image ? req.files.image[0].buffer : null;

    let imageUrl = null;
    if (imageBuffer) {
      logger.debug("Uploading image to Cloudinary...");
      imageUrl = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            folder: "music-player-images",
            resource_type: "image",
          },
          (err, result) => {
            if (err) {
              logger.error("Image upload failed", err);
              return reject(err);
            }
            logger.debug("Image uploaded successfully", { url: result.secure_url });
            resolve(result.secure_url);
          }
        );
        bufferToStream(imageBuffer).pipe(stream);
      });
    }

    logger.debug("Uploading audio to Cloudinary...");
    const audioUrl = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: "music-player-audio",
          resource_type: "video", // Required for mp3/wav/m4a
        },
        (err, result) => {
          if (err) {
            logger.error("Audio upload failed", err);
            return reject(err);
          }
          logger.debug("Audio uploaded successfully", { url: result.secure_url });
          resolve(result.secure_url);
        }
      );
      bufferToStream(audioBuffer).pipe(stream);
    });

    logger.debug("Saving song to database...");
    const newSong = await Song.create({
      title,
      artist,
      album,
      audioUrl: audioUrl,
      imageUrl: imageUrl || null,
    });

    logger.info("Song created successfully", { id: newSong.id, title: newSong.title });
    res.status(201).json({
      message: "Song uploaded successfully",
      song: newSong,
    });
  } catch (error) {
    logger.error("Error adding song", error);
    res.status(500).json({
      message: "Error adding song",
      error: error.message,
    });
  }
};

// ===============================
// ✏️ Cập nhật bài hát
// ===============================
export const updateSong = async (req, res) => {
  try {
    const { id } = req.params;
    logger.info("Received update request for song", { id });
    const { title, artist, album, audioUrl, imageUrl } = req.body;
    logger.debug("Update data", { id, title, artist, album });

    const song = await Song.findByPk(id);
    if (!song) {
      logger.warn("Update failed: Song not found", { id });
      return res.status(404).json({ message: "Song not found" });
    }

    logger.debug("Updating song in database", { id });
    Object.assign(song, { title, artist, album, audioUrl, imageUrl });
    await song.save();

    logger.info("Song updated successfully", { id });
    res.json({ message: "Song updated successfully", song });
  } catch (error) {
    logger.error("Error updating song", error);
    res.status(500).json({ message: "Error updating song", error: error.message });
  }
};

// ===============================
// ❌ Xóa bài hát
// ===============================
export const deleteSong = async (req, res) => {
  try {
    const { id } = req.params;
    logger.info("Received delete request for song", { id });
    const song = await Song.findByPk(id);

    if (!song) {
      logger.warn("Delete failed: Song not found", { id });
      return res.status(404).json({ message: "Song not found" });
    }

    logger.debug("Deleting song from database", { id, title: song.title });
    await song.destroy();
    logger.info("Song deleted successfully", { id });
    res.json({ message: "Song deleted successfully" });
  } catch (error) {
    logger.error("Error deleting song", error);
    res.status(500).json({ message: "Error deleting song", error: error.message });
  }
};

// ===============================
// 🎧 Lấy bài hát theo playlist
// ===============================
export const getSongsByPlaylist = async (req, res) => {
  try {
    const { playlistId } = req.params;
    logger.info("Fetching songs for playlist", { playlistId });

    const playlist = await Playlist.findByPk(playlistId, {
      include: { model: Song, through: { attributes: [] } },
    });

    if (!playlist) {
      logger.warn("Get songs by playlist failed: Playlist not found", { playlistId });
      return res.status(404).json({ message: "Playlist not found" });
    }

    const songs = playlist.Songs || [];
    logger.debug("Found songs for playlist", { playlistId, count: songs.length });
    res.json(songs);
  } catch (error) {
    logger.error("Error getting songs by playlist", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// ===============================
// 👤 Lấy bài hát theo user
// ===============================
export const getSongsByUser = async (req, res) => {
  try {
    const { userId } = req.params;
    logger.info("Fetching songs for user", { userId });

    const user = await User.findByPk(userId, {
      include: [
        {
          model: Playlist,
          include: [{ model: Song, through: { attributes: [] } }],
        },
      ],
    });

    if (!user) {
      logger.warn("Get songs by user failed: User not found", { userId });
      return res.status(404).json({ message: "User not found" });
    }

    const allSongs =
      user.Playlists.flatMap((playlist) => playlist.Songs || []) || [];

    logger.debug("Found songs for user", { userId, count: allSongs.length });
    res.json(allSongs);
  } catch (error) {
    logger.error("Error in getSongsByUser", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// ===============================
// 🎵 Lấy bài hát theo danh sách IDs
// ===============================
export const getSongsByIds = async (req, res) => {
  try {
    const { ids } = req.query;
    if (!ids) {
      logger.warn("Get songs by IDs failed: No IDs provided");
      return res.status(400).json({ message: "IDs parameter is required" });
    }

    // Parse comma-separated IDs
    const idArray = ids.split(",").map((id) => parseInt(id.trim(), 10)).filter((id) => !isNaN(id));

    if (idArray.length === 0) {
      logger.warn("Get songs by IDs failed: No valid IDs provided");
      return res.status(400).json({ message: "No valid IDs provided" });
    }

    logger.info("Fetching songs by IDs", { count: idArray.length, ids: idArray });

    const songs = await Song.findAll({
      where: { id: idArray },
      attributes: ['id', 'title', 'artist', 'audioUrl', 'imageUrl', 'album', 'duration'],
    });

    logger.debug("Found songs by IDs", { count: songs.length });
    res.json(songs);
  } catch (error) {
    logger.error("Error fetching songs by IDs", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};
