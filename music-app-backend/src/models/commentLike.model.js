import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const CommentLike = sequelize.define(
  "CommentLike",
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    userId: { type: DataTypes.INTEGER, allowNull: false },
    commentId: { type: DataTypes.INTEGER, allowNull: false },
  },
  {
    tableName: "comment_likes",
    timestamps: true,
    indexes: [
      {
        unique: true,
        fields: ["userId", "commentId"],
      },
    ],
  }
);

export default CommentLike;

