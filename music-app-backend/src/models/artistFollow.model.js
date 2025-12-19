import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const ArtistFollow = sequelize.define(
  "ArtistFollow",
  {
    followerId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      comment: "User who is following"
    },
    artistId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      comment: "Artist (user with role='artist') being followed"
    }
  },
  {
    tableName: "artist_follows",
    timestamps: true,
    indexes: [
      {
        unique: true,
        fields: ['followerId', 'artistId']
      }
    ]
  }
);

export default ArtistFollow;
