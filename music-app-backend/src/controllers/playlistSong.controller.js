import Playlist from "../models/playlist.model.js";
import Song from "../models/song.model.js";
import PlaylistSong from "../models/playlistSong.model.js";

// 🎵 Thêm bài hát vào playlist
export const addSongToPlaylist = async (req, res) => {
  try {
    const { playlistId } = req.params;
    const { songId } = req.body;

    // Kiểm tra playlist và bài hát có tồn tại không
    const playlist = await Playlist.findByPk(playlistId);
    const song = await Song.findByPk(songId);

    if (!playlist || !song) {
      return res.status(404).json({ message: "Playlist hoặc bài hát không tồn tại" });
    }

    // Kiểm tra xem bài hát đã tồn tại trong playlist chưa
    const existing = await PlaylistSong.findOne({
      where: { playlistId, songId },
    });

    if (existing) {
      return res.status(400).json({ message: "Bài hát đã có trong playlist" });
    }

    // Thêm bài hát vào playlist
    await PlaylistSong.create({ playlistId, songId });
    res.status(201).json({ message: "Đã thêm bài hát vào playlist" });
  } catch (error) {
    console.error("Error adding song to playlist:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// ❌ Xóa bài hát khỏi playlist
export const removeSongFromPlaylist = async (req, res) => {
  try {
    const { playlistId, songId } = req.params;

    const deleted = await PlaylistSong.destroy({
      where: { playlistId, songId },
    });

    if (!deleted) {
      return res.status(404).json({ message: "Bài hát không tồn tại trong playlist" });
    }

    res.json({ message: "Đã xóa bài hát khỏi playlist" });
  } catch (error) {
    console.error("Error removing song from playlist:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// 📜 Lấy danh sách bài hát trong playlist
export const getSongsInPlaylist = async (req, res) => {
  try {
    const { playlistId } = req.params;

    const playlist = await Playlist.findByPk(playlistId, {
      include: [
        {
          model: Song,
          through: { attributes: [] }, // Bỏ cột trung gian
        },
      ],
    });

    if (!playlist) {
      return res.status(404).json({ message: "Không tìm thấy playlist" });
    }

    res.json(playlist.Songs);
  } catch (error) {
    console.error("Error fetching songs from playlist:", error);
    res.status(500).json({ message: "Server error" });
  }
};
