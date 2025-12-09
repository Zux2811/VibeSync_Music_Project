import bcrypt from "bcryptjs";
import User from "../models/user.model.js";
import UserProfile from "../models/userProfile.model.js";
import PasswordReset from "../models/passwordReset.model.js";
import { OAuth2Client } from "google-auth-library";
import { createJwt } from "../utils/jwt.js";
import logger from "../utils/logger.js";
import { getMailer } from "../config/mailer.js";


const DEFAULT_AVATAR_URL = "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png";

export const register = async (req, res) => {
  try {
    logger.debug("Received registration request", { username: req.body.username, email: req.body.email });
    const { username, email, password, avatarUrl } = req.body;

    if (!username || !email || !password) {
      logger.warn("Registration failed: Missing required fields");
      return res.status(400).json({ message: "Missing required fields: username, email, password" });
    }

    logger.debug("Checking for existing email", { email });
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      logger.warn("Registration failed: Email already exists", { email });
      return res.status(400).json({ message: "Email already exists" });
    }

    logger.debug("Hashing password", { email });
    const hashedPassword = await bcrypt.hash(password, 10);

    logger.debug("Creating new user", { username, email });
    const newUser = await User.create({
      username,
      email,
      password: hashedPassword,
      role: "user",
    });

    // Create a profile, using the provided avatar URL or the default one
    const createdProfile = await UserProfile.create({
      userId: newUser.id,
      avatarUrl: avatarUrl || DEFAULT_AVATAR_URL,
    });

    // Attach the profile to the user object before creating the JWT
    newUser.profile = createdProfile.toJSON();

    logger.info("User registered successfully", { id: newUser.id, email: newUser.email, tierCode: newUser.tierCode });
    const token = createJwt(newUser);

    res.status(201).json({
      success: true,
      message: "User registered successfully",
      token: token,
      user: {
        id: newUser.id,
        username: newUser.username,
        email: newUser.email,
        role: newUser.role,
        tierCode: newUser.tierCode || 'free',
      },
    });
  } catch (error) {
    logger.error("Registration error", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const login = async (req, res) => {
  try {
    logger.info("Login attempt", { email: req.body.email });
    const { email, password } = req.body;

    if (!email || !password) {
      logger.warn("Login failed: Missing email or password");
      return res.status(400).json({ message: "Email and password are required" });
    }

    logger.debug("Finding user", { email });
    const user = await User.findOne({
      where: { email },
      include: [{ model: UserProfile, as: 'profile' }]
    });
    if (!user) {
      logger.warn("Login failed: User not found", { email });
      return res.status(404).json({ message: "User not found" });
    }

    // For social-login accounts (no local password), block local login
    if (!user.password) {
      logger.warn("Login failed: Local login attempted for social account", { email });
      return res.status(400).json({ message: "This account uses social login. Please sign in with Google." });
    }

    logger.debug("Comparing password", { email });
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      logger.warn("Login failed: Invalid password", { email });
      return res.status(401).json({ message: "Invalid password" });
    }

    logger.debug("Creating JWT", { id: user.id, email: user.email, role: user.role, tierCode: user.tierCode });
    const token = createJwt(user);

    logger.info("Login successful", { email, tierCode: user.tierCode });
    res.json({
      message: "Login successful",
      token,
      role: user.role,
      tierCode: user.tierCode || 'free',
    });
  } catch (error) {
    logger.error("Login error", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getMe = async (req, res) => {
  try {
    logger.debug("Fetching profile for user", { userId: req.user.id });
    const user = await User.findByPk(req.user.id, {
      attributes: ["id", "username", "email", "role", "tierCode"],
      include: {
        model: UserProfile,
        as: 'profile',
        attributes: ["bio", "avatarUrl"],
      },
    });

    if (!user) {
      logger.warn("getMe failed: User not found in database", { userId: req.user.id });
      return res.status(404).json({ message: "User not found" });
    }

    // Flatten the response object
    const userProfile = user.profile ? user.profile.get({ plain: true }) : {};
    const response = {
      id: user.id,
      name: user.username,
      email: user.email,
      role: user.role,
      tierCode: user.tierCode || 'free',
      bio: userProfile.bio,
      avatarUrl: userProfile.avatarUrl,
    };

    logger.info("User profile fetched successfully", { userId: user.id, tierCode: user.tierCode });
    res.json(response);
  } catch (error) {
    logger.error("Error in getMe controller", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { bio } = req.body;

    // Find the user's profile
    const userProfile = await UserProfile.findOne({ where: { userId } });

    if (!userProfile) {
      // If no profile exists, create one
      await UserProfile.create({ userId, bio });
      logger.info(`Created profile and updated bio for user ${userId}`);
      return res.status(200).json({ message: "Bio updated successfully." });
    }

    // If a profile exists, update it
    userProfile.bio = bio;
    await userProfile.save();

    logger.info(`Updated bio for user ${userId}`);
    return res.status(200).json({ message: "Bio updated successfully." });

  } catch (error) {
    logger.error("Error updating profile", { userId: req.user?.id, error });
    return res.status(500).json({ message: "Server error while updating profile." });
  }
};


export const googleSignIn = async (req, res) => {
  try {
    logger.info("Received Google sign-in request");
    const { idToken } = req.body;

    if (!idToken) {
      logger.warn("Google sign-in failed: Missing idToken");
      return res.status(400).json({ message: "Missing idToken" });
    }

    // Support multiple Google Client IDs (Android/iOS/Web) via comma-separated env
    const allowedClientIds = (process.env.GOOGLE_CLIENT_IDS || process.env.GOOGLE_CLIENT_ID || "")
      .split(",")
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    if (!allowedClientIds.length) {
      logger.error("Google sign-in failed: GOOGLE_CLIENT_ID(S) not configured");
      return res.status(500).json({ message: "Server missing GOOGLE_CLIENT_ID(S)" });
    }

    logger.debug("Verifying Google ID token", { audiences: allowedClientIds });
    const googleClient = new OAuth2Client(allowedClientIds[0]);

    // Verify Google ID token (accept multiple audiences)
    let payload;
    try {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: allowedClientIds,
      });
      payload = ticket.getPayload();
    } catch (e) {
      logger.warn("Google ID token verification failed", { error: e.message });
      return res.status(401).json({ message: "Invalid Google token", error: e.message });
    }

    // Extra safety: ensure aud in allowed list
    const aud = payload?.aud;
    if (!aud || !allowedClientIds.includes(aud)) {
      logger.warn("Google sign-in failed: Token audience not allowed", { aud });
      return res.status(401).json({ message: "Invalid Google token audience" });
    }

    const email = payload?.email;
    const name = payload?.name || email?.split("@")[0];

    if (!email) {
      logger.warn("Google sign-in failed: Cannot extract email from Google token");
      return res.status(400).json({ message: "Cannot extract email from Google token" });
    }

    logger.info("Google token verified", { email });

    // Find or create user
    logger.debug("Looking for existing user", { email });
    let user = await User.findOne({ where: { email } });
    if (!user) {
      logger.debug("Creating new user from Google", { name, email });
      user = await User.create({
        username: name,
        email,
        password: null, // no local password for social accounts
        role: "user",
      });
      // Also create a default profile for the new Google user
      await UserProfile.create({
        userId: user.id,
        avatarUrl: DEFAULT_AVATAR_URL
      });
      logger.info("New user created from Google sign-in", { id: user.id, email: user.email });
    } else {
      logger.debug("Existing user found", { id: user.id, email: user.email });
    }

    // Issue our JWT
    logger.debug("Creating JWT for Google user", { id: user.id, email: user.email, role: user.role, tierCode: user.tierCode });
    const token = createJwt(user);

    logger.info("Google sign-in successful", { email, tierCode: user.tierCode });
    res.json({
      message: "Google login successful",
      token,
      role: user.role,
      tierCode: user.tierCode || 'free',
    });
  } catch (error) {
    logger.error("Google sign-in error", error);
    res.status(500).json({ message: "Google login failed", error: error.message });
  }
};


export const requestPasswordChange = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findByPk(userId);

    if (!user || !user.email) {
      logger.warn("Password change request failed: User or email not found", { userId });
      return res.status(404).json({ message: "User or email not found." });
    }

    // Generate a 6-digit verification code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 300 * 1000); // 5 minutes (300 seconds)

    // Store the code in database (replace any existing code for this user)
    await PasswordReset.upsert(
      { userId, code, expiresAt },
      { where: { userId } }
    );
    logger.info(`Generated password change code for user ${userId}`);

    // Send the email
    const mailer = getMailer();
    await mailer.sendMail({
      from: `"Music App" <${process.env.SMTP_USER}>`,
      to: user.email,
      subject: "Your Password Change Verification Code",
      html: `
        <div style="font-family: sans-serif; padding: 20px; color: #333;">
          <h2>Password Change Request</h2>
          <p>Hi ${user.username},</p>
          <p>We received a request to change the password for your account.</p>
          <p>Your verification code is:</p>
          <p style="font-size: 24px; font-weight: bold; letter-spacing: 2px; background: #f0f0f0; padding: 10px; border-radius: 5px; display: inline-block;">${code}</p>
          <p>This code is valid for <strong>5 minutes</strong>. If you did not request this change, please ignore this email.</p>
          <hr/>
          <p style="font-size: 12px; color: #888;">Music App Team</p>
        </div>
      `,
    });

    logger.info(`Password change code sent to ${user.email}`);
    return res.status(200).json({ message: "Verification code sent to your email." });

  } catch (error) {
    logger.error("Error requesting password change", { userId: req.user?.id, error });
    if (error.message.includes('SMTP is not configured')) {
      return res.status(500).json({ message: 'Email service is not configured on the server.' });
    }
    return res.status(500).json({ message: "Server error while sending verification code." });
  }
};

export const changePassword = async (req, res) => {
  try {
    const userId = req.user.id;
    const { oldPassword, newPassword, verificationCode } = req.body;

    if (!oldPassword || !newPassword || !verificationCode) {
      return res.status(400).json({ message: "Old password, new password, and verification code are required." });
    }

    // 1. Verify verification code from database
    const resetRecord = await PasswordReset.findOne({ where: { userId } });
    if (!resetRecord) {
      return res.status(400).json({ message: "No verification code requested. Please request a code first." });
    }
    if (new Date() > resetRecord.expiresAt) {
      await resetRecord.destroy(); // Clean up expired code
      return res.status(400).json({ message: "Verification code has expired. Please request a new one." });
    }
    if (resetRecord.code !== verificationCode) {
      return res.status(400).json({ message: "Invalid verification code." });
    }

    // 2. Verify old password
    const user = await User.findByPk(userId);
    if (!user || !user.password) {
      return res.status(404).json({ message: "User not found or is a social login account." });
    }

    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: "Incorrect old password." });
    }

    // 3. Update to new password
    const hashedNewPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedNewPassword;
    await user.save();

    // 4. Clean up used code
    await resetRecord.destroy();

    logger.info(`Password changed successfully for user ${userId}`);
    return res.status(200).json({ message: "Password changed successfully." });

  } catch (error) {
    logger.error("Error changing password", { userId: req.user?.id, error });
    return res.status(500).json({ message: "Server error while changing password." });
  }
};
