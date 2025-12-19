import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const ArtistVerification = sequelize.define(
  "ArtistVerification",
  {
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      comment: "User requesting artist verification"
    },
    stageName: {
      type: DataTypes.STRING(100),
      allowNull: false,
      comment: "Requested stage name"
    },
    realName: {
      type: DataTypes.STRING(200),
      allowNull: true,
      comment: "Real name for verification"
    },
    bio: {
      type: DataTypes.TEXT,
      allowNull: true,
      comment: "Artist bio/description"
    },
    // Social links for verification
    facebookUrl: {
      type: DataTypes.STRING(500),
      allowNull: true
    },
    youtubeUrl: {
      type: DataTypes.STRING(500),
      allowNull: true
    },
    spotifyUrl: {
      type: DataTypes.STRING(500),
      allowNull: true
    },
    instagramUrl: {
      type: DataTypes.STRING(500),
      allowNull: true
    },
    websiteUrl: {
      type: DataTypes.STRING(500),
      allowNull: true
    },
    // Links to released songs for proof
    releasedSongLinks: {
      type: DataTypes.JSON,
      allowNull: true,
      defaultValue: [],
      comment: "Array of links to songs already released on platforms"
    },
    // Identity documents
    idDocumentUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      comment: "URL to uploaded ID document (CMND/CCCD)"
    },
    authorizationDocUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      comment: "URL to authorization document if applicable"
    },
    profileImageUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      comment: "Uploaded profile image for verification"
    },
    contactEmail: {
      type: DataTypes.STRING(255),
      allowNull: false,
      comment: "Contact email for communication"
    },
    contactPhone: {
      type: DataTypes.STRING(20),
      allowNull: true
    },
    // Status tracking
    status: {
      type: DataTypes.ENUM('pending', 'approved', 'rejected'),
      allowNull: false,
      defaultValue: 'pending'
    },
    adminNotes: {
      type: DataTypes.TEXT,
      allowNull: true,
      comment: "Notes from admin when reviewing"
    },
    rejectionReason: {
      type: DataTypes.TEXT,
      allowNull: true,
      comment: "Reason for rejection if rejected"
    },
    reviewedBy: {
      type: DataTypes.INTEGER,
      allowNull: true,
      comment: "Admin user ID who reviewed"
    },
    reviewedAt: {
      type: DataTypes.DATE,
      allowNull: true
    }
  },
  {
    tableName: "artist_verifications",
    timestamps: true
  }
);

export default ArtistVerification;
