import { useEffect, useMemo, useState } from "react";
import api from "../api/api";

export default function SongEditModal({ song, onClose, onSaved, onNotify }) {
  const [title, setTitle] = useState(song?.title || "");
  const [artist, setArtist] = useState(song?.artist || "");
  const [album, setAlbum] = useState(song?.album || "");
  const [image, setImage] = useState(null);
  const [audio, setAudio] = useState(null);
  const [loading, setLoading] = useState(false);

  const imagePreview = useMemo(() => (image ? URL.createObjectURL(image) : null), [image]);
  const audioPreview = useMemo(() => (audio ? URL.createObjectURL(audio) : null), [audio]);

  useEffect(() => {
    return () => {
      if (imagePreview) URL.revokeObjectURL(imagePreview);
      if (audioPreview) URL.revokeObjectURL(audioPreview);
    };
  }, [imagePreview, audioPreview]);

  const submit = async () => {
    try {
      setLoading(true);
      const form = new FormData();
      if (title !== undefined) form.append("title", title);
      if (artist !== undefined) form.append("artist", artist);
      if (album !== undefined) form.append("album", album);
      if (image) form.append("image", image);
      if (audio) form.append("audio", audio);

      await api.put(`/songs/${song.id}`, form, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      onSaved?.();
      onNotify?.({ type: "success", message: "Cập nhật bài hát thành công" });
      onClose?.();
    } catch (err) {
      console.error(err);
      onNotify?.({ type: "error", message: err.response?.data?.message || "Cập nhật thất bại" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={styles.backdrop}>
      <div style={styles.modal}>
        <h3>Sửa bài hát (ID: {song.id})</h3>

        <label>Tiêu đề</label>
        <input value={title} onChange={(e) => setTitle(e.target.value)} />

        <label>Nghệ sĩ</label>
        <input value={artist} onChange={(e) => setArtist(e.target.value)} />

        <label>Album (tuỳ chọn)</label>
        <input value={album} onChange={(e) => setAlbum(e.target.value)} />

        <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
          <div>
            <label>Ảnh bìa hiện tại</label>
            <div>{song.imageUrl ? <img src={song.imageUrl} width={100} /> : <span>—</span>}</div>
          </div>
          <div>
            <label>Ảnh bìa mới</label>
            <input type="file" accept="image/*" onChange={(e) => setImage(e.target.files[0])} />
            {imagePreview && (
              <div style={{ marginTop: 8 }}>
                <img src={imagePreview} width={100} />
              </div>
            )}
          </div>
        </div>

        <div style={{ display: "flex", gap: 12, alignItems: "center", marginTop: 8 }}>
          <div style={{ flex: 1 }}>
            <label>Audio hiện tại</label>
            {song.audioUrl ? (
              <audio controls src={song.audioUrl} style={{ display: "block", width: "100%" }} />
            ) : (
              <div>—</div>
            )}
          </div>
          <div style={{ flex: 1 }}>
            <label>Audio mới</label>
            <input type="file" accept="audio/*" onChange={(e) => setAudio(e.target.files[0])} />
            {audioPreview && (
              <audio controls src={audioPreview} style={{ display: "block", width: "100%", marginTop: 8 }} />
            )}
          </div>
        </div>

        <div style={{ marginTop: 16, display: "flex", gap: 8 }}>
          <button onClick={submit} disabled={loading}>
            {loading ? "Đang lưu..." : "Lưu"}
          </button>
          <button onClick={onClose}>Hủy</button>
        </div>
      </div>
    </div>
  );
}

const styles = {
  backdrop: {
    position: "fixed",
    inset: 0,
    background: "rgba(0,0,0,0.5)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    zIndex: 1000,
  },
  modal: {
    background: "#fff",
    borderRadius: 8,
    padding: 16,
    minWidth: 520,
    maxWidth: 720,
    display: "flex",
    flexDirection: "column",
    gap: 8,
  },
};

