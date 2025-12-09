// // src/routes/auth.routes.js
// import express from "express";
// import bcrypt from "bcrypt";
// import jwt from "jsonwebtoken";
// import db from "../config/db.js";

// const router = express.Router();

// router.post("/register", async (req, res) => {
//   const { username, email, password } = req.body;

//   if (!username || !email || !password)
//     return res.status(400).json({ message: "Missing fields" });

//   try {
//     // check email exists
//     const [exists] = await db.query(
//       "SELECT id FROM users WHERE email = ?",
//       [email]
//     );

//     if (exists.length > 0)
//       return res.status(400).json({ message: "Email already registered" });

//     const hash = await bcrypt.hash(password, 10);

//     // INSERT INTO users
//     await db.query(
//       `INSERT INTO users (username, email, password, createdAt, updatedAt)
//        VALUES (?, ?, ?, NOW(), NOW())`,
//       [username, email, hash]
//     );

//     return res.json({ message: "User registered successfully" });
//   } catch (err) {
//     console.error("Register error:", err);
//     return res.status(500).json({ error: err.message });
//   }
// });

// router.post("/login", async (req, res) => {
//   const { email, password } = req.body;

//   if (!email || !password)
//     return res.status(400).json({ message: "Missing email or password" });

//   try {
//     const [rows] = await db.query(
//       "SELECT * FROM users WHERE email = ?",
//       [email]
//     );

//     if (rows.length === 0)
//       return res.status(400).json({ message: "User not found" });

//     const user = rows[0];

//     const match = await bcrypt.compare(password, user.password);
//     if (!match)
//       return res.status(400).json({ message: "Wrong password" });

//     const token = jwt.sign(
//       { id: user.id, email: user.email },
//       process.env.JWT_SECRET,
//       { expiresIn: "7d" }
//     );

//     return res.json({ token });
//   } catch (err) {
//     console.error("Login error:", err);
//     return res.status(500).json({ error: err.message });
//   }
// });

// export default router;

import express from "express";
import { register, login, googleSignIn, getMe, updateProfile, requestPasswordChange, changePassword } from "../controllers/auth.controller.js";
import authMiddleware from "../middleware/auth.middleware.js";

const router = express.Router();

// Public routes
router.post("/register", register);
router.post("/login", login);
router.post("/google", googleSignIn);

// Protected routes
router.put("/profile", authMiddleware, updateProfile);

router.get("/me", authMiddleware, getMe);
router.post("/password/request-change", authMiddleware, requestPasswordChange);
router.post("/password/change", authMiddleware, changePassword);

export default router;

