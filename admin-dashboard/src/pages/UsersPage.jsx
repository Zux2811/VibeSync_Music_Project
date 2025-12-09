import { useEffect, useState } from "react";
import api from "../api/api";
import UserTable from "../components/UserTable";

export default function UsersPage() {
  const [users, setUsers] = useState([]);

  const fetchUsers = async () => {
    const res = await api.get("/admin/users");
    setUsers(res.data);
  };

  const deleteUser = async (id) => {
    if (confirm("Bạn chắc chắn muốn xóa?")) {
      await api.delete(`/admin/users/${id}`);
      fetchUsers();
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  return (
    <>
      <h2>Quản lý người dùng</h2>
      <UserTable users={users} onDelete={deleteUser} />
    </>
  );
}
