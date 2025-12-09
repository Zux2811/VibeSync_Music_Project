import bcrypt from "bcryptjs";
import User from "../models/user.model.js";
import sequelize from "../config/db.js";

async function createAdmin() {
  try {
    await sequelize.authenticate();
    console.log("DB connected!");

    const username = "admin";
    const email = "admin@gmail.com";
    const password = "123456";

    const hashed = await bcrypt.hash(password, 10);

    // Find user by email
    const user = await User.findOne({ where: { email } });

    if (user) {
      // If user exists, update their password and role to admin
      console.log("⚠️ Admin user exists. Updating password and role...");
      user.password = hashed;
      user.role = "admin";
      await user.save();
      console.log("✅ Admin user updated successfully!");
    } else {
      // If user does not exist, create a new admin user
      console.log("Creating new admin user...");
      await User.create({
        username,
        email,
        password: hashed,
        role: "admin",
      });
      console.log("✅ Admin user created successfully!");
    }

    process.exit(0);

  } catch (error) {
    console.error("❌ Error creating admin:", error);
    process.exit(1);
  }
}

createAdmin();
