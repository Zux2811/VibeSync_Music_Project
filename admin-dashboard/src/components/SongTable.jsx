export default function SongTable({ songs, onEdit, onDelete }) {
  return (
    <table className="table">
      <thead>
        <tr>
          <th>ID</th>
          <th>Image</th>
          <th>Title</th>
          <th>Artist</th>
          <th>Album</th>
          <th>Audio</th>
          <th>Action</th>
        </tr>
      </thead>

      <tbody>
        {songs.map((s) => (
          <tr key={s.id}>
            <td>{s.id}</td>
            <td>
              {s.imageUrl ? <img src={s.imageUrl} width="60" /> : <span>—</span>}
            </td>
            <td>{s.title}</td>
            <td>{s.artist}</td>
            <td>{s.album || '—'}</td>
            <td>
              {s.audioUrl ? (
                <a href={s.audioUrl} target="_blank" rel="noreferrer">Nghe</a>
              ) : (
                '—'
              )}
            </td>
            <td>
              <button onClick={() => onEdit?.(s)} style={{ marginRight: 8 }}>Sửa</button>
              <button className="danger" onClick={() => onDelete?.(s.id)}>Xóa</button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
