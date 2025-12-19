import { useState, useRef } from "react";
import { Box, Typography, Paper, TextField, Snackbar, Alert, CircularProgress, LinearProgress } from "@mui/material";
import CloudUploadIcon from '@mui/icons-material/CloudUpload';
import MusicNoteIcon from '@mui/icons-material/MusicNote';
import ImageIcon from '@mui/icons-material/Image';
import AudioFileIcon from '@mui/icons-material/AudioFile';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import api from "../api/api";

export default function UploadSongPage() {
  const [title, setTitle] = useState("");
  const [artist, setArtist] = useState("");
  const [album, setAlbum] = useState("");
  const [audio, setAudio] = useState(null);
  const [image, setImage] = useState(null);
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [snack, setSnack] = useState({ open: false, message: "", severity: "success" });
  
  const audioInputRef = useRef(null);
  const imageInputRef = useRef(null);

  const notify = ({ type = "success", message = "" }) => setSnack({ open: true, message, severity: type });

  const upload = async () => {
    if (!title || !artist) {
      notify({ type: "error", message: "Vui lòng nhập tiêu đề và nghệ sĩ" });
      return;
    }
    if (!audio) {
      notify({ type: "error", message: "Vui lòng chọn file audio" });
      return;
    }

    setLoading(true);
    setProgress(0);

    try {
      const form = new FormData();
      form.append("title", title);
      form.append("artist", artist);
      if (album) form.append("album", album);
      if (audio) form.append("audio", audio);
      if (image) form.append("image", image);

      // Simulate progress
      const interval = setInterval(() => {
        setProgress((prev) => Math.min(prev + 10, 90));
      }, 200);

      await api.post("/songs/upload", form, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      clearInterval(interval);
      setProgress(100);

      notify({ type: "success", message: "🎉 Tải lên thành công!" });
      
      // Reset form
      setTitle("");
      setArtist("");
      setAlbum("");
      setAudio(null);
      setImage(null);
      if (audioInputRef.current) audioInputRef.current.value = "";
      if (imageInputRef.current) imageInputRef.current.value = "";
    } catch (err) {
      console.error(err);
      notify({ type: "error", message: err.response?.data?.message || "Upload thất bại" });
    } finally {
      setLoading(false);
      setTimeout(() => setProgress(0), 1000);
    }
  };

  return (
    <>
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
          <CloudUploadIcon sx={{ fontSize: 32, color: '#6366f1' }} />
          <Typography variant="h4" component="h2" sx={{ fontWeight: 700, color: '#1e293b' }}>
            Tải bài hát mới
          </Typography>
        </Box>
        <Typography variant="body1" sx={{ color: '#64748b' }}>
          Upload bài hát mới vào hệ thống VibeSync
        </Typography>
      </Box>

      <Paper sx={{ 
        p: 4, 
        borderRadius: 3, 
        maxWidth: 700,
        boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' 
      }}>
        {loading && (
          <Box sx={{ mb: 3 }}>
            <LinearProgress 
              variant="determinate" 
              value={progress} 
              sx={{ 
                height: 8, 
                borderRadius: 4,
                backgroundColor: '#e2e8f0',
                '& .MuiLinearProgress-bar': {
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  borderRadius: 4,
                }
              }} 
            />
            <Typography variant="body2" sx={{ color: '#64748b', mt: 1, textAlign: 'center' }}>
              Đang tải lên... {progress}%
            </Typography>
          </Box>
        )}

        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
          {/* Song Info */}
          <Box>
            <Typography variant="subtitle2" sx={{ fontWeight: 600, color: '#374151', mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
              <MusicNoteIcon sx={{ fontSize: 20, color: '#6366f1' }} />
              Thông tin bài hát
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <TextField
                label="Tiêu đề *"
                placeholder="Nhập tiêu đề bài hát"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                fullWidth
                disabled={loading}
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
              />
              <TextField
                label="Nghệ sĩ *"
                placeholder="Nhập tên nghệ sĩ"
                value={artist}
                onChange={(e) => setArtist(e.target.value)}
                fullWidth
                disabled={loading}
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
              />
              <TextField
                label="Album (tuỳ chọn)"
                placeholder="Nhập tên album"
                value={album}
                onChange={(e) => setAlbum(e.target.value)}
                fullWidth
                disabled={loading}
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
              />
            </Box>
          </Box>

          {/* File Uploads */}
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 3 }}>
            {/* Audio Upload */}
            <Box>
              <Typography variant="subtitle2" sx={{ fontWeight: 600, color: '#374151', mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                <AudioFileIcon sx={{ fontSize: 20, color: '#10b981' }} />
                File Audio *
              </Typography>
              <Box
                onClick={() => !loading && audioInputRef.current?.click()}
                sx={{
                  border: '2px dashed',
                  borderColor: audio ? '#10b981' : '#cbd5e1',
                  borderRadius: 2,
                  p: 3,
                  textAlign: 'center',
                  cursor: loading ? 'not-allowed' : 'pointer',
                  transition: 'all 0.2s',
                  backgroundColor: audio ? 'rgba(16, 185, 129, 0.05)' : '#f8fafc',
                  '&:hover': {
                    borderColor: loading ? '#cbd5e1' : '#6366f1',
                    backgroundColor: loading ? '#f8fafc' : 'rgba(99, 102, 241, 0.05)',
                  }
                }}
              >
                <input
                  ref={audioInputRef}
                  type="file"
                  accept="audio/*"
                  onChange={(e) => setAudio(e.target.files[0])}
                  style={{ display: 'none' }}
                  disabled={loading}
                />
                {audio ? (
                  <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
                    <CheckCircleIcon sx={{ fontSize: 40, color: '#10b981' }} />
                    <Typography variant="body2" sx={{ fontWeight: 500, color: '#10b981' }}>
                      {audio.name}
                    </Typography>
                    <Typography variant="caption" sx={{ color: '#64748b' }}>
                      {(audio.size / 1024 / 1024).toFixed(2)} MB
                    </Typography>
                  </Box>
                ) : (
                  <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
                    <AudioFileIcon sx={{ fontSize: 40, color: '#94a3b8' }} />
                    <Typography variant="body2" sx={{ color: '#64748b' }}>
                      Nhấn để chọn file audio
                    </Typography>
                    <Typography variant="caption" sx={{ color: '#94a3b8' }}>
                      MP3, WAV, OGG...
                    </Typography>
                  </Box>
                )}
              </Box>
            </Box>

            {/* Image Upload */}
            <Box>
              <Typography variant="subtitle2" sx={{ fontWeight: 600, color: '#374151', mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                <ImageIcon sx={{ fontSize: 20, color: '#ec4899' }} />
                Ảnh bìa (tuỳ chọn)
              </Typography>
              <Box
                onClick={() => !loading && imageInputRef.current?.click()}
                sx={{
                  border: '2px dashed',
                  borderColor: image ? '#ec4899' : '#cbd5e1',
                  borderRadius: 2,
                  p: 3,
                  textAlign: 'center',
                  cursor: loading ? 'not-allowed' : 'pointer',
                  transition: 'all 0.2s',
                  backgroundColor: image ? 'rgba(236, 72, 153, 0.05)' : '#f8fafc',
                  '&:hover': {
                    borderColor: loading ? '#cbd5e1' : '#6366f1',
                    backgroundColor: loading ? '#f8fafc' : 'rgba(99, 102, 241, 0.05)',
                  }
                }}
              >
                <input
                  ref={imageInputRef}
                  type="file"
                  accept="image/*"
                  onChange={(e) => setImage(e.target.files[0])}
                  style={{ display: 'none' }}
                  disabled={loading}
                />
                {image ? (
                  <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
                    <img 
                      src={URL.createObjectURL(image)} 
                      alt="preview" 
                      style={{ 
                        width: 60, 
                        height: 60, 
                        objectFit: 'cover', 
                        borderRadius: 8 
                      }} 
                    />
                    <Typography variant="body2" sx={{ fontWeight: 500, color: '#ec4899' }}>
                      {image.name}
                    </Typography>
                  </Box>
                ) : (
                  <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
                    <ImageIcon sx={{ fontSize: 40, color: '#94a3b8' }} />
                    <Typography variant="body2" sx={{ color: '#64748b' }}>
                      Nhấn để chọn ảnh
                    </Typography>
                    <Typography variant="caption" sx={{ color: '#94a3b8' }}>
                      JPG, PNG, WEBP...
                    </Typography>
                  </Box>
                )}
              </Box>
            </Box>
          </Box>

          {/* Submit Button */}
          <button 
            onClick={upload} 
            disabled={loading}
            style={{ 
              marginTop: 8,
              opacity: loading ? 0.7 : 1,
            }}
          >
            {loading ? (
              <CircularProgress size={24} sx={{ color: 'white' }} />
            ) : (
              <>
                <CloudUploadIcon />
                Upload bài hát
              </>
            )}
          </button>
        </Box>
      </Paper>

      <Snackbar
        open={snack.open}
        autoHideDuration={3000}
        onClose={() => setSnack((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
      >
        <Alert 
          severity={snack.severity} 
          onClose={() => setSnack((s) => ({ ...s, open: false }))}
          sx={{ borderRadius: 2 }}
        >
          {snack.message}
        </Alert>
      </Snackbar>
    </>
  );
}
