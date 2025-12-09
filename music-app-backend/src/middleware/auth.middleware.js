import jwt from "jsonwebtoken";
import logger from "../utils/logger.js";
import { JWT_SECRET } from "../config/security.js";

export default function authMiddleware(req, res, next) {
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
    logger.debug("Token verified for user", { id: payload.id, email: payload.email });
    req.user = payload; // { id, email, role }
    next();
  } catch (err) {
    logger.warn(`Token verification failed: ${err.message}`);
    return res.status(401).json({ message: "Invalid token", error: err.message });
  }
}
