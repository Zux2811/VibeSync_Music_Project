import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";
import User from "./user.model.js";

const UserProfile = sequelize.define("UserProfile", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'user_id'
  },
  avatarUrl: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'avatar_url'
  },
  bio: { type: DataTypes.TEXT, allowNull: true },
}, {
  tableName: "user_profiles",
  timestamps: false,
});



export default UserProfile;
