import { Box, IconButton, Tooltip, Chip } from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import MusicNoteIcon from '@mui/icons-material/MusicNote';

export default function SongTable({ songs, onEdit, onDelete }) {
  if (!songs.length) {
    return (
      <Box sx={{ p: 6, textAlign: 'center', color: '#94a3b8' }}>
        <MusicNoteIcon sx={{ fontSize: 48, opacity: 0.5, mb: 2 }} />
        <Box sx={{ fontWeight: 500 }}>Không có bài hát nào</Box>
      </Box>
    );
  }

  return (
    <table className="table">
      <thead>
        <tr>
          <th style={{ width: 60 }}>ID</th>
          <th style={{ width: 80 }}>Ảnh</th>
          <th>Tiêu đề</th>
          <th>Nghệ sĩ</th>
          <th>Album</th>
          <th style={{ width: 100 }}>Audio</th>
          <th style={{ width: 120 }}>Thao tác</th>
        </tr>
      </thead>

      <tbody>
        {songs.map((s) => (
          <tr key={s.id}>
            <td>
              <Chip 
                label={`#${s.id}`} 
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
              {s.imageUrl ? (
                <img 
                  src={s.imageUrl} 
                  width="50" 
                  height="50"
                  alt={s.title}
                  style={{ 
                    borderRadius: 8, 
                    objectFit: 'cover',
                    boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
                  }} 
                />
              ) : (
                <Box sx={{ 
                  width: 50, 
                  height: 50, 
                  borderRadius: 2, 
                  backgroundColor: '#f1f5f9',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <MusicNoteIcon sx={{ color: '#94a3b8' }} />
                </Box>
              )}
            </td>
            <td>
              <Box sx={{ fontWeight: 600, color: '#1e293b' }}>{s.title}</Box>
            </td>
            <td>
              <Box sx={{ color: '#64748b' }}>{s.artist}</Box>
            </td>
            <td>
              <Box sx={{ color: '#94a3b8' }}>{s.album || '—'}</Box>
            </td>
            <td>
              {s.audioUrl ? (
                <Tooltip title="Nghe thử">
                  <IconButton 
                    size="small"
                    onClick={() => window.open(s.audioUrl, '_blank')}
                    sx={{ 
                      backgroundColor: 'rgba(16, 185, 129, 0.1)',
                      color: '#10b981',
                      '&:hover': { backgroundColor: 'rgba(16, 185, 129, 0.2)' }
                    }}
                  >
                    <PlayArrowIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              ) : (
                <Box sx={{ color: '#94a3b8' }}>—</Box>
              )}
            </td>
            <td>
              <Box sx={{ display: 'flex', gap: 1 }}>
                <Tooltip title="Chỉnh sửa">
                  <IconButton 
                    size="small"
                    onClick={() => onEdit?.(s)}
                    sx={{ 
                      backgroundColor: 'rgba(99, 102, 241, 0.1)',
                      color: '#6366f1',
                      '&:hover': { backgroundColor: 'rgba(99, 102, 241, 0.2)' }
                    }}
                  >
                    <EditIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
                <Tooltip title="Xóa">
                  <IconButton 
                    size="small"
                    onClick={() => onDelete?.(s.id)}
                    sx={{ 
                      backgroundColor: 'rgba(239, 68, 68, 0.1)',
                      color: '#ef4444',
                      '&:hover': { backgroundColor: 'rgba(239, 68, 68, 0.2)' }
                    }}
                  >
                    <DeleteIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </Box>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
