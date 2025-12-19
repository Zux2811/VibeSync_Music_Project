import { User, Song, Album, ArtistProfile, ArtistFollow, UserProfile } from "../models/index.js";
import cloudinary from "../config/cloudinary.js";
import { Readable } from "stream";
import logger from "../utils/logger.js";
import { Op } from "sequelize";

// Convert buffer to stream for Cloudinary
function bufferToStream(buffer) {
  const readable = new Readable();
  readable.push(buffer);
  readable.push(null);
  return readable;
}

// ===============================
// 🎤 Get all artists (public)
// ===============================
export const getAllArtists = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;

    const { count, rows: artists } = await User.findAndCountAll({
      where: { role: 'artist' },
      attributes: ['id', 'username', 'email'],
      include: [{
        model: ArtistProfile,
        as: 'artistProfile',
        attributes: ['stageName', 'bio', 'avatarUrl', 'coverUrl', 'totalFollowers', 'totalPlays', 'verified', 'genres', 'socialLinks']
      }],
      offset,
      limit,
      order: [['createdAt', 'DESC']]
    });

    const totalPages = Math.ceil(count / limit);

    res.json({
      items: artists,
      page,
      limit,
      total: count,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1
    });
  } catch (error) {
    logger.error("Error fetching artists", error);
    res.status(500).json({ message: "Error fetching artists", error: error.message });
  }
};

// ===============================
// 🎤 Get artist by ID (public)
// ===============================
export const getArtistById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id; // May be null if not logged in

    const artist = await User.findOne({
      where: { id, role: 'artist' },
      attributes: ['id', 'username', 'email', 'createdAt'],
      include: [{
        model: ArtistProfile,
        as: 'artistProfile'
      }]
    });

    if (!artist) {
      return res.status(404).json({ message: "Artist not found" });
    }

    // Check if current user is following this artist
    let isFollowing = false;
    if (userId) {
      const follow = await ArtistFollow.findOne({
        where: { followerId: userId, artistId: id }
      });
      isFollowing = !!follow;
    }

    // Get song count and album count
    const songCount = await Song.count({ where: { artistId: id, isPublished: true } });
    const albumCount = await Album.count({ where: { artistId: id, isPublished: true } });

    res.json({
      ...artist.toJSON(),
      songCount,
      albumCount,
      isFollowing
    });
  } catch (error) {
    logger.error("Error fetching artist", error);
    res.status(500).json({ message: "Error fetching artist", error: error.message });
  }
};

// ===============================
// 🎤 Get artist's songs (public)
// ===============================
export const getArtistSongs = async (req, res) => {
  try {
    const { id } = req.params;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;

    // Verify artist exists
    const artist = await User.findOne({ where: { id, role: 'artist' } });
    if (!artist) {
      return res.status(404).json({ message: "Artist not found" });
    }

    const { count, rows: songs } = await Song.findAndCountAll({
      where: { artistId: id, isPublished: true },
      include: [{
        model: Album,
        as: 'albumRef',
        attributes: ['id', 'title', 'coverUrl']
      }],
      offset,
      limit,
      order: [['createdAt', 'DESC']]
    });

    const totalPages = Math.ceil(count / limit);

    res.json({
      items: songs,
      page,
      limit,
      total: count,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1
    });
  } catch (error) {
    logger.error("Error fetching artist songs", error);
    res.status(500).json({ message: "Error fetching songs", error: error.message });
  }
};

// ===============================
// 🎤 Get artist's albums (public)
// ===============================
export const getArtistAlbums = async (req, res) => {
  try {
    const { id } = req.params;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;

    const { count, rows: albums } = await Album.findAndCountAll({
      where: { artistId: id, isPublished: true },
      offset,
      limit,
      order: [['releaseDate', 'DESC']]
    });

    const totalPages = Math.ceil(count / limit);

    res.json({
      items: albums,
      page,
      limit,
      total: count,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1
    });
  } catch (error) {
    logger.error("Error fetching artist albums", error);
    res.status(500).json({ message: "Error fetching albums", error: error.message });
  }
};

