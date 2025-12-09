import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const PasswordReset = sequelize.define(
  "PasswordReset",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      field: 'user_id',
      unique: true, // Only one active reset per user
    },
    code: {
      type: DataTypes.STRING(10),
      allowNull: false,
    },
    expiresAt: {
      type: DataTypes.DATE,
      allowNull: false,
      field: 'expires_at',
    },
  },
  {
    tableName: "password_resets",
    timestamps: false, // No createdAt/updatedAt needed for temporary codes
  }
);

export default PasswordReset;

