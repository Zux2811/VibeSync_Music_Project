import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

// Define only the model here. All associations are declared centrally in models/index.js
const Comment = sequelize.define(
  "Comment",
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    user_id: { type: DataTypes.INTEGER, allowNull: false },
    song_id: { type: DataTypes.INTEGER, allowNull: true },
    playlist_id: { type: DataTypes.INTEGER, allowNull: true },
    parent_id: { type: DataTypes.INTEGER, allowNull: true },
    content: { type: DataTypes.TEXT, allowNull: false },
    likes: { type: DataTypes.INTEGER, defaultValue: 0 },
  },
  {
    tableName: "comments",
    timestamps: true,
    createdAt: "created_at",
    updatedAt: false,
  }
);

export default Comment;