// ===============================
// 🎤 Follow/Unfollow artist
// ===============================
export const toggleFollowArtist = async (req, res) => {
  try {
    const { id: artistId } = req.params;
    const followerId = req.user.id;

    // Can't follow yourself
    if (parseInt(artistId) === followerId) {
      return res.status(400).json({ message: "Cannot follow yourself" });
    }

    // Verify artist exists
    const artist = await User.findOne({ where: { id: artistId, role: 'artist' } });
    if (!artist) {
      return res.status(404).json({ message: "Artist not found" });
    }

    // Check existing follow
    const existingFollow = await ArtistFollow.findOne({
      where: { followerId, artistId }
    });

    if (existingFollow) {
      // Unfollow
      await existingFollow.destroy();
      
      // Update follower count
      await ArtistProfile.decrement('totalFollowers', { where: { userId: artistId } });
      
      res.json({ message: "Unfollowed successfully", isFollowing: false });
    } else {
      // Follow
      await ArtistFollow.create({ followerId, artistId });
      
      // Update follower count
      await ArtistProfile.increment('totalFollowers', { where: { userId: artistId } });
      
      res.json({ message: "Followed successfully", isFollowing: true });
    }
  } catch (error) {
    logger.error("Error toggling follow", error);
    res.status(500).json({ message: "Error toggling follow", error: error.message });
  }
};

// ===============================
// 🎤 Get my artist profile (for artists)
// ===============================
export const getMyArtistProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if user is an artist
    const user = await User.findByPk(userId);
    if (!user || user.role !== 'artist') {
      return res.status(403).json({ message: "Not an artist account" });
    }

    let profile = await ArtistProfile.findOne({ where: { userId } });
    
    if (!profile) {
      // Create default profile
      profile = await ArtistProfile.create({
        userId,
        stageName: user.username,
        bio: '',
        socialLinks: {}
      });
    }

    res.json(profile);
  } catch (error) {
    logger.error("Error fetching artist profile", error);
    res.status(500).json({ message: "Error fetching profile", error: error.message });
  }
};

// ===============================
// 🎤 Update my artist profile
// ===============================
export const updateMyArtistProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { stageName, bio, socialLinks, contactEmail, country, genres } = req.body;

    // Check if user is an artist
    const user = await User.findByPk(userId);
    if (!user || user.role !== 'artist') {
      return res.status(403).json({ message: "Not an artist account" });
    }

    let profile = await ArtistProfile.findOne({ where: { userId } });
    
    if (!profile) {
      profile = await ArtistProfile.create({
        userId,
        stageName: stageName || user.username,
        bio,
        socialLinks,
        contactEmail,
        country,
        genres
      });
    } else {
      await profile.update({
        stageName: stageName || profile.stageName,
        bio: bio !== undefined ? bio : profile.bio,
        socialLinks: socialLinks !== undefined ? socialLinks : profile.socialLinks,
        contactEmail: contactEmail !== undefined ? contactEmail : profile.contactEmail,
        country: country !== undefined ? country : profile.country,
        genres: genres !== undefined ? genres : profile.genres
      });
    }

    res.json({ message: "Profile updated", profile });
  } catch (error) {
    logger.error("Error updating artist profile", error);
    res.status(500).json({ message: "Error updating profile", error: error.message });
  }
};

// ===============================
// 🎤 Upload artist avatar/cover
// ===============================
export const uploadArtistImage = async (req, res) => {
  try {
    const userId = req.user.id;
    const { type } = req.params; // 'avatar' or 'cover'

    if (!['avatar', 'cover'].includes(type)) {
      return res.status(400).json({ message: "Invalid image type. Use 'avatar' or 'cover'" });
    }

    // Check if user is an artist
    const user = await User.findByPk(userId);
    if (!user || user.role !== 'artist') {
      return res.status(403).json({ message: "Not an artist account" });
    }

    if (!req.file) {
      return res.status(400).json({ message: "No image file provided" });
    }

    const imageBuffer = req.file.buffer;

    // Upload to Cloudinary
    const imageUrl = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: `artist-${type}s`,
          resource_type: "image",
        },
        (err, result) => {
          if (err) return reject(err);
          resolve(result.secure_url);
        }
      );
      bufferToStream(imageBuffer).pipe(stream);
    });

    // Update profile
    const updateField = type === 'avatar' ? 'avatarUrl' : 'coverUrl';
    await ArtistProfile.update(
      { [updateField]: imageUrl },
      { where: { userId } }
    );

    res.json({ message: `${type} uploaded successfully`, url: imageUrl });
  } catch (error) {
    logger.error("Error uploading artist image", error);
    res.status(500).json({ message: "Error uploading image", error: error.message });
  }
};

