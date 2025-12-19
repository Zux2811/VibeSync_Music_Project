import { Box, IconButton, Tooltip, Chip, Avatar } from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import PersonOffIcon from '@mui/icons-material/PersonOff';
import ReportIcon from '@mui/icons-material/Report';
import CommentIcon from '@mui/icons-material/Comment';

export default function ReportTable({ reports, onDeleteComment, onDeleteUser }) {
  if (!reports.length) {
    return (
      <Box sx={{ p: 6, textAlign: 'center', color: '#94a3b8' }}>
        <ReportIcon sx={{ fontSize: 48, opacity: 0.5, mb: 2 }} />
        <Box sx={{ fontWeight: 500 }}>Không có báo cáo nào</Box>
        <Box sx={{ fontSize: '0.875rem', mt: 1 }}>Hệ thống đang hoạt động tốt! 🎉</Box>
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
          <th>Nội dung bình luận</th>
          <th style={{ width: 140 }}>Người bị báo cáo</th>
          <th style={{ width: 140 }}>Người báo cáo</th>
          <th style={{ width: 180 }}>Lý do</th>
          <th style={{ width: 140 }}>Ngày</th>
          <th style={{ width: 140 }}>Thao tác</th>
        </tr>
      </thead>

      <tbody>
        {reports.map((r) => {
          const content = r.comment?.content ?? `#${r.commentId}`;
          const reportedUser = r.comment?.user?.username ?? r.comment?.user_id ?? "?";
          const reporter = r.user?.username ?? r.userId;
          const reportedUserId = r.comment?.user?.id ?? r.comment?.user_id;
          
          return (
            <tr key={r.id}>
              <td>
                <Chip 
                  label={`#${r.id}`} 
                  size="small" 
                  sx={{ 
                    backgroundColor: 'rgba(239, 68, 68, 0.1)', 
                    color: '#ef4444',
                    fontWeight: 600,
                    fontSize: '0.75rem'
                  }} 
                />
              </td>
              <td>
                <Box sx={{ 
                  display: 'flex', 
                  alignItems: 'flex-start', 
                  gap: 1.5,
                  maxWidth: 300
                }}>
                  <CommentIcon sx={{ color: '#94a3b8', fontSize: 20, mt: 0.5, flexShrink: 0 }} />
                  <Box sx={{ 
                    color: '#374151',
                    fontSize: '0.875rem',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical'
                  }} title={content}>
                    {content}
                  </Box>
                </Box>
              </td>
              <td>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Avatar sx={{ width: 28, height: 28, backgroundColor: '#ef4444', fontSize: '0.75rem' }}>
                    {reportedUser?.[0]?.toUpperCase() || '?'}
                  </Avatar>
                  <Box sx={{ fontWeight: 500, color: '#1e293b', fontSize: '0.875rem' }}>
                    {reportedUser}
                  </Box>
                </Box>
              </td>
              <td>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Avatar sx={{ width: 28, height: 28, backgroundColor: '#6366f1', fontSize: '0.75rem' }}>
                    {reporter?.[0]?.toUpperCase() || '?'}
                  </Avatar>
                  <Box sx={{ color: '#64748b', fontSize: '0.875rem' }}>
                    {reporter}
                  </Box>
                </Box>
              </td>
              <td>
                <Chip
                  label={r.message || 'Không rõ'}
                  size="small"
                  sx={{
                    backgroundColor: 'rgba(245, 158, 11, 0.1)',
                    color: '#f59e0b',
                    fontWeight: 500,
                    maxWidth: 160,
                    '& .MuiChip-label': {
                      overflow: 'hidden',
                      textOverflow: 'ellipsis'
                    }
                  }}
                  title={r.message}
                />
              </td>
              <td>
                <Box sx={{ color: '#94a3b8', fontSize: '0.875rem' }}>
                  {formatDate(r.createdAt)}
                </Box>
              </td>
              <td>
                <Box sx={{ display: 'flex', gap: 1 }}>
                  <Tooltip title="Xóa bình luận">
                    <IconButton 
                      size="small"
                      onClick={() => onDeleteComment?.(r.comment?.id ?? r.commentId)}
                      sx={{ 
                        backgroundColor: 'rgba(239, 68, 68, 0.1)',
                        color: '#ef4444',
                        '&:hover': { backgroundColor: 'rgba(239, 68, 68, 0.2)' }
                      }}
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Xóa tài khoản">
                    <IconButton 
                      size="small"
                      onClick={() => onDeleteUser?.(reportedUserId)}
                      sx={{ 
                        backgroundColor: 'rgba(245, 158, 11, 0.1)',
                        color: '#f59e0b',
                        '&:hover': { backgroundColor: 'rgba(245, 158, 11, 0.2)' }
                      }}
                    >
                      <PersonOffIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                </Box>
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
