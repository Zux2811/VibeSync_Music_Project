// // src/models/index.js
// import User from "./user.model.js";
// import Song from "./song.model.js";
// import Playlist from "./playlist.model.js";
// import PlaylistSong from "./playlistSong.model.js";
// import Comment from "./comment.model.js";
// import UserProfile from "./userProfile.model.js";
// import Folder from "./folder.model.js";

// // Associations (giữ giống cấu trúc bạn có)
// User.hasOne(UserProfile, { foreignKey: "user_id" });
// UserProfile.belongsTo(User, { foreignKey: "user_id" });

// User.hasMany(Playlist, { onDelete: "CASCADE" });
// Playlist.belongsTo(User);

// User.hasMany(Folder, { onDelete: "CASCADE" });
// Folder.belongsTo(User);

// Playlist.belongsToMany(Song, {
//   through: PlaylistSong,
//   foreignKey: "playlistId",
//   otherKey: "songId",
// });
// Song.belongsToMany(Playlist, {
//   through: PlaylistSong,
//   foreignKey: "songId",
//   otherKey: "playlistId",
// });

// User.hasMany(Comment, { foreignKey: "user_id" });
// Comment.belongsTo(User, { foreignKey: "user_id" });

// Song.hasMany(Comment, { foreignKey: "song_id" });
// Comment.belongsTo(Song, { foreignKey: "song_id" });

// Playlist.hasMany(Comment, { foreignKey: "playlist_id" });
// Comment.belongsTo(Playlist, { foreignKey: "playlist_id" });

// export {
//   User,
//   Song,
//   Playlist,
//   PlaylistSong,
//   Comment,
//   UserProfile,
//   Folder,
// };

// src/models/index.js

// src/models/index.js
import User from "./user.model.js";
import Song from "./song.model.js";
import Playlist from "./playlist.model.js";
import PlaylistSong from "./playlistSong.model.js";
import Comment from "./comment.model.js";
import UserProfile from "./userProfile.model.js";
import Folder from "./folder.model.js";
import Report from "./report.model.js";
import Favorite from "./favorite.model.js";
import CommentLike from "./commentLike.model.js";
import Tier from "./tier.model.js";
import UserSubscription from "./userSubscription.model.js";
import PasswordReset from "./passwordReset.model.js";

// Associations

// Subscription relations
User.hasMany(UserSubscription, { foreignKey: 'userId', onDelete: 'CASCADE' });
UserSubscription.belongsTo(User, { foreignKey: 'userId', constraints: false });
Tier.hasMany(UserSubscription, { foreignKey: 'tierId', onDelete: 'CASCADE' });
UserSubscription.belongsTo(Tier, { foreignKey: 'tierId', constraints: false });

// Password reset codes (temporary, one per user)
User.hasOne(PasswordReset, { foreignKey: 'userId', onDelete: 'CASCADE' });
PasswordReset.belongsTo(User, { foreignKey: 'userId', constraints: false });

// User profile
User.hasOne(UserProfile, { foreignKey: "user_id", as: "profile", onDelete: "CASCADE" });
UserProfile.belongsTo(User, { foreignKey: "user_id", constraints: false });

// Relationships to User - turn off some constraints to avoid "max 64 keys" error
User.hasMany(Playlist, { foreignKey: "UserId", onDelete: "CASCADE" });
Playlist.belongsTo(User, { foreignKey: "UserId", constraints: false }); // Optimization

User.hasMany(Folder, { foreignKey: "UserId", onDelete: "CASCADE" });
Folder.belongsTo(User, { foreignKey: "UserId", constraints: false }); // Optimization

// Comments ↔ Users (alias to disambiguate from like relation)
User.hasMany(Comment, { foreignKey: "user_id", as: "comments" });
Comment.belongsTo(User, { foreignKey: "user_id", as: "user", constraints: false });

// Reports ↔ Users (alias for include)
User.hasMany(Report, { foreignKey: "userId", as: "reports" });
Report.belongsTo(User, { foreignKey: "userId", as: "user", constraints: false });

User.hasMany(Favorite, { foreignKey: "userId", onDelete: "CASCADE" });
Favorite.belongsTo(User, { foreignKey: "userId", constraints: false }); // Optimization

// --- Other Relationships ---

// Folder-Playlist relation
Folder.hasMany(Playlist, { foreignKey: 'folderId', onDelete: 'SET NULL' });
Playlist.belongsTo(Folder, { foreignKey: 'folderId' });

// Self-referencing for nested folders
// A Folder can have many SubFolders (children)
Folder.hasMany(Folder, { as: 'SubFolders', foreignKey: 'parentId', onDelete: 'CASCADE' });

// A Folder belongs to one Parent Folder
Folder.belongsTo(Folder, { as: 'Parent', foreignKey: 'parentId' });

// Use explicit aliases so included data keys are lowercased as expected by mobile app
Playlist.belongsToMany(Song, {
  through: PlaylistSong,
  foreignKey: "playlistId",
  otherKey: "songId",
  as: 'songs',
});
Song.belongsToMany(Playlist, {
  through: PlaylistSong,
  foreignKey: "songId",
  otherKey: "playlistId",
  as: 'playlists',
});

Song.hasMany(Comment, { foreignKey: "song_id" });
Comment.belongsTo(Song, { foreignKey: "song_id" });

Playlist.hasMany(Comment, { foreignKey: "playlist_id" });
Comment.belongsTo(Playlist, { foreignKey: "playlist_id" });

// Reports ↔ Comments with alias for admin includes
Comment.hasMany(Report, { foreignKey: "commentId", as: "reports" });
Report.belongsTo(Comment, { foreignKey: "commentId", as: "comment" });

Song.hasMany(Favorite, { foreignKey: "songId", onDelete: "CASCADE" });
Favorite.belongsTo(Song, { foreignKey: "songId" });

// COMMENT LIKES (through table) - give explicit aliases to avoid ambiguity
User.belongsToMany(Comment, {
  through: CommentLike,
  foreignKey: "userId",
  otherKey: "commentId",
  as: 'likedComments',
});
Comment.belongsToMany(User, {
  through: CommentLike,
  foreignKey: "commentId",
  otherKey: "userId",
  as: 'likedBy',
});

export {
  User,
  Song,
  Playlist,
  PlaylistSong,
  Comment,
  UserProfile,
  Folder,
  Report,
  Favorite,
  CommentLike,
  PasswordReset,
};