// ===============================
// 🎤 Artist uploads a new song
// ===============================
export const uploadArtistSong = async (req, res) => {
  try {
    const userId = req.user.id;
    const { title, genre, lyrics, albumId, releaseDate, isExplicit } = req.body;

    // Check if user is an artist
    const user = await User.findByPk(userId, {
      include: [{ model: ArtistProfile, as: 'artistProfile' }]
    });
    if (!user || user.role !== 'artist') {
      return res.status(403).json({ message: "Not an artist account" });
    }

    if (!req.files || !req.files.audio) {
      return res.status(400).json({ message: "Audio file is required" });
    }

    const audioBuffer = req.files.audio[0].buffer;
    const imageBuffer = req.files.image ? req.files.image[0].buffer : null;

    // Upload cover image if provided
    let imageUrl = null;
    if (imageBuffer) {
      imageUrl = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: "artist-song-covers", resource_type: "image" },
          (err, result) => {
            if (err) return reject(err);
            resolve(result.secure_url);
          }
        );
        bufferToStream(imageBuffer).pipe(stream);
      });
    }

    // Upload audio
    const audioUrl = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        { folder: "artist-songs", resource_type: "video" },
        (err, result) => {
          if (err) return reject(err);
          resolve(result.secure_url);
        }
      );
      bufferToStream(audioBuffer).pipe(stream);
    });

    // Get artist name from profile
    const artistName = user.artistProfile?.stageName || user.username;

    // Create song
    const newSong = await Song.create({
      title,
      artist: artistName,
      artistId: userId,
      albumId: albumId || null,
      audioUrl,
      imageUrl,
      genre,
      lyrics,
      releaseDate,
      isExplicit: isExplicit === 'true' || isExplicit === true,
      isPublished: true
    });

    // If part of album, update album track count
    if (albumId) {
      await Album.increment('totalTracks', { where: { id: albumId } });
    }

    logger.info("Artist uploaded song", { artistId: userId, songId: newSong.id });
    res.status(201).json({ message: "Song uploaded successfully", song: newSong });
  } catch (error) {
    logger.error("Error uploading artist song", error);
    res.status(500).json({ message: "Error uploading song", error: error.message });
  }
};

// ===============================
// 🎤 Artist updates their song
// ===============================
export const updateArtistSong = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { title, genre, lyrics, albumId, releaseDate, isExplicit, isPublished } = req.body;

    const song = await Song.findByPk(id);
    if (!song) {
      return res.status(404).json({ message: "Song not found" });
    }

    // Check ownership
    if (song.artistId !== userId) {
      return res.status(403).json({ message: "You can only edit your own songs" });
    }

    await song.update({
      title: title || song.title,
      genre: genre !== undefined ? genre : song.genre,
      lyrics: lyrics !== undefined ? lyrics : song.lyrics,
      albumId: albumId !== undefined ? albumId : song.albumId,
      releaseDate: releaseDate !== undefined ? releaseDate : song.releaseDate,
      isExplicit: isExplicit !== undefined ? isExplicit : song.isExplicit,
      isPublished: isPublished !== undefined ? isPublished : song.isPublished
    });

    res.json({ message: "Song updated", song });
  } catch (error) {
    logger.error("Error updating artist song", error);
    res.status(500).json({ message: "Error updating song", error: error.message });
  }
};

// ===============================
// 🎤 Artist deletes their song
// ===============================
export const deleteArtistSong = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const song = await Song.findByPk(id);
    if (!song) {
      return res.status(404).json({ message: "Song not found" });
    }

    // Check ownership
    if (song.artistId !== userId) {
      return res.status(403).json({ message: "You can only delete your own songs" });
    }

    const albumId = song.albumId;
    await song.destroy();

    // Update album track count if was part of album
    if (albumId) {
      await Album.decrement('totalTracks', { where: { id: albumId } });
    }

    res.json({ message: "Song deleted successfully" });
  } catch (error) {
    logger.error("Error deleting artist song", error);
    res.status(500).json({ message: "Error deleting song", error: error.message });
  }
};

// ===============================
// 🎤 Get my songs (for artist)
// ===============================
export const getMySongs = async (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;
    const includeHidden = req.query.includeHidden === 'true';

    const whereClause = { artistId: userId };
    if (!includeHidden) {
      whereClause.isPublished = true;
    }

    const { count, rows: songs } = await Song.findAndCountAll({
      where: whereClause,
      include: [{
        model: Album,
        as: 'albumRef',
        attributes: ['id', 'title', 'coverUrl']
      }],
      offset,
      limit,
      order: [['createdAt', 'DESC']]
    });

    const totalPages = Math.ceil(count / limit);

    res.json({
      items: songs,
      page,
      limit,
      total: count,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1
    });
  } catch (error) {
    logger.error("Error fetching my songs", error);
    res.status(500).json({ message: "Error fetching songs", error: error.message });
  }
};

