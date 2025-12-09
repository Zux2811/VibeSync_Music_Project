import Playlist from "../models/playlist.model.js";
import Song from "../models/song.model.js";
import PlaylistSong from "../models/playlistSong.model.js";
import { v2 as cloudinary } from "cloudinary";
import streamifier from "streamifier";
import { getUserTier } from "../utils/tier.js";

// 🆕 Tạo playlist mới (folderId optional; allow root playlists)
export const createPlaylist = async (req, res) => {
  try {
    const { name } = req.body;
    let { folderId } = req.body;
    const userId = req.user.id;

    // Normalize folderId: treat '', 0, '0', undefined as null (root)
    if (folderId === undefined || folderId === '' || Number(folderId) === 0) {
      folderId = null;
    }

    // Enforce tier limits: free users can only create up to features.maxPlaylists
    const tier = await getUserTier(userId); // { code, features }
    const currentCount = await Playlist.count({ where: { UserId: userId } });
    const maxPlaylists = Number(tier?.features?.maxPlaylists || 5);
    if (tier.code !== 'pro' && currentCount >= maxPlaylists) {
      return res.status(403).json({
        message: `Free tier: Bạn chỉ được tạo tối đa ${maxPlaylists} playlist. Hãy nâng cấp Pro để tạo không giới hạn.`,
        tier: tier.code,
        currentCount,
        maxPlaylists,
      });
    }

    const payload = { name, UserId: userId };
    if (folderId !== undefined) payload.folderId = folderId; // null will be saved as NULL

    const playlist = await Playlist.create(payload);
    res.status(201).json({ message: "Playlist created", playlist });
  } catch (error) {
    res.status(500).json({ message: "Error creating playlist", error: error.message });
  }
};

// 🔍 Lấy playlist của user (luôn dùng id từ JWT để tránh truy cập chéo người dùng)
export const getUserPlaylists = async (req, res) => {
  try {
    const userId = req.user.id; // ignore any params
    const playlists = await Playlist.findAll({
      where: { UserId: userId },
      include: [{ model: Song, as: 'songs' }],
    });
    res.json(playlists);
  } catch (error) {
    res.status(500).json({ message: "Error fetching playlists", error });
  }
};

// 🔍 Admin xem playlist của 1 user bất kỳ
export const adminGetUserPlaylists = async (req, res) => {
  try {
    const { userId } = req.params;
    const playlists = await Playlist.findAll({
      where: { UserId: userId },
      include: [{ model: Song, as: 'songs' }],
    });
    res.json(playlists);
  } catch (error) {
    res.status(500).json({ message: "Error fetching playlists (admin)", error });
  }
};

// ✏️ Cập nhật playlist (đổi tên hoặc di chuyển folder)
export const updatePlaylist = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, folderId } = req.body;
    const userId = req.user.id;

    const playlist = await Playlist.findByPk(id);
    if (!playlist) return res.status(404).json({ message: "Playlist not found" });

    // Verify ownership: playlist must belong to the authenticated user
    if (playlist.UserId !== userId) {
      return res.status(403).json({ message: "You do not have permission to update this playlist" });
    }

    if (name) playlist.name = name;

    if (folderId !== undefined) {
      // Cho phép chuyển playlist ra ngoài gốc bằng null/""/0
      if (folderId === null || folderId === "" || Number(folderId) === 0) {
        playlist.folderId = null;
      } else {
        playlist.folderId = folderId;
      }
    }

    await playlist.save();

    res.json({ message: "Playlist updated", playlist });
  } catch (error) {
    res.status(500).json({ message: "Error updating playlist", error: error.message });
  }
};


// 🖼️ Cập nhật ảnh playlist (multipart field: image)
export const updatePlaylistImage = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    if (!req.file) {
      return res.status(400).json({ message: "Thiếu file ảnh (field: image)" });
    }

    const playlist = await Playlist.findByPk(id);
    if (!playlist) return res.status(404).json({ message: "Playlist not found" });

    // Verify ownership: playlist must belong to the authenticated user
    if (playlist.UserId !== userId) {
      return res.status(403).json({ message: "You do not have permission to update this playlist" });
    }

    // Upload buffer lên Cloudinary
    const result = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        { resource_type: "image", folder: "music_app/playlist_covers" },
        (err, uploadResult) => {
          if (err) return reject(err);
          resolve(uploadResult);
        }
      );
      streamifier.createReadStream(req.file.buffer).pipe(stream);
    });

    playlist.imageUrl = result.secure_url;
    await playlist.save();

    res.json({ message: "Playlist image updated", imageUrl: playlist.imageUrl });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error updating playlist image", error: error.message });
  }
};

// ❌ Xóa playlist
export const deletePlaylist = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const playlist = await Playlist.findByPk(id);
    if (!playlist) return res.status(404).json({ message: "Playlist not found" });

    // Verify ownership: playlist must belong to the authenticated user
    if (playlist.UserId !== userId) {
      return res.status(403).json({ message: "You do not have permission to delete this playlist" });
    }

    await playlist.destroy();
    res.json({ message: "Playlist deleted" });
  } catch (error) {
    res.status(500).json({ message: "Error deleting playlist", error });
  }
};

// ➕ Thêm bài hát vào playlist
export const addSongToPlaylist = async (req, res) => {
  try {
    const { playlistId, songId } = req.params;
    const userId = req.user.id;

    const playlist = await Playlist.findByPk(playlistId);
    const song = await Song.findByPk(songId);

    if (!playlist || !song)
      return res.status(404).json({ message: "Playlist hoặc bài hát không tồn tại" });

    // Verify ownership: playlist must belong to the authenticated user
    if (playlist.UserId !== userId) {
      return res.status(403).json({ message: "You do not have permission to modify this playlist" });
    }

    await playlist.addSong(song);
    res.json({ message: "Thêm bài hát vào playlist thành công" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Lỗi khi thêm bài hát vào playlist", error });
  }
};

// 🎵 Lấy danh sách bài hát trong playlist
export const getSongsInPlaylist = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const playlist = await Playlist.findByPk(id, { include: [Song] });
    if (!playlist) return res.status(404).json({ message: "Playlist not found" });

    // Verify ownership: playlist must belong to the authenticated user
    if (playlist.UserId !== userId) {
      return res.status(403).json({ message: "You do not have permission to view this playlist" });
    }

    res.json(playlist.Songs);
  } catch (error) {
    res.status(500).json({ message: "Error fetching songs in playlist", error });
  }
};

// ➖ Xóa bài hát khỏi playlist
export const removeSongFromPlaylist = async (req, res) => {
  try {
    const { playlistId, songId } = req.params;
    const userId = req.user.id;

    // Verify ownership: playlist must belong to the authenticated user
    const playlist = await Playlist.findByPk(playlistId);
    if (!playlist) {
      return res.status(404).json({ message: "Playlist not found" });
    }
    if (playlist.UserId !== userId) {
      return res.status(403).json({ message: "You do not have permission to modify this playlist" });
    }

    // Kiểm tra tồn tại trước khi xóa
    const existing = await PlaylistSong.findOne({
      where: {
        playlistId: Number(playlistId),
        songId: Number(songId),
      },
    });

    if (!existing) {
      return res.status(404).json({ message: "Bài hát không tồn tại trong playlist" });
    }

    await existing.destroy();

    return res.status(200).json({ message: "Xóa bài hát khỏi playlist thành công" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Lỗi server", error: err.message });
  }
};