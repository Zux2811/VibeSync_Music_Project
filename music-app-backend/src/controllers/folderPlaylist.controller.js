import Playlist from "../models/playlist.model.js";
import Folder from "../models/folder.model.js";

// 🟢 Thêm playlist vào folder
export const addPlaylistToFolder = async (req, res) => {
  try {
    const { folderId, playlistId } = req.params;

    const folder = await Folder.findByPk(folderId);
    const playlist = await Playlist.findByPk(playlistId);

    if (!folder || !playlist) {
      return res.status(404).json({ message: "Folder hoặc Playlist không tồn tại" });
    }

    playlist.folderId = folderId;
    await playlist.save();

    res.status(200).json({ message: "Đã thêm playlist vào folder thành công", playlist });
  } catch (error) {
    console.error("Error adding playlist to folder:", error);
    res.status(500).json({ message: "Lỗi khi thêm playlist vào folder", error: error.message });
  }
};

// 🟡 Lấy tất cả playlist trong folder
export const getPlaylistsInFolder = async (req, res) => {
  try {
    const { folderId } = req.params;

    const folder = await Folder.findByPk(folderId, {
      include: [{ model: Playlist }],
    });

    if (!folder) {
      return res.status(404).json({ message: "Folder không tồn tại" });
    }

    res.status(200).json(folder.Playlists);
  } catch (error) {
    console.error("Error fetching playlists in folder:", error);
    res.status(500).json({ message: "Lỗi khi lấy danh sách playlist trong folder", error: error.message });
  }
};

// 🔴 Gỡ playlist khỏi folder
export const removePlaylistFromFolder = async (req, res) => {
  try {
    const { playlistId } = req.params;

    const playlist = await Playlist.findByPk(playlistId);
    if (!playlist) {
      return res.status(404).json({ message: "Không tìm thấy playlist" });
    }

    playlist.folderId = null;
    await playlist.save();

    res.status(200).json({ message: "Đã gỡ playlist khỏi folder" });
  } catch (error) {
    console.error("Error removing playlist from folder:", error);
    res.status(500).json({ message: "Lỗi khi gỡ playlist khỏi folder", error: error.message });
  }
};
