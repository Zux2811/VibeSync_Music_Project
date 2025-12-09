import Favorite from "../models/favorite.model.js";
import Song from "../models/song.model.js";

// GET /api/favorites -> return array of songIds for current user
export const getFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const rows = await Favorite.findAll({ where: { userId } });
    const ids = rows.map((r) => r.songId);
    return res.json(ids);
  } catch (err) {
    return res.status(500).json({ message: "Error fetching favorites", error: err.message });
  }
};

// POST /api/favorites { songId }
export const addFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { songId } = req.body;
    if (!songId) return res.status(400).json({ message: "songId is required" });
    // Ensure song exists (optional but safer)
    const song = await Song.findByPk(songId);
    if (!song) return res.status(404).json({ message: "Song not found" });

    await Favorite.findOrCreate({ where: { userId, songId }, defaults: { userId, songId } });
    return res.status(201).json({ message: "Added to favorites", songId });
  } catch (err) {
    return res.status(500).json({ message: "Error adding favorite", error: err.message });
  }
};

// DELETE /api/favorites/:songId
export const removeFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { songId } = req.params;
    const deleted = await Favorite.destroy({ where: { userId, songId } });
    if (!deleted) return res.status(404).json({ message: "Favorite not found" });
    return res.json({ message: "Removed from favorites", songId: Number(songId) });
  } catch (err) {
    return res.status(500).json({ message: "Error removing favorite", error: err.message });
  }
};

// GET /api/favorites/songs -> return full song records for current user's favorites
export const getFavoriteSongs = async (req, res) => {
  try {
    const userId = req.user.id;
    const favorites = await Favorite.findAll({
      where: { userId },
      include: [{ model: Song, attributes: ['id', 'title', 'artist', 'audioUrl', 'imageUrl', 'album', 'duration'] }],
    });
    const songs = favorites.map((fav) => fav.Song).filter((song) => song !== null);
    return res.json(songs);
  } catch (err) {
    return res.status(500).json({ message: "Error fetching favorite songs", error: err.message });
  }
};

