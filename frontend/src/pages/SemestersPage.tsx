import { useState, useEffect } from 'react';
import {
  Container,
  Box,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  CardActions,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Alert,
  CircularProgress,
  Chip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  CalendarToday as CalendarIcon,
  Schedule as ScheduleIcon,
  CheckCircle as ActiveIcon,
  RadioButtonUnchecked as InactiveIcon,
} from '@mui/icons-material';
import { semesterService } from '../services/semesterService';
import type { Semester, CreateSemesterData } from '../types';
import { MainLayout } from '../components/layout/MainLayout';

export const SemestersPage = () => {
  const [semesters, setSemesters] = useState<Semester[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [editingSemester, setEditingSemester] = useState<Semester | null>(null);
  const [formData, setFormData] = useState<CreateSemesterData>({
    name: '',
    startDate: '',
    endDate: '',
  });

  useEffect(() => {
    loadSemesters();
  }, []);

  const loadSemesters = async () => {
    try {
      setLoading(true);
      const data = await semesterService.getAll();
      setSemesters(data);
      setError('');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load semesters');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDialog = (semester?: Semester) => {
    if (semester) {
      setEditingSemester(semester);
      setFormData({
        name: semester.name,
        startDate: semester.startDate.split('T')[0],
        endDate: semester.endDate.split('T')[0],
      });
    } else {
      setEditingSemester(null);
      setFormData({
        name: '',
        startDate: '',
        endDate: '',
      });
    }
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setEditingSemester(null);
  };

  const handleSubmit = async () => {
    try {
      if (editingSemester) {
        await semesterService.update(editingSemester.id, formData);
      } else {
        await semesterService.create(formData);
      }
      await loadSemesters();
      handleCloseDialog();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to save semester');
    }
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this semester? This will also delete all associated subjects.')) {
      try {
        await semesterService.delete(id);
        await loadSemesters();
      } catch (err: any) {
        setError(err.response?.data?.message || 'Failed to delete semester');
      }
    }
  };

  const handleToggleActive = async (semester: Semester) => {
    try {
      await semesterService.update(semester.id, { isActive: !semester.isActive });
      await loadSemesters();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to update semester');
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <MainLayout>
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
          <Typography variant="h4" component="h1">
            My Semesters
          </Typography>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => handleOpenDialog()}
          >
            Add Semester
          </Button>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError('')}>
            {error}
          </Alert>
        )}

        <Grid container spacing={3}>
          {semesters.map((semester) => {
            const startDate = new Date(semester.startDate);
            const endDate = new Date(semester.endDate);
            const today = new Date();
            const totalDays = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
            const daysElapsed = Math.ceil((today.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
            const daysRemaining = Math.ceil((endDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
            const progress = Math.min(Math.max((daysElapsed / totalDays) * 100, 0), 100);
            const isOngoing = today >= startDate && today <= endDate;
            const isPast = today > endDate;
            const isFuture = today < startDate;

            return (
              <Grid item xs={12} sm={6} md={6} key={semester.id}>
                <Card
                  sx={{
                    height: '100%',
                    display: 'flex',
                    flexDirection: 'column',
                    border: semester.isActive ? '2px solid' : '1px solid',
                    borderColor: semester.isActive ? 'primary.main' : 'divider',
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      boxShadow: 6,
                      transform: 'translateY(-4px)',
                    },
                  }}
                >
                  <CardContent sx={{ flexGrow: 1, pb: 1 }}>
                    <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                      <Box flex={1}>
                        <Typography variant="h6" component="div" fontWeight={600} gutterBottom>
                          {semester.name}
                        </Typography>
                        <Box display="flex" alignItems="center" gap={0.5} mb={1}>
                          {semester.isActive ? (
                            <ActiveIcon sx={{ fontSize: 16, color: 'success.main' }} />
                          ) : (
                            <InactiveIcon sx={{ fontSize: 16, color: 'text.disabled' }} />
                          )}
                          <Chip
                            label={semester.isActive ? 'Active' : 'Inactive'}
                            color={semester.isActive ? 'success' : 'default'}
                            size="small"
                            onClick={() => handleToggleActive(semester)}
                            sx={{ cursor: 'pointer', height: 20, fontSize: '0.7rem' }}
                          />
                          {isOngoing && (
                            <Chip
                              label="Ongoing"
                              color="info"
                              size="small"
                              sx={{ height: 20, fontSize: '0.7rem', ml: 0.5 }}
                            />
                          )}
                          {isPast && (
                            <Chip
                              label="Ended"
                              size="small"
                              sx={{ height: 20, fontSize: '0.7rem', ml: 0.5, bgcolor: 'grey.300' }}
                            />
                          )}
                          {isFuture && (
                            <Chip
                              label="Upcoming"
                              color="warning"
                              size="small"
                              sx={{ height: 20, fontSize: '0.7rem', ml: 0.5 }}
                            />
                          )}
                        </Box>
                      </Box>
                    </Box>

                    <Box sx={{ mb: 2 }}>
                      <Box display="flex" alignItems="center" gap={1} mb={1}>
                        <CalendarIcon sx={{ fontSize: 18, color: 'primary.main' }} />
                        <Typography variant="body2" color="text.secondary">
                          <strong>Start:</strong> {startDate.toLocaleDateString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            year: 'numeric'
                          })}
                        </Typography>
                      </Box>
                      <Box display="flex" alignItems="center" gap={1} mb={1}>
                        <ScheduleIcon sx={{ fontSize: 18, color: 'error.main' }} />
                        <Typography variant="body2" color="text.secondary">
                          <strong>End:</strong> {endDate.toLocaleDateString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            year: 'numeric'
                          })}
                        </Typography>
                      </Box>
                    </Box>

                    {isOngoing && (
                      <Box sx={{ mb: 1 }}>
                        <Box display="flex" justifyContent="space-between" alignItems="center" mb={0.5}>
                          <Typography variant="caption" color="text.secondary" fontWeight={500}>
                            Progress
                          </Typography>
                          <Typography variant="caption" color="primary.main" fontWeight={600}>
                            {daysRemaining > 0 ? `${daysRemaining} days left` : 'Last day'}
                          </Typography>
                        </Box>
                        <Box
                          sx={{
                            width: '100%',
                            height: 6,
                            bgcolor: 'grey.200',
                            borderRadius: 1,
                            overflow: 'hidden',
                          }}
                        >
                          <Box
                            sx={{
                              width: `${progress}%`,
                              height: '100%',
                              bgcolor: 'primary.main',
                              transition: 'width 0.3s ease',
                            }}
                          />
                        </Box>
                      </Box>
                    )}

                    {isFuture && (
                      <Box
                        sx={{
                          mt: 1,
                          p: 1,
                          bgcolor: 'warning.50',
                          borderRadius: 1,
                          border: '1px solid',
                          borderColor: 'warning.200',
                        }}
                      >
                        <Typography variant="caption" color="warning.dark" fontWeight={500}>
                          Starts in {Math.abs(daysElapsed)} days
                        </Typography>
                      </Box>
                    )}

                    {isPast && (
                      <Box
                        sx={{
                          mt: 1,
                          p: 1,
                          bgcolor: 'grey.100',
                          borderRadius: 1,
                        }}
                      >
                        <Typography variant="caption" color="text.secondary" fontWeight={500}>
                          Ended {Math.abs(daysRemaining)} days ago
                        </Typography>
                      </Box>
                    )}

                    <Typography variant="caption" color="text.disabled" sx={{ display: 'block', mt: 1.5 }}>
                      Created {new Date(semester.createdAt).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric'
                      })}
                    </Typography>
                  </CardContent>
                  <CardActions sx={{ justifyContent: 'flex-end', pt: 0, px: 2, pb: 2 }}>
                    <IconButton
                      size="small"
                      color="primary"
                      onClick={() => handleOpenDialog(semester)}
                      sx={{
                        '&:hover': {
                          bgcolor: 'primary.50',
                        }
                      }}
                    >
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => handleDelete(semester.id)}
                      sx={{
                        '&:hover': {
                          bgcolor: 'error.50',
                        }
                      }}
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </CardActions>
                </Card>
              </Grid>
            );
          })}
        </Grid>

        {semesters.length === 0 && (
          <Box textAlign="center" mt={8}>
            <Typography variant="h6" color="text.secondary" gutterBottom>
              No semesters yet
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Create your first semester to organize your subjects
            </Typography>
          </Box>
        )}

        <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
          <DialogTitle>
            {editingSemester ? 'Edit Semester' : 'Add New Semester'}
          </DialogTitle>
          <DialogContent>
            <TextField
              fullWidth
              label="Semester Name"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              margin="normal"
              required
              placeholder="e.g., Fall 2024, Spring 2025"
            />

            <TextField
              fullWidth
              label="Start Date"
              type="date"
              value={formData.startDate}
              onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
              margin="normal"
              required
              InputLabelProps={{ shrink: true }}
            />

            <TextField
              fullWidth
              label="End Date"
              type="date"
              value={formData.endDate}
              onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
              margin="normal"
              required
              InputLabelProps={{ shrink: true }}
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={handleCloseDialog}>Cancel</Button>
            <Button
              onClick={handleSubmit}
              variant="contained"
              disabled={!formData.name.trim() || !formData.startDate || !formData.endDate}
            >
              {editingSemester ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </Dialog>
      </Container>
    </MainLayout>
  );
};
