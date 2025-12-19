import jwt from "jsonwebtoken";
import logger from "../utils/logger.js";
import { JWT_SECRET } from "../config/security.js";

export function authMiddleware(req, res, next) {
  logger.debug(`Checking authorization for: ${req.method} ${req.path}`);
  const auth = req.headers.authorization || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : null;

  if (!token) {
    logger.warn("Authorization failed: No token provided");
    return res.status(401).json({ message: "No token" });
  }

  try {
    logger.debug("Verifying JWT token");
    const payload = jwt.verify(token, JWT_SECRET);
    logger.debug("Token verified for user", { id: payload.id, email: payload.email, role: payload.role });
    req.user = payload; // { id, email, role }
    next();
  } catch (err) {
    logger.warn(`Token verification failed: ${err.message}`);
    return res.status(401).json({ message: "Invalid token", error: err.message });
  }
}

/**
 * Middleware to require specific roles
 * @param {string[]} roles - Array of allowed roles
 */
export function requireRole(roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Authentication required" });
    }

    if (!roles.includes(req.user.role)) {
      logger.warn(`Access denied for user ${req.user.id} with role ${req.user.role}. Required roles: ${roles.join(', ')}`);
      return res.status(403).json({ message: "Access denied. Insufficient permissions." });
    }

    next();
  };
}

// Default export for backward compatibility
export default authMiddleware;
