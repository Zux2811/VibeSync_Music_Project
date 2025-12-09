export default function UserTable({ users, onDelete }) {
    return (
      <table className="table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Email</th>
            <th>Role</th>
            <th>Create At</th>
            <th>Action</th>
          </tr>
        </thead>
  
        <tbody>
          {users.map((u) => (
            <tr key={u.id}>
              <td>{u.id}</td>
              <td>{u.email}</td>
              <td>{u.role}</td>
              <td>{u.createdAt}</td>
              <td>
                <button className="danger" onClick={() => onDelete(u.id)}>
                  Xóa
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    );
  }
  