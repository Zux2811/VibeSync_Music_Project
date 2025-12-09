import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Playlist = sequelize.define(
  "Playlist",
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    name: { type: DataTypes.STRING, allowNull: false },
    folderId: { type: DataTypes.INTEGER, allowNull: true }, // Foreign key to Folder
    UserId: { type: DataTypes.INTEGER, allowNull: false }, // ✅ Foreign key to User
    imageUrl: { type: DataTypes.STRING, allowNull: true }, // ✅ thumbnail for playlist
  },
  {
    tableName: "playlists",
    timestamps: true,
  }
);

export default Playlist;
