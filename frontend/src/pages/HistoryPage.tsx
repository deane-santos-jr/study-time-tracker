import React, { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Box,
  Container,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Chip,
  IconButton,
  Tooltip,
  CircularProgress,
} from '@mui/material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { FilterList, Refresh, Delete as DeleteIcon, Note as NoteIcon, Edit as EditIcon } from '@mui/icons-material';
import { format } from 'date-fns';
import { MainLayout } from '../components/layout/MainLayout';
import { sessionService } from '../services/sessionService';
import { subjectService } from '../services/subjectService';
import { DeleteSessionDialog } from '../components/history/DeleteSessionDialog';
import { EditSessionDialog } from '../components/history/EditSessionDialog';
import { NoteSessionDialog } from '../components/history/NoteSessionDialog';
import type { StudySession, Subject } from '../types';

const formatDuration = (seconds: number): string => {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;
  if (hours > 0) return `${hours}h ${minutes}m ${secs}s`;
  if (minutes > 0) return `${minutes}m ${secs}s`;
  return `${secs}s`;
};

const formatDateTime = (dateString: string): string => {
  try {
    return format(new Date(dateString), 'MMM dd, yyyy hh:mm a');
  } catch {
    return 'Invalid date';
  }
};

const STATUS_COLORS: Record<string, 'default' | 'primary' | 'success' | 'warning'> = {
  COMPLETED: 'success',
  ACTIVE: 'primary',
  PAUSED: 'warning',
};

