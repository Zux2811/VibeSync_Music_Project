import { User, ArtistVerification, ArtistProfile, UserProfile } from "../models/index.js";
import cloudinary from "../config/cloudinary.js";
import { Readable } from "stream";
import logger from "../utils/logger.js";
import { getMailer } from "../config/mailer.js";

// Convert buffer to stream for Cloudinary
function bufferToStream(buffer) {
  const readable = new Readable();
  readable.push(buffer);
  readable.push(null);
  return readable;
}

// ===============================
// 📝 Submit artist verification request
// ===============================
export const submitVerificationRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      stageName,
      realName,
      bio,
      facebookUrl,
      youtubeUrl,
      spotifyUrl,
      instagramUrl,
      websiteUrl,
      releasedSongLinks,
      contactEmail,
      contactPhone
    } = req.body;

    // Check if user already has a pending request
    const existingRequest = await ArtistVerification.findOne({
      where: { userId, status: 'pending' }
    });
    if (existingRequest) {
      return res.status(400).json({ message: "You already have a pending verification request" });
    }

    // Check if user is already an artist
    const user = await User.findByPk(userId);
    if (user.role === 'artist') {
      return res.status(400).json({ message: "You are already a verified artist" });
    }

    // Handle file uploads
    let idDocumentUrl = null;
    let authorizationDocUrl = null;
    let profileImageUrl = null;

    if (req.files) {
      // Upload ID document
      if (req.files.idDocument && req.files.idDocument[0]) {
        idDocumentUrl = await new Promise((resolve, reject) => {
          const stream = cloudinary.uploader.upload_stream(
            { folder: "artist-verification/id-docs", resource_type: "auto" },
            (err, result) => {
              if (err) return reject(err);
              resolve(result.secure_url);
            }
          );
          bufferToStream(req.files.idDocument[0].buffer).pipe(stream);
        });
      }

      // Upload authorization document
      if (req.files.authorizationDoc && req.files.authorizationDoc[0]) {
        authorizationDocUrl = await new Promise((resolve, reject) => {
          const stream = cloudinary.uploader.upload_stream(
            { folder: "artist-verification/auth-docs", resource_type: "auto" },
            (err, result) => {
              if (err) return reject(err);
              resolve(result.secure_url);
            }
          );
          bufferToStream(req.files.authorizationDoc[0].buffer).pipe(stream);
        });
      }

      // Upload profile image
      if (req.files.profileImage && req.files.profileImage[0]) {
        profileImageUrl = await new Promise((resolve, reject) => {
          const stream = cloudinary.uploader.upload_stream(
            { folder: "artist-verification/profile-images", resource_type: "image" },
            (err, result) => {
              if (err) return reject(err);
              resolve(result.secure_url);
            }
          );
          bufferToStream(req.files.profileImage[0].buffer).pipe(stream);
        });
      }
    }

    // Create verification request
    const verification = await ArtistVerification.create({
      userId,
      stageName,
      realName,
      bio,
      facebookUrl,
      youtubeUrl,
      spotifyUrl,
      instagramUrl,
      websiteUrl,
      releasedSongLinks: releasedSongLinks ? JSON.parse(releasedSongLinks) : [],
      idDocumentUrl,
      authorizationDocUrl,
      profileImageUrl,
      contactEmail,
      contactPhone,
      status: 'pending'
    });

    logger.info("Artist verification request submitted", { userId, verificationId: verification.id });
    res.status(201).json({
      message: "Verification request submitted successfully",
      verification: {
        id: verification.id,
        status: verification.status,
        createdAt: verification.createdAt
      }
    });
  } catch (error) {
    logger.error("Error submitting verification request", error);
    res.status(500).json({ message: "Error submitting request", error: error.message });
  }
};

