import { useAuth } from "../context/AuthContext";
import { useTheme } from "../context/ThemeContext";
import NotificationsNoneIcon from '@mui/icons-material/NotificationsNone';
import Brightness4Icon from '@mui/icons-material/Brightness4';
import Brightness7Icon from '@mui/icons-material/Brightness7';
import { Badge, IconButton, Avatar, Box, Typography, Tooltip } from '@mui/material';

export default function Topbar() {
  const { admin } = useAuth();
  const { isDarkMode, toggleTheme } = useTheme();
  
  return (
    <header className={`topbar ${isDarkMode ? 'dark' : 'light'}`}>
      <Box>
        <Typography variant="h5" component="h1" sx={{ 
          fontWeight: 700,
          background: 'linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
        }}>
          VibeSync Dashboard
        </Typography>
        <Typography variant="body2" sx={{ color: isDarkMode ? '#94a3b8' : '#64748b' }}>
          Chào mừng trở lại!
        </Typography>
      </Box>
      
      <Box className="topbar-right">
        <Tooltip title={isDarkMode ? "Chế độ sáng" : "Chế độ tối"}>
          <IconButton 
            onClick={toggleTheme}
            sx={{ 
              color: isDarkMode ? '#38bdf8' : '#0ea5e9',
              backgroundColor: isDarkMode ? 'rgba(56, 189, 248, 0.1)' : 'rgba(14, 165, 233, 0.1)',
              '&:hover': {
                backgroundColor: isDarkMode ? 'rgba(56, 189, 248, 0.2)' : 'rgba(14, 165, 233, 0.2)',
              }
            }}
          >
            {isDarkMode ? <Brightness7Icon /> : <Brightness4Icon />}
          </IconButton>
        </Tooltip>
        
        <IconButton sx={{ color: isDarkMode ? '#94a3b8' : '#64748b' }}>
          <Badge badgeContent={3} color="error">
            <NotificationsNoneIcon />
          </Badge>
        </IconButton>
        
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Avatar 
            sx={{ 
              width: 40, 
              height: 40,
              background: 'linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%)',
              fontWeight: 600
            }}
          >
            {admin?.username?.[0]?.toUpperCase() || 'A'}
          </Avatar>
          <Box sx={{ display: { xs: 'none', sm: 'block' } }}>
            <Typography variant="body2" sx={{ fontWeight: 600, color: isDarkMode ? '#f0f9ff' : '#0c4a6e' }}>
              {admin?.username || 'Admin'}
            </Typography>
            <Typography variant="caption" sx={{ color: isDarkMode ? '#94a3b8' : '#64748b' }}>
              Administrator
            </Typography>
          </Box>
        </Box>
      </Box>
    </header>
  );
}