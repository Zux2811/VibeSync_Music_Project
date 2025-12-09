// // src/config/db.js
// import { Sequelize } from "sequelize";
// import dotenv from "dotenv";
// dotenv.config();

// const sequelize = new Sequelize(
//   process.env.DB_NAME,
//   process.env.DB_USER,
//   process.env.DB_PASS,
//   {
//     host: process.env.DB_HOST,
//     port: Number(process.env.DB_PORT) || 3306,
//     dialect: "mysql",
//     logging: false,
//     dialectOptions: {
//       // keep this if Railway requires SSL; nếu không, có thể loại bỏ
//       ssl: process.env.DB_SSL === "true" ? { rejectUnauthorized: false } : undefined,
//     },
//   }
// );

// export default sequelize;

import { Sequelize } from "sequelize";
import dotenv from "dotenv";
dotenv.config();

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASS,
  {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT) || 3306,
    dialect: "mysql",
    logging: false,
    dialectOptions: {
      ssl: process.env.DB_SSL === "true" ? { rejectUnauthorized: false } : undefined,
    },
  }
);

export default sequelize;