// ===============================
// 📝 Get my verification requests
// ===============================
export const getMyVerificationRequests = async (req, res) => {
  try {
    const userId = req.user.id;

    const requests = await ArtistVerification.findAll({
      where: { userId },
      order: [['createdAt', 'DESC']]
    });

    res.json(requests);
  } catch (error) {
    logger.error("Error fetching verification requests", error);
    res.status(500).json({ message: "Error fetching requests", error: error.message });
  }
};

// ===============================
// 👑 ADMIN: Get all verification requests
// ===============================
export const getAllVerificationRequests = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;
    const status = req.query.status; // Filter by status

    const whereClause = {};
    if (status && ['pending', 'approved', 'rejected'].includes(status)) {
      whereClause.status = status;
    }

    const { count, rows: requests } = await ArtistVerification.findAndCountAll({
      where: whereClause,
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'username', 'email', 'role']
      }],
      offset,
      limit,
      order: [['createdAt', 'DESC']]
    });

    const totalPages = Math.ceil(count / limit);

    res.json({
      items: requests,
      page,
      limit,
      total: count,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1
    });
  } catch (error) {
    logger.error("Error fetching all verification requests", error);
    res.status(500).json({ message: "Error fetching requests", error: error.message });
  }
};

// ===============================
// 👑 ADMIN: Get verification request by ID
// ===============================
export const getVerificationRequestById = async (req, res) => {
  try {
    const { id } = req.params;

    const request = await ArtistVerification.findByPk(id, {
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'username', 'email', 'role', 'createdAt'],
        include: [{
          model: UserProfile,
          as: 'profile',
          attributes: ['bio', 'avatarUrl']
        }]
      }]
    });

    if (!request) {
      return res.status(404).json({ message: "Verification request not found" });
    }

    res.json(request);
  } catch (error) {
    logger.error("Error fetching verification request", error);
    res.status(500).json({ message: "Error fetching request", error: error.message });
  }
};

// ===============================
// 👑 ADMIN: Approve verification request
// ===============================
export const approveVerificationRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const adminId = req.user.id;
    const { adminNotes } = req.body;

    const request = await ArtistVerification.findByPk(id, {
      include: [{ model: User, as: 'user' }]
    });

    if (!request) {
      return res.status(404).json({ message: "Verification request not found" });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({ message: "This request has already been processed" });
    }

    // Update verification request
    await request.update({
      status: 'approved',
      adminNotes,
      reviewedBy: adminId,
      reviewedAt: new Date()
    });

    // Update user role to artist
    await User.update({ role: 'artist' }, { where: { id: request.userId } });

    // Create artist profile
    await ArtistProfile.create({
      userId: request.userId,
      stageName: request.stageName,
      bio: request.bio,
      avatarUrl: request.profileImageUrl,
      socialLinks: {
        facebook: request.facebookUrl,
        youtube: request.youtubeUrl,
        spotify: request.spotifyUrl,
        instagram: request.instagramUrl,
        website: request.websiteUrl
      },
      contactEmail: request.contactEmail,
      verified: true
    });

    // Send approval email
    try {
      const mailer = getMailer();
      await mailer.sendMail({
        from: `"VibeSync Music" <${process.env.SMTP_USER}>`,
        to: request.contactEmail || request.user.email,
        subject: "🎉 Chúc mừng! Yêu cầu xác minh nghệ sĩ đã được duyệt",
        html: `
          <div style="font-family: sans-serif; padding: 20px; color: #333; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #6366f1;">🎉 Chúc mừng ${request.stageName}!</h2>
            <p>Yêu cầu xác minh nghệ sĩ của bạn đã được <strong>duyệt thành công</strong>!</p>
            <p>Bây giờ bạn có thể:</p>
            <ul>
              <li>✅ Tải lên và quản lý bài hát của mình</li>
              <li>✅ Tạo album</li>
              <li>✅ Xem thống kê và lượt nghe</li>
              <li>✅ Tương tác với người hâm mộ</li>
            </ul>
            <p>Đăng nhập ngay để bắt đầu chia sẻ âm nhạc của bạn với thế giới!</p>
            ${adminNotes ? `<p><strong>Ghi chú từ admin:</strong> ${adminNotes}</p>` : ''}
            <hr/>
            <p style="font-size: 12px; color: #888;">VibeSync Music Team</p>
          </div>
        `
      });
      logger.info("Approval email sent", { to: request.contactEmail || request.user.email });
    } catch (emailError) {
      logger.warn("Failed to send approval email", emailError);
    }

    logger.info("Artist verification approved", { verificationId: id, userId: request.userId, approvedBy: adminId });
    res.json({ message: "Verification approved successfully", request });
  } catch (error) {
    logger.error("Error approving verification", error);
    res.status(500).json({ message: "Error approving request", error: error.message });
  }
};

