import Folder from "../models/folder.model.js";
import Playlist from "../models/playlist.model.js";
import Song from "../models/song.model.js"; // Import Song model

// Cấu trúc include đệ quy để lấy thư mục con, playlist, và các bài hát trong playlist
const includeNestedFolders = (level = 4) => {
  const playlistInclude = {
    model: Playlist,
    include: [{
      model: Song, // Include songs in each playlist
      as: 'songs', // Make sure this alias matches the one in Playlist model
      through: { attributes: [] }, // Exclude join table attributes
    }],
  };

  if (level <= 0) {
    return [playlistInclude];
  }

  return [
    playlistInclude,
    {
      model: Folder,
      as: "SubFolders",
      include: includeNestedFolders(level - 1), // Đệ quy
    },
  ];
};

// 🟢 Create a new folder (supports nesting)
export const createFolder = async (req, res) => {
  try {
    const { name, parentId } = req.body;
    const userId = req.user.id;

    const folderData = { name, UserId: userId };
    if (parentId) {
      folderData.parentId = parentId;
    }

    const folder = await Folder.create(folderData);
    res.status(201).json(folder);
  } catch (error) {
    console.error("Error creating folder:", error);
    res.status(500).json({ message: "Lỗi khi tạo folder", error: error.message });
  }
};

// 🟡 Get all folders for a user (nested structure) + root playlists (folderId=null)
export const getFolders = async (req, res) => {
  try {
    const userId = req.user.id;
    const folders = await Folder.findAll({
      where: { UserId: userId, parentId: null }, // Fetch only top-level folders
      include: includeNestedFolders(),
      order: [["name", "ASC"]], // Optional: sort folders
    });

    // Also return playlists that are not inside any folder (folderId IS NULL)
    const { default: Playlist } = await import("../models/playlist.model.js");
    const { default: Song } = await import("../models/song.model.js");

    const rootPlaylists = await Playlist.findAll({
      where: { UserId: userId, folderId: null },
      include: [{ model: Song, as: 'songs', through: { attributes: [] } }],
      order: [["name", "ASC"]],
    });

    res.status(200).json({ folders, rootPlaylists });
  } catch (error) {
    console.error("Error fetching folders:", error);
    res.status(500).json({ message: "Lỗi khi lấy danh sách folder", error: error.message });
  }
};

// 🟠 Update a folder (rename or move)
export const updateFolder = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, parentId } = req.body;

    const folder = await Folder.findOne({ where: { id, UserId: req.user.id } });
    if (!folder) {
      return res.status(404).json({ message: "Không tìm thấy folder" });
    }

    if (name) {
      folder.name = name;
    }

    // Handle moving folder
    if (parentId !== undefined) {
      // Normalize parentId: allow null, "null", empty, 0, "0" => move to root
      const isNullish = parentId === null || parentId === '' || parentId === 0 || parentId === '0' || (typeof parentId === 'string' && parentId.toLowerCase() === 'null');
      if (isNullish) {
        folder.parentId = null;
      } else {
        // Prevent setting parentId to itself
        if (String(parentId) === String(id)) {
          return res.status(400).json({ message: "Không thể di chuyển folder vào chính nó" });
        }
        folder.parentId = parentId;
      }
    }

    await folder.save();
    res.status(200).json(folder);
  } catch (error) {
    console.error("Error updating folder:", error);
    res.status(500).json({ message: "Lỗi khi cập nhật folder", error: error.message });
  }
};

// 🔴 Delete a folder (cascade will handle sub-folders and playlists)
export const deleteFolder = async (req, res) => {
  try {
    const { id } = req.params;

    const folder = await Folder.findOne({ where: { id, UserId: req.user.id } });
    if (!folder) {
      return res.status(404).json({ message: "Không tìm thấy folder" });
    }

    await folder.destroy();
    res.status(200).json({ message: "Đã xóa folder thành công" });
  } catch (error) {
    console.error("Error deleting folder:", error);
    res.status(500).json({ message: "Lỗi khi xóa folder", error: error.message });
  }
};
