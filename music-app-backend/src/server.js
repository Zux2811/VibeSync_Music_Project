// // src/server.js
// import express from "express";
// import dotenv from "dotenv";
// import cors from "cors";
// import sequelize from "./config/db.js";
// import "./models/index.js"; // load models & associations
// import authRoutes from "./routes/auth.routes.js";
// import songRoutes from "./routes/song.routes.js";

// dotenv.config();

// const app = express();
// app.use(cors());
// app.use(express.json());
// app.use(express.urlencoded({ extended: true }));

// app.get("/", (req, res) => res.json({ status: "ok", time: new Date() }));

// app.use("/api/auth", authRoutes);
// app.use("/api/songs", songRoutes);

// // connect + sync
// (async () => {
//   try {
//     await sequelize.authenticate();
//     console.log("Sequelize connected.");
//     await sequelize.sync({ alter: true }); // alter:true để cập nhật schema nhẹ — dùng { force: false } hoặc remove trên prod
//     console.log("DB synced.");
//   } catch (err) {
//     console.error("DB connection/sync error:", err);
//   }
// })();

// const PORT = process.env.PORT || 5000;
// app.listen(PORT, () => console.log(`Server listening on ${PORT}`));


import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import sequelize from "./config/db.js";
import "./models/index.js";
import logger from "./utils/logger.js";
import { QueryTypes } from "sequelize";
// Import JWT_SECRET from config/security.js which validates it on load
import { JWT_SECRET } from "./config/security.js";

import authRoutes from "./routes/auth.routes.js";
import songRoutes from "./routes/song.routes.js";
import adminRoutes from "./routes/admin.routes.js";
import reportRoutes from "./routes/report.routes.js";
import commentRoutes from "./routes/comment.routes.js";
import folderRoutes from "./routes/folder.routes.js";
import playlistRoutes from "./routes/playlist.routes.js";
import favoriteRoutes from "./routes/favorite.routes.js";
import uploadRoutes from "./routes/upload.routes.js";
import subscriptionRoutes from "./routes/subscription.routes.js";
import artistRoutes from "./routes/artist.routes.js";
import artistVerificationRoutes from "./routes/artistVerification.routes.js";

dotenv.config();

// JWT_SECRET is validated and imported from config/security.js
logger.info("✓ JWT_SECRET validated and loaded from config/security.js");

logger.info("Starting application...");
logger.debug("Initial environment:", {
  NODE_ENV: process.env.NODE_ENV,
  PORT: process.env.PORT || 5000,
  SKIP_DB: process.env.SKIP_DB,
  SEQUELIZE_ALTER: process.env.SEQUELIZE_ALTER
});

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

logger.info("Middleware configured");

app.get("/", (req, res) => {
  logger.debug("Root health check endpoint called");
  return res.json({ status: "ok", time: new Date() });
});

