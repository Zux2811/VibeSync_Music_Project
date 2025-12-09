import axios from "axios";

// Resolve base URL from environment with safe defaults
let baseURL = (import.meta.env.VITE_API_BASE_URL || "").trim();

if (!baseURL) {
  if (import.meta.env.DEV) {
    baseURL = "http://localhost:5000/api";
    // Warn in development when falling back to localhost
    // Ensure you set VITE_API_BASE_URL in .env for non-local environments
    // to avoid accidentally targeting localhost.
    // eslint-disable-next-line no-console
    console.warn(
      "[admin-dashboard] VITE_API_BASE_URL is not set. Using localhost fallback (http://localhost:5000/api)."
    );
  } else {
    // In production builds, require explicit configuration
    throw new Error(
      "VITE_API_BASE_URL is required in production. Set it to your backend API (e.g. https://music-app-backend-aijn.onrender.com/api)."
    );
  }
}

const api = axios.create({ baseURL });

// Attach token automatically
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("jwt_token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default api;
