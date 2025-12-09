/**
 * Admin seeding script
 * 
 * This script creates a default admin account if one doesn't exist.
 * 
 * Usage: node src/scripts/seedAdmin.js
 * 
 * Environment variables:
 * - ADMIN_EMAIL: Email for admin account (default: admin@gmail.com)
 * - ADMIN_PASSWORD: Password for admin account (default: 123456)
 */

import dotenv from 'dotenv';
import sequelize from '../config/db.js';
import logger from '../utils/logger.js';
import bcrypt from 'bcryptjs';

dotenv.config();

const seedAdmin = async () => {
  try {
    logger.info('Starting admin seeding...');
    
    // Ensure database connection
    await sequelize.authenticate();
    logger.info('✓ Database connected');

    const { User } = await import('../models/index.js');
    
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
      logger.info(`✓ Seeded default admin account: ${adminEmail}`);
    } else if (admin.role !== 'admin') {
      admin.role = 'admin';
      await admin.save();
      logger.info(`✓ Upgraded user ${adminEmail} to admin role`);
    } else {
      logger.info(`✓ Admin account already exists: ${adminEmail}`);
    }

    logger.info('✓ Admin seeding completed successfully');
    process.exit(0);
  } catch (err) {
    logger.error('Admin seeding failed:', err);
    process.exit(1);
  }
};

seedAdmin();

