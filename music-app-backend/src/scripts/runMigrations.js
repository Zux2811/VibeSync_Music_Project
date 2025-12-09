/**
 * Database migration script
 * 
 * This script should be run before starting the application in production.
 * It handles:
 * - Safety migrations for missing columns/constraints
 * - Legacy data migrations (e.g., url -> audioUrl)
 * - Data recomputations (e.g., comment likes from join table)
 * 
 * Usage: node src/scripts/runMigrations.js
 */

import dotenv from 'dotenv';
import sequelize from '../config/db.js';
import logger from '../utils/logger.js';
import { QueryTypes } from 'sequelize';

dotenv.config();

const runMigrations = async () => {
  try {
    logger.info('Starting database migrations...');
    
    // Ensure database connection
    await sequelize.authenticate();
    logger.info('✓ Database connected');

    // ---- Safety migrations for missing columns/constraints (idempotent) ----
    logger.info('Running safety migrations...');
    try {
      const ensureColumn = async (table, column, ddl) => {
        try {
          const [rows] = await sequelize.query(
            `SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :t AND COLUMN_NAME = :c`,
            { replacements: { t: table, c: column }, type: QueryTypes.SELECT }
          );
          const cnt = rows?.cnt ?? 0;
          if (!Number(cnt)) {
            logger.info(`Adding missing column ${table}.${column} ...`);
            await sequelize.query(`ALTER TABLE ${table} ${ddl}`);
            logger.info(`✓ Added column ${table}.${column}`);
          }
        } catch (e) {
          if (e.message.includes("doesn't exist")) {
            logger.warn(`Table ${table} not found, skipping column check.`);
          } else {
            throw e;
          }
        }
      };

      // Ensure folders.parentId for nesting exists
      await ensureColumn('folders', 'parentId', 'ADD COLUMN parentId INT NULL DEFAULT NULL');

    } catch (e) {
      logger.error('Error during safety migrations:', e.message);
      throw e;
    }

    // Legacy migration: populate audioUrl from legacy url column if present
    try {
      logger.info('Checking for legacy url->audioUrl migration...');
      await sequelize.query(
        'UPDATE songs SET audioUrl = url WHERE (audioUrl IS NULL OR audioUrl = "") AND url IS NOT NULL'
      );
      logger.info('✓ Migrated legacy url -> audioUrl where needed');
    } catch (e) {
      logger.warn('Legacy url->audioUrl migration skipped:', e.message);
    }

    // Optional: drop legacy 'url' column if explicitly enabled
    if (process.env.DROP_LEGACY_URL === 'true') {
      try {
        logger.info('Dropping legacy "url" column...');
        await sequelize.query('ALTER TABLE songs DROP COLUMN url');
        logger.info('✓ Dropped legacy "url" column from songs');
      } catch (e) {
        logger.warn('Drop legacy "url" column skipped:', e.message);
      }
    }

    // Migrate comment likes from legacy JSON column to join table (if legacy existed)
    try {
      logger.info('Recomputing comment likes from join table...');
      await sequelize.query(
        `UPDATE comments c
         LEFT JOIN (
           SELECT commentId, COUNT(*) AS cnt
           FROM comment_likes
           GROUP BY commentId
         ) cl ON cl.commentId = c.id
         SET c.likes = COALESCE(cl.cnt, 0)`
      );
      logger.info('✓ Recomputed comments.likes from comment_likes join table');
    } catch (e) {
      logger.warn('Recompute comments.likes skipped:', e.message);
    }

    // Optionally drop legacy liked_by column if present and enabled
    if (process.env.DROP_LEGACY_LIKED_BY === 'true') {
      try {
        logger.info('Dropping legacy "liked_by" column...');
        await sequelize.query('ALTER TABLE comments DROP COLUMN liked_by');
        logger.info('✓ Dropped legacy "liked_by" column from comments');
      } catch (e) {
        logger.warn('Drop legacy "liked_by" column skipped:', e.message);
      }
    }

    logger.info('✓ All migrations completed successfully');
    process.exit(0);
  } catch (err) {
    logger.error('Migration failed:', err);
    process.exit(1);
  }
};

runMigrations();