// ===============================
// 👑 ADMIN: Reject verification request
// ===============================
export const rejectVerificationRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const adminId = req.user.id;
    const { rejectionReason, adminNotes } = req.body;

    if (!rejectionReason) {
      return res.status(400).json({ message: "Rejection reason is required" });
    }

    const request = await ArtistVerification.findByPk(id, {
      include: [{ model: User, as: 'user' }]
    });

    if (!request) {
      return res.status(404).json({ message: "Verification request not found" });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({ message: "This request has already been processed" });
    }

    // Update verification request
    await request.update({
      status: 'rejected',
      rejectionReason,
      adminNotes,
      reviewedBy: adminId,
      reviewedAt: new Date()
    });

    // Send rejection email
    try {
      const mailer = getMailer();
      await mailer.sendMail({
        from: `"VibeSync Music" <${process.env.SMTP_USER}>`,
        to: request.contactEmail || request.user.email,
        subject: "Thông báo về yêu cầu xác minh nghệ sĩ",
        html: `
          <div style="font-family: sans-serif; padding: 20px; color: #333; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #ef4444;">Thông báo về yêu cầu xác minh</h2>
            <p>Xin chào ${request.stageName},</p>
            <p>Rất tiếc, yêu cầu xác minh nghệ sĩ của bạn chưa được duyệt.</p>
            <p><strong>Lý do:</strong></p>
            <p style="background: #fef2f2; padding: 15px; border-radius: 8px; border-left: 4px solid #ef4444;">
              ${rejectionReason}
            </p>
            <p>Bạn có thể gửi lại yêu cầu sau khi đã cập nhật thông tin theo yêu cầu.</p>
            <p>Nếu bạn có thắc mắc, vui lòng liên hệ với chúng tôi.</p>
            <hr/>
            <p style="font-size: 12px; color: #888;">VibeSync Music Team</p>
          </div>
        `
      });
      logger.info("Rejection email sent", { to: request.contactEmail || request.user.email });
    } catch (emailError) {
      logger.warn("Failed to send rejection email", emailError);
    }

    logger.info("Artist verification rejected", { verificationId: id, userId: request.userId, rejectedBy: adminId });
    res.json({ message: "Verification rejected", request });
  } catch (error) {
    logger.error("Error rejecting verification", error);
    res.status(500).json({ message: "Error rejecting request", error: error.message });
  }
};

// ===============================
// 👑 ADMIN: Get verification stats
// ===============================
export const getVerificationStats = async (req, res) => {
  try {
    const pendingCount = await ArtistVerification.count({ where: { status: 'pending' } });
    const approvedCount = await ArtistVerification.count({ where: { status: 'approved' } });
    const rejectedCount = await ArtistVerification.count({ where: { status: 'rejected' } });
    const totalArtists = await User.count({ where: { role: 'artist' } });

    res.json({
      pending: pendingCount,
      approved: approvedCount,
      rejected: rejectedCount,
      totalArtists
    });
  } catch (error) {
    logger.error("Error fetching verification stats", error);
    res.status(500).json({ message: "Error fetching stats", error: error.message });
  }
};