// ===============================
// 🎤 Create album
// ===============================
export const createAlbum = async (req, res) => {
  try {
    const userId = req.user.id;
    const { title, description, genre, releaseDate, albumType } = req.body;

    // Check if user is an artist
    const user = await User.findByPk(userId);
    if (!user || user.role !== 'artist') {
      return res.status(403).json({ message: "Not an artist account" });
    }

    // Upload cover if provided
    let coverUrl = null;
    if (req.file) {
      coverUrl = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: "album-covers", resource_type: "image" },
          (err, result) => {
            if (err) return reject(err);
            resolve(result.secure_url);
          }
        );
        bufferToStream(req.file.buffer).pipe(stream);
      });
    }

    const album = await Album.create({
      artistId: userId,
      title,
      description,
      coverUrl,
      genre,
      releaseDate,
      albumType: albumType || 'album',
      isPublished: false // Draft by default
    });

    res.status(201).json({ message: "Album created", album });
  } catch (error) {
    logger.error("Error creating album", error);
    res.status(500).json({ message: "Error creating album", error: error.message });
  }
};

// ===============================
// 🎤 Get my albums
// ===============================
export const getMyAlbums = async (req, res) => {
  try {
    const userId = req.user.id;
    const includeUnpublished = req.query.includeUnpublished === 'true';

    const whereClause = { artistId: userId };
    if (!includeUnpublished) {
      whereClause.isPublished = true;
    }

    const albums = await Album.findAll({
      where: whereClause,
      include: [{
        model: Song,
        as: 'tracks',
        attributes: ['id', 'title', 'duration', 'imageUrl'],
        where: { isPublished: true },
        required: false
      }],
      order: [['createdAt', 'DESC']]
    });

    res.json(albums);
  } catch (error) {
    logger.error("Error fetching my albums", error);
    res.status(500).json({ message: "Error fetching albums", error: error.message });
  }
};

// ===============================
// 🎤 Update album
// ===============================
export const updateAlbum = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { title, description, genre, releaseDate, albumType, isPublished } = req.body;

    const album = await Album.findByPk(id);
    if (!album) {
      return res.status(404).json({ message: "Album not found" });
    }

    if (album.artistId !== userId) {
      return res.status(403).json({ message: "You can only edit your own albums" });
    }

    // Upload new cover if provided
    let coverUrl = album.coverUrl;
    if (req.file) {
      coverUrl = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: "album-covers", resource_type: "image" },
          (err, result) => {
            if (err) return reject(err);
            resolve(result.secure_url);
          }
        );
        bufferToStream(req.file.buffer).pipe(stream);
      });
    }

    await album.update({
      title: title || album.title,
      description: description !== undefined ? description : album.description,
      coverUrl,
      genre: genre !== undefined ? genre : album.genre,
      releaseDate: releaseDate !== undefined ? releaseDate : album.releaseDate,
      albumType: albumType || album.albumType,
      isPublished: isPublished !== undefined ? isPublished : album.isPublished
    });

    res.json({ message: "Album updated", album });
  } catch (error) {
    logger.error("Error updating album", error);
    res.status(500).json({ message: "Error updating album", error: error.message });
  }
};

// ===============================
// 🎤 Delete album
// ===============================
export const deleteAlbum = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const album = await Album.findByPk(id);
    if (!album) {
      return res.status(404).json({ message: "Album not found" });
    }

    if (album.artistId !== userId) {
      return res.status(403).json({ message: "You can only delete your own albums" });
    }

    // Remove album reference from songs (don't delete songs)
    await Song.update({ albumId: null }, { where: { albumId: id } });

    await album.destroy();

    res.json({ message: "Album deleted successfully" });
  } catch (error) {
    logger.error("Error deleting album", error);
    res.status(500).json({ message: "Error deleting album", error: error.message });
  }
};

// ===============================
// 🎤 Get artist stats
// ===============================
export const getArtistStats = async (req, res) => {
  try {
    const userId = req.user.id;

    const profile = await ArtistProfile.findOne({ where: { userId } });
    const totalSongs = await Song.count({ where: { artistId: userId } });
    const totalAlbums = await Album.count({ where: { artistId: userId } });
    const totalPlays = await Song.sum('playCount', { where: { artistId: userId } }) || 0;

    res.json({
      totalFollowers: profile?.totalFollowers || 0,
      totalPlays,
      totalSongs,
      totalAlbums,
      verified: profile?.verified || false
    });
  } catch (error) {
    logger.error("Error fetching artist stats", error);
    res.status(500).json({ message: "Error fetching stats", error: error.message });
  }
};
