import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const ArtistProfile = sequelize.define(
  "ArtistProfile",
  {
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      unique: true,
      comment: "Reference to User with role='artist'"
    },
    stageName: {
      type: DataTypes.STRING(100),
      allowNull: false,
      comment: "Artist stage name / display name"
    },
    bio: {
      type: DataTypes.TEXT,
      allowNull: true,
      comment: "Artist biography/description"
    },
    avatarUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      comment: "Artist profile image URL"
    },
    coverUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      comment: "Artist cover/banner image URL"
    },
    // Social links stored as JSON
    socialLinks: {
      type: DataTypes.JSON,
      allowNull: true,
      defaultValue: {},
      comment: "Social media links: {facebook, youtube, spotify, instagram, twitter, website}"
    },
    totalFollowers: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    totalPlays: {
      type: DataTypes.BIGINT,
      allowNull: false,
      defaultValue: 0,
      comment: "Total plays across all songs"
    },
    verified: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      comment: "Whether artist is officially verified"
    },
    contactEmail: {
      type: DataTypes.STRING(255),
      allowNull: true,
      comment: "Business contact email"
    },
    country: {
      type: DataTypes.STRING(100),
      allowNull: true
    },
    genres: {
      type: DataTypes.JSON,
      allowNull: true,
      defaultValue: [],
      comment: "Array of genre strings"
    }
  },
  {
    tableName: "artist_profiles",
    timestamps: true
  }
);

export default ArtistProfile;
