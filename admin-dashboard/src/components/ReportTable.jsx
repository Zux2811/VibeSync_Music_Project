export default function ReportTable({ reports, onDeleteComment, onDeleteUser }) {
  return (
    <table className="table">
      <thead>
        <tr>
          <th>ID</th>
          <th>Bình luận</th>
          <th>Người bị báo cáo</th>
          <th>Người báo cáo</th>
          <th>Lý do</th>
          <th>Ngày</th>
          <th>Action</th>
        </tr>
      </thead>

      <tbody>
        {reports.map((r) => {
          const content = r.comment?.content ?? `#${r.commentId}`;
          const reportedUser = r.comment?.user?.username ?? r.comment?.user_id ?? "?";
          const reporter = r.user?.username ?? r.userId;
          const date = new Date(r.createdAt).toLocaleString();
          const reportedUserId = r.comment?.user?.id ?? r.comment?.user_id;
          return (
            <tr key={r.id}>
              <td>{r.id}</td>
              <td style={{maxWidth: 360, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis'}} title={content}>{content}</td>
              <td>{reportedUser}</td>
              <td>{reporter}</td>
              <td>{r.message}</td>
              <td>{date}</td>
              <td>
                <div style={{ display: 'flex', gap: 8 }}>
                  <button
                    className="danger"
                    title="Xóa bình luận (kèm các trả lời)"
                    onClick={() => onDeleteComment?.(r.comment?.id ?? r.commentId)}
                  >
                    Xóa bình luận
                  </button>
                  <button
                    className="warning"
                    title="Xóa tài khoản người bị báo cáo"
                    onClick={() => onDeleteUser?.(reportedUserId)}
                  >
                    Xóa tài khoản
                  </button>
                </div>
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
