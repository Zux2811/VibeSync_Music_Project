import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Album = sequelize.define(
  "Album",
  {
    artistId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      comment: "Reference to User with role='artist'"
    },
    title: {
      type: DataTypes.STRING(200),
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    coverUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      comment: "Album cover image URL"
    },
    releaseDate: {
      type: DataTypes.DATEONLY,
      allowNull: true
    },
    genre: {
      type: DataTypes.STRING(100),
      allowNull: true
    },
    totalTracks: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    totalDuration: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      comment: "Total duration in seconds"
    },
    totalPlays: {
      type: DataTypes.BIGINT,
      allowNull: false,
      defaultValue: 0
    },
    isPublished: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      comment: "Whether album is publicly visible"
    },
    albumType: {
      type: DataTypes.ENUM('album', 'single', 'ep'),
      allowNull: false,
      defaultValue: 'album'
    }
  },
  {
    tableName: "albums",
    timestamps: true
  }
);

export default Album;
