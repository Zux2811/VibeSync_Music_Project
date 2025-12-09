import UserProfile from "../models/userProfile.model.js";
import User from "../models/user.model.js";

export const createOrUpdateProfile = async (req, res) => {
  try {
    // Prefer camelCase payload; support legacy snake_case for compatibility
    const { userId, avatarUrl, bio } = req.body;
    const resolvedUserId = userId ?? req.body.user_id;
    const resolvedAvatarUrl = avatarUrl ?? req.body.avatar_url;

    const user = await User.findByPk(resolvedUserId);
    if (!user) return res.status(404).json({ message: "Người dùng không tồn tại" });

    // Use model attribute names so Sequelize maps them via `field`
    const [profile, created] = await UserProfile.upsert({
      userId: resolvedUserId,
      avatarUrl: resolvedAvatarUrl,
      bio,
    });

    res.json({
      message: created ? "Tạo hồ sơ thành công" : "Cập nhật hồ sơ thành công",
      profile,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getProfile = async (req, res) => {
  try {
    const userIdParam = req.params.userId ?? req.params.user_id;
    const profile = await UserProfile.findOne({ where: { userId: userIdParam } });
    if (!profile) return res.status(404).json({ message: "Chưa có hồ sơ" });
    res.json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
