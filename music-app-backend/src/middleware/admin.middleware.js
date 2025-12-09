// Admin-only guard. Assumes authMiddleware has already verified the JWT
// and populated req.user. This prevents duplicated token parsing and keeps
// verification logic in a single place.
export default function adminAuth(req, res, next) {
  try {
    const user = req.user;
    if (!user) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const role = (user.role ?? "").toString().trim().toLowerCase();
    if (role !== "admin") {
      return res.status(403).json({ message: "You are not admin" });
    }

    return next();
  } catch (err) {
    return res.status(401).json({ message: "Unauthorized" });
  }
}
