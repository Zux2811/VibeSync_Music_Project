import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Tier = sequelize.define(
  "Tier",
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    code: { type: DataTypes.STRING(32), unique: true, allowNull: false },
    name: { type: DataTypes.STRING(100), allowNull: false },
    features: { type: DataTypes.JSON, allowNull: false },
    isActive: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  },
  {
    tableName: "tiers",
    timestamps: true,
  }
);

export default Tier;

