import { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Box,
  TextField,
  Typography,
  InputAdornment,
  IconButton,
  CircularProgress,
  Alert,
} from "@mui/material";
import EmailOutlinedIcon from "@mui/icons-material/EmailOutlined";
import LockOutlinedIcon from "@mui/icons-material/LockOutlined";
import VisibilityOutlinedIcon from "@mui/icons-material/VisibilityOutlined";
import VisibilityOffOutlinedIcon from "@mui/icons-material/VisibilityOffOutlined";
import Brightness4Icon from "@mui/icons-material/Brightness4";
import Brightness7Icon from "@mui/icons-material/Brightness7";
import api from "../api/api";
import { useAuth } from "../context/AuthContext";
import { useTheme } from "../context/ThemeContext";
import "./LoginForm.css";

export default function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const navigate = useNavigate();
  const { login } = useAuth();
  const { isDarkMode, toggleTheme } = useTheme();

  const handleLogin = async (e) => {
    e?.preventDefault();
    if (!email || !password) {
      setError("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const res = await api.post("/admin/login", { email, password });
      const { token, admin } = res.data;
      login(token, admin);
      navigate("/");
    } catch (err) {
      console.error("Admin login failed:", err);
      setError(err.response?.data?.message || "Sai tài khoản hoặc mật khẩu");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box className={`login-form-section ${isDarkMode ? "dark" : "light"}`}>
      {/* Theme toggle */}
      <IconButton className="theme-toggle" onClick={toggleTheme}>
        {isDarkMode ? <Brightness7Icon /> : <Brightness4Icon />}
      </IconButton>

      {/* Mobile logo */}
      <Box className="mobile-logo">
        <img src="/upload/logo/logo_splash.jpg" alt="VibeSync" />
        <Typography variant="h5">VibeSync</Typography>
      </Box>

      <Box className="login-form-container" component="form" onSubmit={handleLogin}>
        <Typography variant="h4" className="login-title">
          Welcome Back
        </Typography>
        <Typography className="login-subtitle">
          Đăng nhập vào Admin Dashboard
        </Typography>

        {error && (
          <Alert severity="error" sx={{ mb: 3, borderRadius: 2 }}>
            {error}
          </Alert>
        )}

        <TextField
          fullWidth
          type="email"
          label="Email"
          placeholder="admin@vibesync.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          disabled={loading}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <EmailOutlinedIcon className="input-icon" />
              </InputAdornment>
            ),
          }}
          className="login-input"
        />

        <TextField
          fullWidth
          type={showPassword ? "text" : "password"}
          label="Mật khẩu"
          placeholder="••••••••"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          disabled={loading}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <LockOutlinedIcon className="input-icon" />
              </InputAdornment>
            ),
            endAdornment: (
              <InputAdornment position="end">
                <IconButton
                  onClick={() => setShowPassword(!showPassword)}
                  edge="end"
                  className="visibility-toggle"
                >
                  {showPassword ? (
                    <VisibilityOffOutlinedIcon />
                  ) : (
                    <VisibilityOutlinedIcon />
                  )}
                </IconButton>
              </InputAdornment>
            ),
          }}
          className="login-input"
        />

        <button type="submit" className="login-button" disabled={loading}>
          {loading ? (
            <CircularProgress size={24} sx={{ color: "white" }} />
          ) : (
            "Đăng nhập"
          )}
        </button>
        
      </Box>
    </Box>
  );
}
