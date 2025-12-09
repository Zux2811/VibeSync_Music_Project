// src/utils/tier.js
import User from "../models/user.model.js";
import Tier from "../models/tier.model.js";

/**
 * Returns the user's effective tier and its features.
 * Falls back to 'free' if user or tier not found.
 * { code: 'free'|'pro', features: object }
 */
export async function getUserTier(userId) {
  const DEFAULT_FREE = { code: 'free', features: { maxPlaylists: 5, offline: false } };
  try {
    const user = await User.findByPk(userId, { attributes: ['id', 'tierCode'] });
    const code = (user?.tierCode || 'free').toLowerCase();
    const tier = await Tier.findOne({ where: { code, isActive: true } });
    if (!tier) return DEFAULT_FREE;
    return { code: tier.code, features: tier.features || DEFAULT_FREE.features };
  } catch (_) {
    return DEFAULT_FREE;
  }
}

/**
 * Checks if a user is Pro by reading the database (not the JWT only).
 */
export async function isUserPro(userId) {
  const t = await getUserTier(userId);
  return t.code === 'pro';
}

