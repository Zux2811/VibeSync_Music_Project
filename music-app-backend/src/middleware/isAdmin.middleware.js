export default function isAdmin(req, res, next) {
    try {
      // auth.middleware.js đã decode JWT và gắn req.user
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }
  
      if (req.user.role !== "admin") {
        return res.status(403).json({ message: "Bạn không có quyền admin" });
      }
  
      next();
    } catch (error) {
      res.status(500).json({ message: "Lỗi kiểm tra admin", error: error.message });
    }
  }
  