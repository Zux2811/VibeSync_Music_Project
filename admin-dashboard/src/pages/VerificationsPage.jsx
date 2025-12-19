import { useEffect, useState } from "react";
import api from "../api/api";
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Avatar,
  IconButton,
  Collapse,
  CircularProgress,
  Alert,
} from "@mui/material";
import {
  CheckCircle,
  Cancel,
  ExpandMore,
  ExpandLess,
  Visibility,
  Email,
  Language,
  Facebook,
  YouTube,
} from "@mui/icons-material";

export default function VerificationsPage() {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [expandedRow, setExpandedRow] = useState(null);
  const [rejectDialog, setRejectDialog] = useState({ open: false, request: null });
  const [rejectReason, setRejectReason] = useState("");
  const [processing, setProcessing] = useState(false);
  const [stats, setStats] = useState({ pending: 0, approved: 0, rejected: 0 });
  const [filter, setFilter] = useState("pending");

  useEffect(() => {
    fetchRequests();
    fetchStats();
  }, [filter]);

  const fetchRequests = async () => {
    try {
      setLoading(true);
      const res = await api.get(`/artist-verification/admin/requests?status=${filter}`);
      setRequests(res.data.items || []);
      setError(null);
    } catch (err) {
      setError("Failed to load verification requests");
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      const res = await api.get("/artist-verification/admin/stats");
      setStats(res.data);
    } catch (err) {
      console.error("Failed to load stats", err);
    }
  };

  const handleApprove = async (request) => {
    if (!window.confirm(`Approve artist verification for "${request.stageName}"?`)) return;
    
    try {
      setProcessing(true);
      await api.post(`/artist-verification/admin/requests/${request.id}/approve`);
      fetchRequests();
      fetchStats();
    } catch (err) {
      alert("Failed to approve request");
      console.error(err);
    } finally {
      setProcessing(false);
    }
  };

  const handleReject = async () => {
    if (!rejectReason.trim()) {
      alert("Please provide a rejection reason");
      return;
    }

    try {
      setProcessing(true);
      await api.post(`/artist-verification/admin/requests/${rejectDialog.request.id}/reject`, {
        rejectionReason: rejectReason,
      });
      setRejectDialog({ open: false, request: null });
      setRejectReason("");
      fetchRequests();
      fetchStats();
    } catch (err) {
      alert("Failed to reject request");
      console.error(err);
    } finally {
      setProcessing(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case "approved":
        return "success";
      case "rejected":
        return "error";
      default:
        return "warning";
    }
  };

  return (
    <Box>
      <Typography variant="h4" sx={{ mb: 3, fontWeight: 700 }}>
        Artist Verifications
      </Typography>

      {/* Stats Cards */}
      <Box sx={{ display: "flex", gap: 2, mb: 3, flexWrap: "wrap" }}>
        <Paper
          sx={{
            p: 2,
            flex: 1,
            minWidth: 150,
            cursor: "pointer",
            border: filter === "pending" ? "2px solid #f59e0b" : "none",
          }}
          onClick={() => setFilter("pending")}
        >
          <Typography variant="h4" color="warning.main">
            {stats.pending}
          </Typography>
          <Typography color="text.secondary">Pending</Typography>
        </Paper>
        <Paper
          sx={{
            p: 2,
            flex: 1,
            minWidth: 150,
            cursor: "pointer",
            border: filter === "approved" ? "2px solid #10b981" : "none",
          }}
          onClick={() => setFilter("approved")}
        >
          <Typography variant="h4" color="success.main">
            {stats.approved}
          </Typography>
          <Typography color="text.secondary">Approved</Typography>
        </Paper>
        <Paper
          sx={{
            p: 2,
            flex: 1,
            minWidth: 150,
            cursor: "pointer",
            border: filter === "rejected" ? "2px solid #ef4444" : "none",
          }}
          onClick={() => setFilter("rejected")}
        >
          <Typography variant="h4" color="error.main">
            {stats.rejected}
          </Typography>
          <Typography color="text.secondary">Rejected</Typography>
        </Paper>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
          <CircularProgress />
        </Box>
      ) : requests.length === 0 ? (
        <Paper sx={{ p: 4, textAlign: "center" }}>
          <Typography color="text.secondary">
            No {filter} verification requests
          </Typography>
        </Paper>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell width={50}></TableCell>
                <TableCell>Artist</TableCell>
                <TableCell>Contact</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Submitted</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {requests.map((request) => (
                <>
                  <TableRow key={request.id} hover>
                    <TableCell>
                      <IconButton
                        size="small"
                        onClick={() =>
                          setExpandedRow(expandedRow === request.id ? null : request.id)
                        }
                      >
                        {expandedRow === request.id ? <ExpandLess /> : <ExpandMore />}
                      </IconButton>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
                        <Avatar src={request.profileImageUrl}>
                          {request.stageName?.[0]?.toUpperCase()}
                        </Avatar>
                        <Box>
                          <Typography fontWeight={600}>{request.stageName}</Typography>
                          <Typography variant="body2" color="text.secondary">
                            {request.realName || "—"}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">{request.contactEmail}</Typography>
                      <Typography variant="body2" color="text.secondary">
                        {request.contactPhone || "—"}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={request.status}
                        color={getStatusColor(request.status)}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      {new Date(request.createdAt).toLocaleDateString()}
                    </TableCell>
                    <TableCell align="right">
                      {request.status === "pending" && (
                        <Box sx={{ display: "flex", gap: 1, justifyContent: "flex-end" }}>
                          <Button
                            variant="contained"
                            color="success"
                            size="small"
                            startIcon={<CheckCircle />}
                            onClick={() => handleApprove(request)}
                            disabled={processing}
                          >
                            Approve
                          </Button>
                          <Button
                            variant="contained"
                            color="error"
                            size="small"
                            startIcon={<Cancel />}
                            onClick={() => setRejectDialog({ open: true, request })}
                            disabled={processing}
                          >
                            Reject
                          </Button>
                        </Box>
                      )}
                    </TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell colSpan={6} sx={{ py: 0, border: 0 }}>
                      <Collapse in={expandedRow === request.id}>
                        <Box sx={{ p: 2, bgcolor: "grey.50", borderRadius: 1, my: 1 }}>
                          <Typography variant="subtitle2" gutterBottom>
                            Details
                          </Typography>
                          {request.bio && (
                            <Typography variant="body2" sx={{ mb: 2 }}>
                              <strong>Bio:</strong> {request.bio}
                            </Typography>
                          )}
                          
                          <Typography variant="subtitle2" gutterBottom>
                            Social Links
                          </Typography>
                          <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap", mb: 2 }}>
                            {request.facebookUrl && (
                              <Chip
                                icon={<Facebook />}
                                label="Facebook"
                                size="small"
                                component="a"
                                href={request.facebookUrl}
                                target="_blank"
                                clickable
                              />
                            )}
                            {request.youtubeUrl && (
                              <Chip
                                icon={<YouTube />}
                                label="YouTube"
                                size="small"
                                component="a"
                                href={request.youtubeUrl}
                                target="_blank"
                                clickable
                              />
                            )}
                            {request.spotifyUrl && (
                              <Chip
                                label="Spotify"
                                size="small"
                                component="a"
                                href={request.spotifyUrl}
                                target="_blank"
                                clickable
                              />
                            )}
                            {request.instagramUrl && (
                              <Chip
                                label="Instagram"
                                size="small"
                                component="a"
                                href={request.instagramUrl}
                                target="_blank"
                                clickable
                              />
                            )}
                            {request.websiteUrl && (
                              <Chip
                                icon={<Language />}
                                label="Website"
                                size="small"
                                component="a"
                                href={request.websiteUrl}
                                target="_blank"
                                clickable
                              />
                            )}
                          </Box>

                          {request.releasedSongLinks?.length > 0 && (
                            <>
                              <Typography variant="subtitle2" gutterBottom>
                                Released Songs
                              </Typography>
                              <Box sx={{ display: "flex", flexDirection: "column", gap: 0.5 }}>
                                {request.releasedSongLinks.map((link, i) => (
                                  <Typography
                                    key={i}
                                    variant="body2"
                                    component="a"
                                    href={link}
                                    target="_blank"
                                    sx={{ color: "primary.main" }}
                                  >
                                    {link}
                                  </Typography>
                                ))}
                              </Box>
                            </>
                          )}

                          {request.idDocumentUrl && (
                            <Box sx={{ mt: 2 }}>
                              <Button
                                variant="outlined"
                                size="small"
                                startIcon={<Visibility />}
                                href={request.idDocumentUrl}
                                target="_blank"
                              >
                                View ID Document
                              </Button>
                            </Box>
                          )}

                          {request.rejectionReason && (
                            <Alert severity="error" sx={{ mt: 2 }}>
                              <strong>Rejection Reason:</strong> {request.rejectionReason}
                            </Alert>
                          )}
                        </Box>
                      </Collapse>
                    </TableCell>
                  </TableRow>
                </>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Reject Dialog */}
      <Dialog open={rejectDialog.open} onClose={() => setRejectDialog({ open: false, request: null })}>
        <DialogTitle>Reject Verification Request</DialogTitle>
        <DialogContent>
          <Typography sx={{ mb: 2 }}>
            Reject artist verification for "{rejectDialog.request?.stageName}"?
          </Typography>
          <TextField
            autoFocus
            fullWidth
            multiline
            rows={3}
            label="Rejection Reason"
            placeholder="Please provide a reason for rejection..."
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRejectDialog({ open: false, request: null })}>
            Cancel
          </Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleReject}
            disabled={processing || !rejectReason.trim()}
          >
            Reject
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
