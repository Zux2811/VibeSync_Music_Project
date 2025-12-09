import { createContext, useContext, useState, useEffect } from "react";

const AuthContext = createContext();

const TOKEN_KEY = "jwt_token";
const ADMIN_USER_KEY = "admin_user";

export const AuthProvider = ({ children }) => {
  const [admin, setAdmin] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    try {
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
