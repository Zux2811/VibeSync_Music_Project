import { useEffect, useState } from "react";
import api from "../api/api";
import PeopleIcon from '@mui/icons-material/People';
import MusicNoteIcon from '@mui/icons-material/MusicNote';
import PlaylistPlayIcon from '@mui/icons-material/PlaylistPlay';
import ReportProblemIcon from '@mui/icons-material/ReportProblem';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import { Box, Typography, Paper, CircularProgress } from '@mui/material';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

const COLORS = ['#6366f1', '#ec4899', '#10b981', '#f59e0b'];

export default function DashboardHome() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const [usersRes, songsRes, reportsRes] = await Promise.all([
          api.get("/admin/users").catch(() => ({ data: [] })),
          api.get("/songs").catch(() => ({ data: { items: [] } })),
          api.get("/reports").catch(() => ({ data: [] })),
        ]);
        
        setStats({
          users: usersRes.data?.length || 0,
          songs: songsRes.data?.items?.length || songsRes.data?.length || 0,
          reports: reportsRes.data?.length || 0,
        });
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    };
    fetchStats();
  }, []);

  const statCards = [
    { 
      title: "Tổng người dùng", 
      value: stats?.users || 0, 
      icon: <PeopleIcon />, 
      color: "primary",
      change: "+12%",
      positive: true
    },
    { 
      title: "Tổng bài hát", 
      value: stats?.songs || 0, 
      icon: <MusicNoteIcon />, 
      color: "success",
      change: "+8%",
      positive: true
    },
    { 
      title: "Playlists", 
      value: 24, 
      icon: <PlaylistPlayIcon />, 
      color: "warning",
      change: "+5%",
      positive: true
    },
    { 
      title: "Báo cáo chờ xử lý", 
      value: stats?.reports || 0, 
      icon: <ReportProblemIcon />, 
      color: "danger",
      change: stats?.reports > 0 ? "Cần xử lý" : "Tốt",
      positive: stats?.reports === 0
    },
  ];

  // Sample data for charts
  const chartData = [
    { name: 'T2', users: 40, songs: 24 },
    { name: 'T3', users: 30, songs: 13 },
    { name: 'T4', users: 20, songs: 38 },
    { name: 'T5', users: 27, songs: 39 },
    { name: 'T6', users: 18, songs: 48 },
    { name: 'T7', users: 23, songs: 38 },
    { name: 'CN', users: 34, songs: 43 },
  ];

  const pieData = [
    { name: 'Pop', value: 400 },
    { name: 'Rock', value: 300 },
    { name: 'Jazz', value: 200 },
    { name: 'Electronic', value: 278 },
  ];

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress sx={{ color: '#6366f1' }} />
      </Box>
    );
  }

  return (
    <div>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h2" sx={{ fontWeight: 700, color: '#1e293b', mb: 1 }}>
          Dashboard
        </Typography>
        <Typography variant="body1" sx={{ color: '#64748b' }}>
          Tổng quan về hệ thống VibeSync Music
        </Typography>
      </Box>

      {/* Stats Grid */}
      <div className="stats-grid">
        {statCards.map((stat, index) => (
          <div key={index} className="stat-card">
            <div className={`stat-icon ${stat.color}`}>
              {stat.icon}
            </div>
            <div className="stat-content">
              <h3>{stat.title}</h3>
              <div className="stat-value">{stat.value.toLocaleString()}</div>
              <div className={`stat-change ${stat.positive ? 'positive' : 'negative'}`}>
                {stat.positive ? '↑' : '⚠'} {stat.change}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Charts Section */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '2fr 1fr' }, gap: 3, mt: 4 }}>
        {/* Activity Chart */}
        <Paper sx={{ p: 3, borderRadius: 3, boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 3 }}>
            <TrendingUpIcon sx={{ color: '#6366f1' }} />
            <Typography variant="h6" sx={{ fontWeight: 600 }}>
              Hoạt động tuần này
            </Typography>
          </Box>
          <ResponsiveContainer width="100%" height={280}>
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#6366f1" stopOpacity={0}/>
                </linearGradient>
                <linearGradient id="colorSongs" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#ec4899" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#ec4899" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
              <XAxis dataKey="name" stroke="#94a3b8" />
              <YAxis stroke="#94a3b8" />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: 'white', 
                  border: 'none', 
                  borderRadius: 8, 
                  boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' 
                }} 
              />
              <Area type="monotone" dataKey="users" stroke="#6366f1" fillOpacity={1} fill="url(#colorUsers)" name="Người dùng" />
              <Area type="monotone" dataKey="songs" stroke="#ec4899" fillOpacity={1} fill="url(#colorSongs)" name="Bài hát" />
            </AreaChart>
          </ResponsiveContainer>
        </Paper>

        {/* Genre Distribution */}
        <Paper sx={{ p: 3, borderRadius: 3, boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
          <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
            🎵 Phân bố thể loại
          </Typography>
          <ResponsiveContainer width="100%" height={280}>
            <PieChart>
              <Pie
                data={pieData}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={100}
                paddingAngle={5}
                dataKey="value"
              >
                {pieData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, justifyContent: 'center', mt: 2 }}>
            {pieData.map((entry, index) => (
              <Box key={entry.name} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Box sx={{ width: 12, height: 12, borderRadius: '50%', backgroundColor: COLORS[index] }} />
                <Typography variant="body2" sx={{ color: '#64748b' }}>{entry.name}</Typography>
              </Box>
            ))}
          </Box>
        </Paper>
      </Box>

      {/* Recent Activity */}
      <Paper sx={{ p: 3, borderRadius: 3, mt: 4, boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
        <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
          🕐 Hoạt động gần đây
        </Typography>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {[
            { action: "Người dùng mới đăng ký", time: "2 phút trước", color: "#10b981" },
            { action: "Bài hát mới được tải lên", time: "15 phút trước", color: "#6366f1" },
            { action: "Báo cáo comment mới", time: "1 giờ trước", color: "#f59e0b" },
            { action: "Playlist mới được tạo", time: "3 giờ trước", color: "#ec4899" },
          ].map((item, index) => (
            <Box key={index} sx={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: 2,
              p: 2,
              borderRadius: 2,
              backgroundColor: '#f8fafc',
              transition: 'all 0.2s',
              '&:hover': { backgroundColor: '#f1f5f9' }
            }}>
              <Box sx={{ 
                width: 10, 
                height: 10, 
                borderRadius: '50%', 
                backgroundColor: item.color 
              }} />
              <Typography sx={{ flex: 1, fontWeight: 500 }}>{item.action}</Typography>
              <Typography variant="body2" sx={{ color: '#94a3b8' }}>{item.time}</Typography>
            </Box>
          ))}
        </Box>
      </Paper>
    </div>
  );
}
