// src/config/security.js
// Central place to access security-related constants. This module validates
// JWT_SECRET on first import; all other modules should import from here
// instead of reading process.env directly.

import dotenv from 'dotenv';
import logger from '../utils/logger.js';

// Ensure env is loaded even if this file is imported independently
dotenv.config();

// Validate JWT_SECRET once on module load
const jwtSecret = (process.env.JWT_SECRET || "").trim();
if (!jwtSecret || jwtSecret.length < 16) {
  const errorMsg = "[SECURITY] Invalid or missing JWT_SECRET. Set a strong secret (>=16 chars) in environment variables.";
  if (logger && logger.error) {
    logger.error(errorMsg);
  } else {
    console.error(errorMsg);
  }
  process.exit(1);
}

export const JWT_SECRET = jwtSecret;

