import sequelize from "../config/db.js";
import Tier from "../models/tier.model.js";
import UserSubscription from "../models/userSubscription.model.js";
import User from "../models/user.model.js";
import logger from "../utils/logger.js";

export const listActiveTiers = async (req, res) => {
  try {
    let tiers = await Tier.findAll({
      where: { isActive: true },
      attributes: ["code", "name", "features"],
      order: [["id", "ASC"]],
    });

    // Auto-seed default tiers if none exist
    if (!tiers || tiers.length === 0) {
      logger.warn("No tiers configured. Seeding default tiers: free, pro");
      await Tier.bulkCreate([
        { code: "free", name: "Free", features: { maxPlaylists: 5, offline: false }, isActive: true },
        { code: "pro", name: "Pro", features: { maxPlaylists: 1000, offline: true }, isActive: true },
      ]);
      tiers = await Tier.findAll({
        where: { isActive: true },
        attributes: ["code", "name", "features"],
        order: [["id", "ASC"]],
      });
    }

    res.json(tiers);
  } catch (e) {
    logger.error("listActiveTiers error", e);
    res.status(500).json({ message: "Server error", error: e.message });
  }
};

export const getMySubscription = async (req, res) => {
  try {
    const userId = req.user.id;

    // Load denormalized user tier
    const user = await User.findByPk(userId, { attributes: ["id", "tierCode"] });
    let tierCode = user?.tierCode || "free";

    // Find latest active subscription
    let activeSub = await UserSubscription.findOne({
      where: { userId, status: 'active' },
      order: [['startAt', 'DESC']],
    });

    // Auto-expire if past endAt
    if (activeSub && activeSub.endAt && new Date() > new Date(activeSub.endAt)) {
      await activeSub.update({ status: 'expired' });
      activeSub = null;
      // Downgrade user to free if expired
      await User.update({ tierCode: 'free', status: 'unactive' }, { where: { id: userId } });
      tierCode = 'free';
    }

    const tier = await Tier.findOne({ where: { code: tierCode, isActive: true } });
    if (!tier) {
      const free = await Tier.findOne({ where: { code: 'free' } });
      return res.json({ tierCode: 'free', features: free?.features || {}, source: 'fallback', endAt: null, remainingMs: null });
    }

    const endAt = activeSub?.endAt || null;
    const remainingMs = endAt ? Math.max(0, new Date(endAt).getTime() - Date.now()) : null;

    res.json({ tierCode: tier.code, features: tier.features, source: activeSub ? 'subscription' : 'denormalized', endAt, remainingMs });
  } catch (e) {
    logger.error('getMySubscription error', e);
    res.status(500).json({ message: 'Server error', error: e.message });
  }
};

export const upgradeToPro = async (req, res) => {
  const { provider = 'vnpay', providerRef = null, amount, durationMonths } = req.body || {};
  if (!provider || typeof provider !== 'string') {
    return res.status(400).json({ message: 'Invalid provider' });
  }
  const months = Number(durationMonths) || 1;
  if (![1, 6, 12].includes(months)) {
    return res.status(400).json({ message: 'Invalid duration. Allowed: 1, 6, 12 months' });
  }
  try {
    const userId = req.user.id;

    // Optional idempotency: avoid duplicate subscriptions for the same transaction
    if (providerRef && providerRef.toString().trim().length > 0) {
      const duplicate = await UserSubscription.findOne({ where: { userId, provider, providerRef } });
      if (duplicate) {
        return res.status(409).json({ message: 'Duplicate providerRef for this user/provider' });
      }
    }

    let proTier = await Tier.findOne({ where: { code: 'pro', isActive: true } });
    if (!proTier) {
      // Auto-seed default tiers if missing
      try {
        logger.warn('Pro tier not found. Seeding default tiers: free, pro');
        await Tier.bulkCreate([
          { code: 'free', name: 'Free', features: { maxPlaylists: 5, offline: false }, isActive: true },
          { code: 'pro', name: 'Pro', features: { maxPlaylists: 1000, offline: true }, isActive: true },
        ]);
      } catch (seedErr) {
        logger.warn('Seeding tiers may have failed or already exist:', seedErr.message);
      }
      proTier = await Tier.findOne({ where: { code: 'pro', isActive: true } });
      if (!proTier) {
        return res.status(500).json({ message: 'Pro tier not configured' });
      }
    }

    const addMonths = (date, m) => {
      const d = new Date(date.getTime());
      const day = d.getDate();
      d.setMonth(d.getMonth() + m);
      // Adjust for month rollover
      if (d.getDate() < day) d.setDate(0);
      return d;
    };

    const result = await sequelize.transaction(async (t) => {
      // Expire existing active subscriptions
      await UserSubscription.update(
        { status: 'expired', endAt: new Date() },
        { where: { userId, status: 'active' }, transaction: t }
      );

      const now = new Date();
      const endAt = addMonths(now, months);

      const sub = await UserSubscription.create(
        {
          userId,
          tierId: proTier.id,
          status: 'active',
          provider,
          providerRef,
          startAt: now,
          endAt,
        },
        { transaction: t }
      );

      // Update denormalized user tierCode and activate account
      await User.update({ tierCode: 'pro', status: 'active' }, { where: { id: userId }, transaction: t });

      return sub;
    });

    res.status(201).json({
      message: 'Upgraded to Pro',
      subscription: result,
    });
  } catch (e) {
    logger.error('upgradeToPro error', e);
    res.status(500).json({ message: 'Server error', error: e.message });
  }
};

