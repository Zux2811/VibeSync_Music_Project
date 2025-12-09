import { useState } from "react";
import api from "../api/api";

export default function UploadSongPage() {
  const [title, setTitle] = useState("");
  const [artist, setArtist] = useState("");
  const [album, setAlbum] = useState(""); // optional
  const [audio, setAudio] = useState(null);
  const [image, setImage] = useState(null);

  const upload = async () => {
    try {
      const form = new FormData();
      form.append("title", title);
      form.append("artist", artist);
      if (album) form.append("album", album);
      if (audio) form.append("audio", audio);
      if (image) form.append("image", image);

      await api.post("/songs/upload", form, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      alert("Tải lên thành công!");
      // reset
      setTitle("");
      setArtist("");
      setAlbum("");
      setAudio(null);
      setImage(null);
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.message || "Upload thất bại");
    }
  };

  return (
    <div>
      <h2>Tải bài hát</h2>

      <input placeholder="Tiêu đề" value={title} onChange={(e) => setTitle(e.target.value)} />
      <input placeholder="Nghệ sĩ" value={artist} onChange={(e) => setArtist(e.target.value)} />
      <input placeholder="Album (tuỳ chọn)" value={album} onChange={(e) => setAlbum(e.target.value)} />

      <label>Chọn file audio:</label>
      <input type="file" accept="audio/*" onChange={(e) => setAudio(e.target.files[0])} />

      <label>Chọn ảnh bìa:</label>
      <input type="file" accept="image/*" onChange={(e) => setImage(e.target.files[0])} />

      <button onClick={upload}>Upload</button>
    </div>
  );
}
