import jwt from "jsonwebtoken";
import { JWT_SECRET } from "../config/security.js";

export function createJwt(user) {
  if (!user) throw new Error("createJwt requires a user object");
  const payload = {
    id: user.id,
    email: user.email,
    role: user.role,
    tierCode: user.tierCode || 'free',
  };

  // Ensure UserProfile data, especially avatarUrl, is included if it exists
  if (user.UserProfile) {
    payload.profile = {
      avatarUrl: user.UserProfile.avatarUrl,
    };
  } else if (user.profile) { // Fallback for manually attached profile
    payload.profile = {
      avatarUrl: user.profile.avatarUrl,
    };
  }

  // Tier denormalized on user
  if (user.tierCode) {
    payload.tierCode = user.tierCode;
  }

  return jwt.sign(payload, JWT_SECRET, { expiresIn: "7d" });
}

