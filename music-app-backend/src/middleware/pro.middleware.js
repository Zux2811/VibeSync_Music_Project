// src/middleware/pro.middleware.js
import { isUserPro } from "../utils/tier.js";

export default async function requirePro(req, res, next) {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: "Unauthorized" });
    const ok = await isUserPro(userId);
    if (!ok) return res.status(403).json({ message: "Pro feature. Please upgrade." });
    next();
  } catch (e) {
    return res.status(500).json({ message: "Server error", error: e.message });
  }
}

