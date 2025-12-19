import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Song = sequelize.define(
  "Song",
  {
    title: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    artist: {
      type: DataTypes.STRING,
      allowNull: false,
      comment: "Artist display name (can be different from artistId user)"
    },
    artistId: {
      type: DataTypes.INTEGER,
      allowNull: true,
      comment: "Reference to User with role='artist' who uploaded this song"
    },
    albumId: {
      type: DataTypes.INTEGER,
      allowNull: true,
      comment: "Reference to Album if part of an album"
    },
    audioUrl: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    imageUrl: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    album: {
      type: DataTypes.STRING,
      allowNull: true,
      comment: "Album name (text field, for backward compatibility)"
    },
    duration: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
      comment: "Duration in seconds"
    },
    genre: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    lyrics: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    playCount: {
      type: DataTypes.BIGINT,
      allowNull: false,
      defaultValue: 0,
    },
    isPublished: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
      comment: "Whether song is publicly visible"
    },
    isExplicit: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    releaseDate: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    }
  },
  {
    tableName: "songs",
    timestamps: true,
  }
);

export default Song;