const HistoryPage: React.FC = () => {
  const [sessions, setSessions] = useState<StudySession[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [loading, setLoading] = useState(true);

  // Filter states
  const [selectedSubject, setSelectedSubject] = useState<string>('all');
  const [startDate, setStartDate] = useState<string>('');
  const [endDate, setEndDate] = useState<string>('');

  // Pagination
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  // Dialog states — only store the minimal identifier/object needed
  const [deleteSessionId, setDeleteSessionId] = useState<string | null>(null);
  const [editSession, setEditSession] = useState<StudySession | null>(null);
  const [noteSession, setNoteSession] = useState<StudySession | null>(null);

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const [sessionsData, subjectsData] = await Promise.all([
        sessionService.getAll(),
        subjectService.getAll(),
      ]);
      setSessions(sessionsData);
      setSubjects(subjectsData);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // O(1) subject lookups instead of .find() per row
  const subjectMap = useMemo(() => {
    const map = new Map<string, Subject>();
    for (const s of subjects) map.set(s.id, s);
    return map;
  }, [subjects]);

  // Memoized filtering + sorting — no extra useEffect/setState cycle
  const filteredSessions = useMemo(() => {
    let filtered = sessions;

    if (selectedSubject !== 'all') {
      filtered = filtered.filter((s) => s.subjectId === selectedSubject);
    }

    if (startDate) {
      const start = new Date(startDate).getTime();
      filtered = filtered.filter((s) => new Date(s.startTime).getTime() >= start);
    }

    if (endDate) {
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);
      const endMs = end.getTime();
      filtered = filtered.filter((s) => new Date(s.startTime).getTime() <= endMs);
    }

    return filtered.slice().sort(
      (a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
    );
  }, [sessions, selectedSubject, startDate, endDate]);

  // Reset to first page when filters change
  useEffect(() => {
    setPage(0);
  }, [selectedSubject, startDate, endDate]);

  // Current page slice
  const paginatedSessions = useMemo(
    () => filteredSessions.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage),
    [filteredSessions, page, rowsPerPage]
  );

  const handleClearFilters = useCallback(() => {
    setSelectedSubject('all');
    setStartDate('');
    setEndDate('');
  }, []);

  const handleDeleted = useCallback(() => {
    setDeleteSessionId(null);
    loadData();
  }, [loadData]);

  const handleEditSaved = useCallback(() => {
    setEditSession(null);
    loadData();
  }, [loadData]);

  const noteSubjectName = useMemo(
    () => (noteSession ? subjectMap.get(noteSession.subjectId)?.name || 'Unknown' : ''),
    [noteSession, subjectMap]
  );

  return (
    <MainLayout>
      <Container maxWidth="xl" sx={{ py: 4 }}>
        <Box sx={{ mb: 4 }}>
          <Typography variant="h4" gutterBottom fontWeight={600}>
            Session History
          </Typography>
          <Typography variant="body2" color="text.secondary">
            View and filter all your study sessions
          </Typography>
        </Box>

        {/* Filters */}
        <Paper sx={{ p: 3, mb: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <FilterList sx={{ mr: 1 }} />
            <Typography variant="h6">Filters</Typography>
          </Box>

          <LocalizationProvider dateAdapter={AdapterDateFns}>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6} md={3}>
                <FormControl fullWidth size="small">
                  <InputLabel>Subject</InputLabel>
                  <Select
                    value={selectedSubject}
                    label="Subject"
                    onChange={(e) => setSelectedSubject(e.target.value)}
                  >
                    <MenuItem value="all">All Subjects</MenuItem>
                    {subjects.map((subject) => (
                      <MenuItem key={subject.id} value={subject.id}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Box
                            sx={{
                              width: 12,
                              height: 12,
                              borderRadius: '50%',
                              bgcolor: subject.color,
                            }}
                          />
                          {subject.name}
                        </Box>
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} sm={6} md={3}>
                <DatePicker
                  label="Start Date"
                  value={startDate ? new Date(startDate) : null}
                  onChange={(newValue) => {
                    if (newValue) {
                      setStartDate(newValue.toISOString().split('T')[0]);
                    } else {
                      setStartDate('');
                    }
                  }}
                  format="MM/dd/yyyy"
                  slotProps={{
                    textField: { fullWidth: true, size: 'small' },
                  }}
                />
              </Grid>

              <Grid item xs={12} sm={6} md={3}>
                <DatePicker
                  label="End Date"
                  value={endDate ? new Date(endDate) : null}
                  onChange={(newValue) => {
                    if (newValue) {
                      setEndDate(newValue.toISOString().split('T')[0]);
                    } else {
                      setEndDate('');
                    }
                  }}
                  format="MM/dd/yyyy"
                  slotProps={{
                    textField: { fullWidth: true, size: 'small' },
                  }}
                />
              </Grid>

              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ display: 'flex', gap: 1 }}>
                  <Tooltip title="Clear Filters">
                    <IconButton onClick={handleClearFilters} color="primary">
                      <FilterList />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Refresh">
                    <IconButton onClick={loadData} color="primary">
                      <Refresh />
                    </IconButton>
                  </Tooltip>
                </Box>
              </Grid>
            </Grid>
          </LocalizationProvider>

          <Box sx={{ mt: 2 }}>
            <Typography variant="body2" color="text.secondary">
              Showing {filteredSessions.length} of {sessions.length} sessions
            </Typography>
          </Box>
        </Paper>

        {/* Sessions Table */}
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
            <CircularProgress />
          </Box>
        ) : filteredSessions.length === 0 ? (
          <Paper sx={{ p: 4, textAlign: 'center' }}>
            <Typography variant="h6" color="text.secondary">
              No sessions found
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
              {sessions.length === 0
                ? "Start a study session to see it here!"
                : 'Try adjusting your filters'}
            </Typography>
          </Paper>
        ) : (
          <Paper>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell><strong>Subject</strong></TableCell>
                    <TableCell><strong>Start Time</strong></TableCell>
                    <TableCell><strong>Status</strong></TableCell>
                    <TableCell align="right"><strong>Total Duration</strong></TableCell>
                    <TableCell align="right"><strong>Effective Time</strong></TableCell>
                    <TableCell align="right"><strong>Break Time</strong></TableCell>
                    <TableCell align="center"><strong>Breaks</strong></TableCell>
                    <TableCell align="center"><strong>Actions</strong></TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {paginatedSessions.map((session) => {
                    const subject = subjectMap.get(session.subjectId);
                    const breakTime =
                      (session.totalDuration || 0) -
                      (session.effectiveStudyTime || 0) -
                      (session.accumulatedPauseTime || 0);

                    return (
                      <TableRow
                        key={session.id}
                        sx={{ '&:hover': { bgcolor: 'action.hover' } }}
                      >
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Box
                              sx={{
                                width: 16,
                                height: 16,
                                borderRadius: '50%',
                                bgcolor: subject?.color || '#9e9e9e',
                                flexShrink: 0,
                              }}
                            />
                            <Typography variant="body2" fontWeight={500}>
                              {subject?.name || 'Unknown'}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {formatDateTime(session.startTime)}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={session.status}
                            color={STATUS_COLORS[session.status] || 'default'}
                            size="small"
                          />
                        </TableCell>
                        <TableCell align="right">
                          <Typography variant="body2" fontWeight={500}>
                            {formatDuration(session.totalDuration || 0)}
                          </Typography>
                        </TableCell>
                        <TableCell align="right">
                          <Typography variant="body2" color="success.main">
                            {formatDuration(session.effectiveStudyTime || 0)}
                          </Typography>
                        </TableCell>
                        <TableCell align="right">
                          <Typography variant="body2" color="warning.main">
                            {formatDuration(breakTime)}
                          </Typography>
                        </TableCell>
                        <TableCell align="center">
                          <Chip
                            label={session.breakCount || 0}
                            size="small"
                            variant="outlined"
                          />
                        </TableCell>
                        <TableCell align="center">
                          <Tooltip title="View/Add Note">
                            <IconButton
                              size="small"
                              color="primary"
                              onClick={() => setNoteSession(session)}
                            >
                              <NoteIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Edit Session">
                            <IconButton
                              size="small"
                              color="info"
                              onClick={() => setEditSession(session)}
                            >
                              <EditIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Delete Session">
                            <IconButton
                              size="small"
                              color="error"
                              onClick={() => setDeleteSessionId(session.id)}
                            >
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </TableContainer>
            <TablePagination
              component="div"
              count={filteredSessions.length}
              page={page}
              onPageChange={(_, newPage) => setPage(newPage)}
              rowsPerPage={rowsPerPage}
              onRowsPerPageChange={(e) => {
                setRowsPerPage(parseInt(e.target.value, 10));
                setPage(0);
              }}
              rowsPerPageOptions={[10, 25, 50]}
            />
          </Paper>
        )}

        {/* Dialogs — only mounted when needed */}
        {deleteSessionId && (
          <DeleteSessionDialog
            sessionId={deleteSessionId}
            onClose={() => setDeleteSessionId(null)}
            onDeleted={handleDeleted}
          />
        )}

        {editSession && (
          <EditSessionDialog
            session={editSession}
            subjects={subjects}
            onClose={() => setEditSession(null)}
            onSaved={handleEditSaved}
          />
        )}

        {noteSession && (
          <NoteSessionDialog
            session={noteSession}
            subjectName={noteSubjectName}
            onClose={() => setNoteSession(null)}
          />
        )}
      </Container>
    </MainLayout>
  );
};

export default HistoryPage;
