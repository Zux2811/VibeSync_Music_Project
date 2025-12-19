import { Box } from "@mui/material";
import LogoSection from "../components/LogoSection";
import LoginForm from "../components/LoginForm";
import "./LoginPage.css";

export default function AdminLoginPage() {
  return (
    <Box className="login-page-container">
      <LogoSection />
      <LoginForm />
    </Box>
  );
}
