import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const UserSubscription = sequelize.define(
  "UserSubscription",
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: { model: 'users', key: 'id' },
      onDelete: 'CASCADE',
    },
    tierId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: { model: 'tiers', key: 'id' },
      onDelete: 'CASCADE',
    },
    status: {
      type: DataTypes.ENUM("unactive", "active", "expired", "pending"),
      allowNull: false,
      defaultValue: "unactive",
    },
    provider: { type: DataTypes.STRING, allowNull: true },
    providerRef: { type: DataTypes.STRING, allowNull: true },
    startAt: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
    endAt: { type: DataTypes.DATE, allowNull: true },
  },
  {
    tableName: "user_subscriptions",
    timestamps: true,
    indexes: [
      // Speed up lookups by user & status (active subscriptions)
      { fields: ['userId', 'status'] },
      // Ensure one transaction reference per user/provider
      { unique: true, fields: ['userId', 'provider', 'providerRef'] },
      // Aid sorting/filtering by start time per user
      { fields: ['userId', 'startAt'] },
    ],
  }
);

export default UserSubscription;