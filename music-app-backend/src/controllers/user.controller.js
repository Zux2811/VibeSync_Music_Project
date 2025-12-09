import User from "../models/user.model.js";
import bcrypt from "bcryptjs";

export const getAllUsers = async (req, res) => {
  const users = await User.findAll();
  res.json(users);
};

export const updateUser = async (req, res) => {
  const { id } = req.params;
  const { username, email, password } = req.body;

  const user = await User.findByPk(id);
  if (!user) return res.status(404).json({ message: "User not found" });

  if (password) user.password = await bcrypt.hash(password, 10);
  if (username) user.username = username;
  if (email) user.email = email;

  await user.save();
  res.json({ message: "User updated successfully", user });
};

export const deleteUser = async (req, res) => {
  const { id } = req.params;
  const user = await User.findByPk(id);
  if (!user) return res.status(404).json({ message: "User not found" });

  await user.destroy();
  res.json({ message: "User deleted successfully" });
};
