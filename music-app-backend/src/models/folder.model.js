import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Folder = sequelize.define(
  "Folder",
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    name: { type: DataTypes.STRING, allowNull: false },
    UserId: { type: DataTypes.INTEGER, allowNull: false }, // FK to User
    parentId: { type: DataTypes.INTEGER, allowNull: true, defaultValue: null }, // FK to self
  }
  // Tạm thời bỏ indexes để sync cột trước. Sẽ thêm lại sau.
);

export default Folder;
