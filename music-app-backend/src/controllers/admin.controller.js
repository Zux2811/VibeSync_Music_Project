import User from "../models/user.model.js";
import bcrypt from "bcryptjs";
import { createJwt } from "../utils/jwt.js";
import logger from "../utils/logger.js";

// =======================
// 1. LOGIN ADMIN
// =======================
export const loginAdmin = async (req, res) => {
  try {
    const rawEmail = (req.body.email || '').toString().trim();
    const email = rawEmail;
    const password = (req.body.password || '').toString();
    logger.info("Admin login attempt", { email: rawEmail });

    const admin = await User.findOne({ where: { email } });
    if (!admin) {
      return res.status(400).json({ message: "Sai tài khoản hoặc mật khẩu" });
    }

    // Role must be admin
    if (admin.role?.trim().toLowerCase() !== "admin") {
      return res.status(403).json({ message: "Tài khoản này không có quyền admin" });
    }

    // Support both bcrypt-hashed and legacy plain-text passwords (if explicitly enabled)
    let isMatch = false;
    const stored = admin.password || '';
    const allowLegacy = process.env.ALLOW_LEGACY_ADMIN_PLAIN_PASSWORDS === 'true';
    const isProduction = process.env.NODE_ENV === 'production';

    if (stored.startsWith('$2')) {
      // Bcrypt-hashed password (recommended)
      isMatch = await bcrypt.compare(password, stored);
    } else if (allowLegacy && !isProduction && stored.length > 0) {
      // Legacy: plain text password (only if explicitly enabled AND not in production)
      // WARNING: This is a security risk and should only be used for backward compatibility during migration
      logger.warn('[SECURITY] Legacy plain-text admin password mode is active. Migrate to bcrypt immediately.');
      isMatch = password === stored;
      if (isMatch) {
        try {
          admin.password = await bcrypt.hash(password, 10);
          await admin.save();
          logger.info('Upgraded admin password to bcrypt hash');
        } catch (e) {
          logger.warn('Failed to upgrade legacy admin password:', e.message);
        }
      }
    } else if (allowLegacy && isProduction) {
      // Reject legacy mode in production even if flag is set
      logger.error('[SECURITY] Legacy plain-text admin password mode is disabled in production. Admin password must be bcrypt-hashed.');
      isMatch = false;
    }

    if (!isMatch) {
      return res.status(400).json({ message: "Sai tài khoản hoặc mật khẩu" });
    }

    // Issue JWT with id, email, role
    const token = createJwt(admin);

    res.json({
      message: "Đăng nhập admin thành công",
      token,
      admin: {
        id: admin.id,
        username: admin.username,
        email: admin.email,
        role: admin.role
      }
    });
  } catch (err) {
    logger.error("Admin login error", err);
    res.status(500).json({ message: "Lỗi server", error: err.message });
  }
};

// =======================
// 2. LẤY TẤT CẢ USER
// =======================
export const getAllUsers = async (req, res) => {
  try {
    logger.info("Fetching all users for admin");
    const users = await User.findAll({
      where: { role: "user" },
      attributes: { exclude: ["password"] },
    });
    logger.debug("Found users", { count: users.length });
    res.json(users);
  } catch (err) {
    logger.error("Error fetching all users", err);
    res.status(500).json({ message: "Lỗi server", error: err.message });
  }
};

// =======================
// 3. XÓA USER
// =======================
export const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    logger.info("Admin deleting user", { id });

    const result = await User.destroy({ where: { id } });

    if (result === 0) {
      logger.warn("Delete user failed: User not found", { id });
      return res.status(404).json({ message: "User not found" });
    }

    logger.info("User deleted successfully", { id });
    res.json({ message: "Xóa người dùng thành công" });
  } catch (err) {
    logger.error("Error deleting user", err);
    res.status(500).json({ message: "Lỗi server", error: err.message });
  }
};


