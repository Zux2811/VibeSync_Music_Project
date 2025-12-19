import { Box, IconButton, Tooltip, Chip, Avatar } from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import PersonIcon from '@mui/icons-material/Person';
import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';

export default function UserTable({ users, onDelete }) {
  if (!users.length) {
    return (
      <Box sx={{ p: 6, textAlign: 'center', color: '#94a3b8' }}>
        <PersonIcon sx={{ fontSize: 48, opacity: 0.5, mb: 2 }} />
        <Box sx={{ fontWeight: 500 }}>Không có người dùng nào</Box>
      </Box>
    );
  }

  const formatDate = (dateStr) => {
    if (!dateStr) return '—';
    const date = new Date(dateStr);
    return date.toLocaleDateString('vi-VN', { 
      day: '2-digit', 
      month: '2-digit', 
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <table className="table">
      <thead>
        <tr>
          <th style={{ width: 60 }}>ID</th>
          <th>Người dùng</th>
          <th>Email</th>
          <th style={{ width: 100 }}>Vai trò</th>
          <th style={{ width: 160 }}>Ngày tạo</th>
          <th style={{ width: 80 }}>Thao tác</th>
        </tr>
      </thead>

      <tbody>
        {users.map((u) => (
          <tr key={u.id}>
            <td>
              <Chip 
                label={`#${u.id}`} 
                size="small" 
                sx={{ 
                  backgroundColor: 'rgba(99, 102, 241, 0.1)', 
                  color: '#6366f1',
                  fontWeight: 600,
                  fontSize: '0.75rem'
                }} 
              />
            </td>
            <td>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                <Avatar 
                  sx={{ 
                    width: 36, 
                    height: 36, 
                    backgroundColor: u.role === 'admin' ? '#6366f1' : '#10b981',
                    fontSize: '0.875rem',
                    fontWeight: 600
                  }}
                >
                  {u.username?.[0]?.toUpperCase() || u.email?.[0]?.toUpperCase() || '?'}
                </Avatar>
                <Box sx={{ fontWeight: 600, color: '#1e293b' }}>
                  {u.username || 'Chưa đặt tên'}
                </Box>
              </Box>
            </td>
            <td>
              <Box sx={{ color: '#64748b' }}>{u.email}</Box>
            </td>
            <td>
              {u.role === 'admin' ? (
                <Chip
                  icon={<AdminPanelSettingsIcon sx={{ fontSize: 16 }} />}
                  label="Admin"
                  size="small"
                  sx={{
                    backgroundColor: 'rgba(236, 72, 153, 0.1)',
                    color: '#ec4899',
                    fontWeight: 600,
                    '& .MuiChip-icon': { color: '#ec4899' }
                  }}
                />
              ) : (
                <Chip
                  label="User"
                  size="small"
                  sx={{
                    backgroundColor: 'rgba(16, 185, 129, 0.1)',
                    color: '#10b981',
                    fontWeight: 600
                  }}
                />
              )}
            </td>
            <td>
              <Box sx={{ color: '#94a3b8', fontSize: '0.875rem' }}>
                {formatDate(u.createdAt)}
              </Box>
            </td>
            <td>
              <Tooltip title="Xóa người dùng">
                <IconButton 
                  size="small"
                  onClick={() => onDelete(u.id)}
                  sx={{ 
                    backgroundColor: 'rgba(239, 68, 68, 0.1)',
                    color: '#ef4444',
                    '&:hover': { backgroundColor: 'rgba(239, 68, 68, 0.2)' }
                  }}
                >
                  <DeleteIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}