app.use("/api/auth", authRoutes);
app.use("/api/songs", songRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/comments", commentRoutes);
app.use("/api/folders", folderRoutes);
app.use("/api/playlists", playlistRoutes);
app.use("/api/favorites", favoriteRoutes);
app.use("/api/upload", uploadRoutes);
app.use("/api/subscription", subscriptionRoutes);
app.use("/api/artists", artistRoutes);
app.use("/api/artist-verification", artistVerificationRoutes);

// Legacy/unmounted route modules (kept for reference or backward compatibility):
// - share.routes.js: simple shareable link generation (no auth). Not mounted.
// - user.routes.js: admin-like operations; consider moving under /api/admin. Not mounted.
// - userProfile.routes.js: superseded by /api/auth/profile endpoints. Not mounted.
// - folderPlaylist.routes.js: superseded by playlist update (folderId). Not mounted.
// - playlistSong.routes.js: superseded by playlist.routes song operations. Not mounted.

// connect + sync (non-blocking for port binding/health)
(async () => {
  try {
    logger.info("Starting database initialization...");
    if (process.env.SKIP_DB === "true") {
      logger.warn("SKIP_DB=true -> Skipping database connection/sync on startup");
    } else {
      logger.info("Authenticating with database...");
      await sequelize.authenticate();
      logger.info("✓ Sequelize connected successfully");

      // Sync database models with environment-aware options
      // WARNING: { alter: true } is unsafe for production and should only be used in development/staging
      const shouldAlter = process.env.SEQUELIZE_ALTER_ENABLED === 'true' || process.env.NODE_ENV === 'development';
      if (shouldAlter) {
        logger.info("Syncing database models with { alter: true }...");
        await sequelize.sync({ alter: true });
        logger.info(`✓ DB synced with { alter: true }`);
      } else {
        logger.info("Syncing database models (no alter in production)...");
        await sequelize.sync();
        logger.info(`✓ DB synced (schema changes must be applied via migrations)`);
      }

      // Optional: Run startup migrations if explicitly enabled
      // For production, it's recommended to run migrations separately via: node src/scripts/runMigrations.js
      if (process.env.RUN_STARTUP_MIGRATIONS === 'true') {
        logger.warn('RUN_STARTUP_MIGRATIONS=true: Running migrations during startup (not recommended for production)');
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
                logger.warn(`Table ${table} not found, skipping.`);
              } else {
                throw e;
              }
            }
          };

          logger.info("Running safety migrations...");
          await ensureColumn('folders', 'parentId', 'ADD COLUMN parentId INT NULL DEFAULT NULL');

          // Legacy migrations
          try {
            logger.info("Checking for legacy url->audioUrl migration...");
            await sequelize.query(
              "UPDATE songs SET audioUrl = url WHERE (audioUrl IS NULL OR audioUrl = '') AND url IS NOT NULL"
            );
            logger.info("✓ Migrated legacy url -> audioUrl where needed");
          } catch (e) {
            logger.warn("Legacy url->audioUrl migration skipped:", e.message);
          }

          if (process.env.DROP_LEGACY_URL === "true") {
            try {
              logger.info("Dropping legacy 'url' column...");
              await sequelize.query("ALTER TABLE songs DROP COLUMN url");
              logger.info("✓ Dropped legacy 'url' column from songs");
            } catch (e) {
              logger.warn("Drop legacy 'url' column skipped:", e.message);
            }
          }

          try {
            logger.info("Recomputing comment likes from join table...");
            await sequelize.query(
              `UPDATE comments c
               LEFT JOIN (
                 SELECT commentId, COUNT(*) AS cnt
                 FROM comment_likes
                 GROUP BY commentId
               ) cl ON cl.commentId = c.id
               SET c.likes = COALESCE(cl.cnt, 0)`
            );
            logger.info("✓ Recomputed comments.likes from comment_likes join table");
          } catch (e) {
            logger.warn("Recompute comments.likes skipped:", e.message);
          }

          if (process.env.DROP_LEGACY_LIKED_BY === "true") {
            try {
              logger.info("Dropping legacy 'liked_by' column...");
              await sequelize.query("ALTER TABLE comments DROP COLUMN liked_by");
              logger.info("✓ Dropped legacy 'liked_by' column from comments");
            } catch (e) {
              logger.warn("Drop legacy 'liked_by' column skipped:", e.message);
            }
          }
        } catch (e) {
          logger.error('Error during startup migrations:', e.message);
        }
      } else {
        logger.info('Startup migrations disabled. Run separately: node src/scripts/runMigrations.js');
      }

      // Optional: Seed admin if explicitly enabled
      if (process.env.SEED_ADMIN_ON_STARTUP === 'true') {
        try {
          const { User } = await import('./models/index.js');
          const bcrypt = (await import('bcryptjs')).default;
          const adminEmail = (process.env.ADMIN_EMAIL || 'admin@gmail.com').trim();
          const adminPassword = process.env.ADMIN_PASSWORD || '123456';

          const [admin, created] = await User.findOrCreate({
            where: { email: adminEmail },
            defaults: {
              username: 'admin',
              email: adminEmail,
              password: await bcrypt.hash(adminPassword, 10),
              role: 'admin',
            },
          });
          if (created) {
            logger.info(`Seeded default admin account: ${adminEmail}`);
          } else if (admin.role !== 'admin') {
            admin.role = 'admin';
            await admin.save();
            logger.info(`Upgraded user ${adminEmail} to admin role`);
          }
        } catch (e) {
          logger.warn('Admin seeding skipped:', e.message);
        }
      }

      logger.info("✓ Database initialization completed successfully");
    }
  } catch (err) {
    logger.error("DB connection/sync error:", err);
  }
})();

// Health check
app.get("/health", (req, res) => {
  logger.debug("Health check called");
  return res.json({ status: "ok" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  logger.info(`✓ Server listening on port ${PORT}`);
  logger.info("✓ Application started successfully");
  logger.debug("Available routes:", {
    "/": "health check",
    "/health": "health check",
    "/api/auth": "register, login, google-signin",
    "/api/songs": "GET, POST",
    "...": "And more..."
  });
});
