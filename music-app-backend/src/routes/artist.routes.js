import express from "express";
import multer from "multer";
import { authMiddleware, requireRole } from "../middleware/auth.middleware.js";
import {
  getAllArtists,
  getArtistById,
  getArtistSongs,
  getArtistAlbums,
  toggleFollowArtist,
  getMyArtistProfile,
  updateMyArtistProfile,
  uploadArtistImage,
  uploadArtistSong,
  updateArtistSong,
  deleteArtistSong,
  getMySongs,
  createAlbum,
  getMyAlbums,
  updateAlbum,
  deleteAlbum,
  getArtistStats
} from "../controllers/artist.controller.js";

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// ========== PUBLIC ROUTES ==========

// Get all artists
router.get("/", getAllArtists);

// Get artist by ID
router.get("/:id", getArtistById);

// Get artist's songs
router.get("/:id/songs", getArtistSongs);

// Get artist's albums
router.get("/:id/albums", getArtistAlbums);

// ========== AUTHENTICATED ROUTES ==========

// Follow/unfollow artist
router.post("/:id/follow", authMiddleware, toggleFollowArtist);

// ========== ARTIST ONLY ROUTES ==========

// Get my artist profile
router.get("/me/profile", authMiddleware, requireRole(['artist']), getMyArtistProfile);

// Update my artist profile
router.put("/me/profile", authMiddleware, requireRole(['artist']), updateMyArtistProfile);

// Upload artist avatar or cover
router.post("/me/image/:type", authMiddleware, requireRole(['artist']), upload.single('image'), uploadArtistImage);

// Get my songs (including hidden)
router.get("/me/songs", authMiddleware, requireRole(['artist']), getMySongs);

// Upload new song
router.post("/me/songs", authMiddleware, requireRole(['artist']), upload.fields([
  { name: 'audio', maxCount: 1 },
  { name: 'image', maxCount: 1 }
]), uploadArtistSong);

// Update my song
router.put("/me/songs/:id", authMiddleware, requireRole(['artist']), updateArtistSong);

// Delete my song
router.delete("/me/songs/:id", authMiddleware, requireRole(['artist']), deleteArtistSong);

// Get my albums
router.get("/me/albums", authMiddleware, requireRole(['artist']), getMyAlbums);

// Create album
router.post("/me/albums", authMiddleware, requireRole(['artist']), upload.single('cover'), createAlbum);

// Update album
router.put("/me/albums/:id", authMiddleware, requireRole(['artist']), upload.single('cover'), updateAlbum);

// Delete album
router.delete("/me/albums/:id", authMiddleware, requireRole(['artist']), deleteAlbum);

// Get my stats
router.get("/me/stats", authMiddleware, requireRole(['artist']), getArtistStats);

export default router;
