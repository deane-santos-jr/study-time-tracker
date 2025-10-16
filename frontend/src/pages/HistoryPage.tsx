import React, { useState, useEffect } from 'react';
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
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  Grid,
  Chip,
  IconButton,
  Tooltip,
  CircularProgress,
} from '@mui/material';
import { FilterList, Refresh } from '@mui/icons-material';
import { format } from 'date-fns';
import { MainLayout } from '../components/layout/MainLayout';
import { sessionService } from '../services/sessionService';
import { subjectService } from '../services/subjectService';
import type { StudySession, Subject } from '../types';

const HistoryPage: React.FC = () => {
  const [sessions, setSessions] = useState<StudySession[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [filteredSessions, setFilteredSessions] = useState<StudySession[]>([]);
  const [loading, setLoading] = useState(true);

  // Filter states
  const [selectedSubject, setSelectedSubject] = useState<string>('all');
  const [startDate, setStartDate] = useState<string>('');
  const [endDate, setEndDate] = useState<string>('');

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    applyFilters();
  }, [sessions, selectedSubject, startDate, endDate]);

  const loadData = async () => {
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
  };

  const applyFilters = () => {
    let filtered = [...sessions];

    // Filter by subject
    if (selectedSubject !== 'all') {
      filtered = filtered.filter(session => session.subjectId === selectedSubject);
    }

    // Filter by start date
    if (startDate) {
      filtered = filtered.filter(session =>
        new Date(session.startTime) >= new Date(startDate)
      );
    }

    // Filter by end date
    if (endDate) {
      const endDateTime = new Date(endDate);
      endDateTime.setHours(23, 59, 59, 999);
      filtered = filtered.filter(session =>
        new Date(session.startTime) <= endDateTime
      );
    }

    // Sort by start time (newest first)
    filtered.sort((a, b) =>
      new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
    );

    setFilteredSessions(filtered);
  };

  const getSubjectName = (subjectId: string): string => {
    const subject = subjects.find(s => s.id === subjectId);
    return subject?.name || 'Unknown';
  };

  const getSubjectColor = (subjectId: string): string => {
    const subject = subjects.find(s => s.id === subjectId);
    return subject?.color || '#9e9e9e';
  };

  const formatDuration = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    if (hours > 0) {
      return `${hours}h ${minutes}m ${secs}s`;
    } else if (minutes > 0) {
      return `${minutes}m ${secs}s`;
    } else {
      return `${secs}s`;
    }
  };

  const formatDateTime = (dateString: string): string => {
    try {
      return format(new Date(dateString), 'MMM dd, yyyy hh:mm a');
    } catch {
      return 'Invalid date';
    }
  };

  const getStatusColor = (status: string): 'default' | 'primary' | 'success' | 'warning' => {
    switch (status) {
      case 'COMPLETED':
        return 'success';
      case 'ACTIVE':
        return 'primary';
      case 'PAUSED':
        return 'warning';
      default:
        return 'default';
    }
  };

  const handleRefresh = () => {
    loadData();
  };

  const handleClearFilters = () => {
    setSelectedSubject('all');
    setStartDate('');
    setEndDate('');
  };

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
              <TextField
                fullWidth
                size="small"
                type="date"
                label="Start Date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>

            <Grid item xs={12} sm={6} md={3}>
              <TextField
                fullWidth
                size="small"
                type="date"
                label="End Date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                InputLabelProps={{ shrink: true }}
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
                  <IconButton onClick={handleRefresh} color="primary">
                    <Refresh />
                  </IconButton>
                </Tooltip>
              </Box>
            </Grid>
          </Grid>

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
                : "Try adjusting your filters"}
            </Typography>
          </Paper>
        ) : (
          <TableContainer component={Paper}>
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
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredSessions.map((session) => (
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
                            bgcolor: getSubjectColor(session.subjectId),
                            flexShrink: 0,
                          }}
                        />
                        <Typography variant="body2" fontWeight={500}>
                          {getSubjectName(session.subjectId)}
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
                        color={getStatusColor(session.status)}
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
                        {formatDuration((session.totalDuration || 0) - (session.effectiveStudyTime || 0))}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Chip
                        label={session.breakCount || 0}
                        size="small"
                        variant="outlined"
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Container>
    </MainLayout>
  );
};

export default HistoryPage;
