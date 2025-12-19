import sequelize from "../config/db.js";
import "../models/index.js"; // Load all models and associations
import dotenv from "dotenv";
dotenv.config();

const syncDatabase = async () => {
  try {
    console.log("🔌 Connecting to database...");
    await sequelize.authenticate();
    console.log("✅ Database connected successfully!");
    
    console.log("\n📊 Database info:");
    console.log(`   Host: ${process.env.DB_HOST}`);
    console.log(`   Port: ${process.env.DB_PORT || 3306}`);
    console.log(`   Database: ${process.env.DB_NAME}`);
    console.log(`   User: ${process.env.DB_USER}`);
    
    console.log("\n🔄 Syncing all models with { alter: true }...");
    console.log("   This will create new tables and add missing columns.\n");
    
    await sequelize.sync({ alter: true });
    
    console.log("✅ All tables synced successfully!\n");
    
    // List all tables
    const [tables] = await sequelize.query("SHOW TABLES");
    console.log("📋 Tables in database:");
    tables.forEach((table, index) => {
      const tableName = Object.values(table)[0];
      console.log(`   ${index + 1}. ${tableName}`);
    });
    
    console.log("\n🎉 Database sync completed!");
    process.exit(0);
  } catch (error) {
    console.error("\n❌ Error syncing database:", error.message);
    if (error.original) {
      console.error("   Original error:", error.original.message);
    }
    process.exit(1);
  }
};

syncDatabase();
