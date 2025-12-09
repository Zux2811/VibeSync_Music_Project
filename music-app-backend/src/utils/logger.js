// src/utils/logger.js
// Simple logger utility to standardize output and control verbosity.
// In production, it avoids printing sensitive data or full stack traces.

const isProduction = process.env.NODE_ENV === 'production';

const logger = {
  /**
   * For general application-level information (e.g., startup messages).
   * @param {string} message Log message
   * @param {object} [context] Optional context
   */
  info: (message, context) => {
    console.log(`[INFO] ${message}`, context || '');
  },

  /**
   * For warnings that don't represent an error but should be noted.
   * @param {string} message Log message
   * @param {object} [context] Optional context
   */
  warn: (message, context) => {
    console.warn(`[WARN] ${message}`, context || '');
  },

  /**
   * For application errors. Logs full error in dev, concise message in prod.
   * @param {string} message High-level error message
   * @param {Error|object} error The error object
   */
  error: (message, error) => {
    if (isProduction) {
      console.error(`[ERROR] ${message}`);
    } else {
      console.error(`[ERROR] ${message}`, error);
    }
  },

  /**
   * For detailed, verbose logs useful only during development.
   * Does not log anything in production.
   * @param {string} message Log message
   * @param {object} [context] Optional context
   */
  debug: (message, context) => {
    if (!isProduction) {
      console.log(`[DEBUG] ${message}`, context || '');
    }
  },
};

export default logger;

