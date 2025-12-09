import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Favorite = sequelize.define(
  "Favorite",
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    userId: { type: DataTypes.INTEGER, allowNull: false },
    songId: { type: DataTypes.INTEGER, allowNull: false },
  },
  {
    tableName: "favorites",
    timestamps: true,
    indexes: [
      {
        unique: true,
        fields: ["userId", "songId"],
      },
    ],
  }
);

export default Favorite;

