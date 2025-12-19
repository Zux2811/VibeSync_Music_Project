import sequelize from "../config/db.js";
import { QueryTypes } from "sequelize";
import dotenv from "dotenv";
dotenv.config();

const addColumnIfNotExists = async (table, column, ddl) => {
  try {
    const [rows] = await sequelize.query(
      `SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
      { replacements: [table, column], type: QueryTypes.SELECT }
    );
    const cnt = rows?.cnt ?? 0;
    if (!Number(cnt)) {
      console.log(`Adding column ${table}.${column}...`);
      await sequelize.query(`ALTER TABLE ${table} ADD COLUMN ${ddl}`);
      console.log(`✓ Added ${table}.${column}`);
    } else {
      console.log(`Column ${table}.${column} already exists`);
    }
  } catch (e) {
    console.error(`Error adding ${table}.${column}:`, e.message);
  }
};

const run = async () => {
  try {
    await sequelize.authenticate();
    console.log("Connected to database");

    // Add missing columns to songs table
    await addColumnIfNotExists("songs", "artistId", "artistId INT NULL");
    await addColumnIfNotExists("songs", "albumId", "albumId INT NULL");
    await addColumnIfNotExists("songs", "playCount", "playCount BIGINT DEFAULT 0");
    await addColumnIfNotExists("songs", "isPublished", "isPublished BOOLEAN DEFAULT TRUE");
    await addColumnIfNotExists("songs", "isExplicit", "isExplicit BOOLEAN DEFAULT FALSE");
    await addColumnIfNotExists("songs", "genre", "genre VARCHAR(100) NULL");
    await addColumnIfNotExists("songs", "lyrics", "lyrics TEXT NULL");
    await addColumnIfNotExists("songs", "releaseDate", "releaseDate DATE NULL");

    console.log("\n✓ Migration completed!");
    process.exit(0);
  } catch (e) {
    console.error("Migration failed:", e);
    process.exit(1);
  }
};

run();
