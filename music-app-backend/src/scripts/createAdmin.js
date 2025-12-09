// src/scripts/createAdmin.js
// Chạy file này để tạo hoặc cập nhật tài khoản admin
// Usage: node src/scripts/createAdmin.js <email> <password>

import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import User from '../models/user.model.js';
import sequelize from '../config/db.js';

dotenv.config();

const createAdmin = async () => {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.error('Usage: node src/scripts/createAdmin.js <email> <password>');
    process.exit(1);
  }

  const [email, password] = args;

  try {
    await sequelize.authenticate();
    console.log('Database connected...');

    const hashedPassword = await bcrypt.hash(password, 10);

    const [user, created] = await User.findOrCreate({
      where: { email },
      defaults: {
        username: 'Admin',
        email,
        password: hashedPassword,
        role: 'admin',
      },
    });

    if (created) {
      console.log(`Admin user created successfully: ${email}`);
    } else {
      // If user already exists, update their password and role
      user.password = hashedPassword;
      user.role = 'admin';
      await user.save();
      console.log(`Admin user updated successfully: ${email}`);
    }
  } catch (error) {
    console.error('Error creating/updating admin user:', error);
  } finally {
    await sequelize.close();
    console.log('Database connection closed.');
  }
};

createAdmin();

