import { Box, Typography } from "@mui/material";
import "./LogoSection.css";

export default function LogoSection() {
  return (
    <Box className="logo-section">
      {/* Background animated circles */}
      <div className="bg-circles">
        <div className="circle circle-1"></div>
        <div className="circle circle-2"></div>
        <div className="circle circle-3"></div>
      </div>

      {/* Logo container with music waves */}
      <div className="logo-container">
        {/* Music wave rings */}
        <div className="wave-ring wave-ring-1"></div>
        <div className="wave-ring wave-ring-2"></div>
        <div className="wave-ring wave-ring-3"></div>
        <div className="wave-ring wave-ring-4"></div>

        {/* Logo image */}
        <div className="logo-wrapper">
          <img
            src="/upload/logo/logo_splash.jpg"
            alt="VibeSync Logo"
            className="logo-image"
          />
        </div>

        {/* Sound bars */}
        <div className="sound-bars">
          {[...Array(12)].map((_, i) => (
            <div
              key={i}
              className="sound-bar"
              style={{ animationDelay: `${i * 0.1}s` }}
            ></div>
          ))}
        </div>
      </div>

      {/* Branding text */}
      <Typography variant="body1" className="brand-subtitle">
        Music Admin Dashboard
      </Typography>

      {/* Floating music notes */}
      <div className="music-notes">
        <span className="note note-1">♪</span>
        <span className="note note-2">♫</span>
        <span className="note note-3">♪</span>
        <span className="note note-4">♫</span>
        <span className="note note-5">♪</span>
      </div>
    </Box>
  );
}
