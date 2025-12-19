import { createContext, useContext, useState, useEffect } from "react";

const AuthContext = createContext();

const TOKEN_KEY = "jwt_token";
const ADMIN_USER_KEY = "admin_user";
const API_BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:5000/api";

export const AuthProvider = ({ children }) => {
  const [admin, setAdmin] = useState(null);
  const [loading, setLoading] = useState(true);

  // Function to fetch user profile from token
  const fetchUserFromToken = async (token) => {
    try {
      const response = await fetch(`${API_BASE_URL}/auth/me`, {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });
      if (response.ok) {
        const userData = await response.json();
        if (userData?.role?.toLowerCase() === "admin") {
          localStorage.setItem(TOKEN_KEY, token);
          localStorage.setItem(ADMIN_USER_KEY, JSON.stringify(userData));
          setAdmin(userData);
          return true;
        }
      }
    } catch (error) {
      console.error("Error fetching user from token:", error);
    }
    return false;
  };

  useEffect(() => {
    const initAuth = async () => {
      try {
        // Check for token in URL query params (from Flutter redirect)
        const urlParams = new URLSearchParams(window.location.search);
        const urlToken = urlParams.get("token");

        if (urlToken) {
          // Remove token from URL for security
          window.history.replaceState({}, document.title, window.location.pathname);
          
          // Try to authenticate with the URL token
          const success = await fetchUserFromToken(urlToken);
          if (success) {
            setLoading(false);
            return;
          }
        }

        // Fall back to stored token
        const token = localStorage.getItem(TOKEN_KEY);
        const storedAdmin = localStorage.getItem(ADMIN_USER_KEY);
        if (token && storedAdmin) {
          const parsedAdmin = JSON.parse(storedAdmin);
          // Verify role before setting admin state
          if (parsedAdmin?.role?.toLowerCase() === "admin") {
            setAdmin(parsedAdmin);
          } else {
            // Clear invalid/non-admin user from storage
            localStorage.removeItem(TOKEN_KEY);
            localStorage.removeItem(ADMIN_USER_KEY);
          }
        }
      } catch (error) {
        // Clear storage if parsing fails
        localStorage.removeItem(TOKEN_KEY);
        localStorage.removeItem(ADMIN_USER_KEY);
      } finally {
        setLoading(false);
      }
    };

    initAuth();
  }, []);

  const login = (token, user) => {
    // Only log in if the user has an admin role
    if (user?.role?.toLowerCase() === "admin") {
      localStorage.setItem(TOKEN_KEY, token);
      localStorage.setItem(ADMIN_USER_KEY, JSON.stringify(user));
      setAdmin(user);
    } else {
      // Ensure non-admins are not stored
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem(ADMIN_USER_KEY);
      setAdmin(null);
    }
  };

  const logout = () => {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(ADMIN_USER_KEY);
    setAdmin(null);
  };

  if (loading) {
    return null; // Or a loading spinner, prevents flicker
  }

  return (
    <AuthContext.Provider value={{ admin, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
