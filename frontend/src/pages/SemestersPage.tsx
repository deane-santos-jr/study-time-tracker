import { useState, useEffect } from 'react';
import {
  Container,
  Box,
  Typography,
  Button,
  Card,
  CardContent,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Alert,
  CircularProgress,
  Chip,
  Tooltip,
  LinearProgress,
  Switch,
} from '@mui/material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  CalendarMonth as CalendarIcon,
} from '@mui/icons-material';
import { semesterService } from '../services/semesterService';
import type { Semester, CreateSemesterData } from '../types';
import { MainLayout } from '../components/layout/MainLayout';

const getStatusInfo = (startDate: Date, endDate: Date, isActive: boolean) => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const start = new Date(startDate);
  start.setHours(0, 0, 0, 0);
  const end = new Date(endDate);
  end.setHours(0, 0, 0, 0);

  const totalDays = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
  const daysElapsed = Math.ceil((today.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
  const daysRemaining = Math.ceil((end.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
  const progress = Math.min(Math.max((daysElapsed / totalDays) * 100, 0), 100);

  const isOngoing = today >= start && today <= end;
  const isPast = today > end;
  const isFuture = today < start;

  let color = '#6B7280';
  let label = 'Ended';
  if (isOngoing && isActive) {
    color = '#8B5CF6';
    label = 'Ongoing';
  } else if (isOngoing && !isActive) {
    color = '#6B7280';
    label = 'Paused';
  } else if (isFuture) {
    color = '#3B82F6';
    label = 'Upcoming';
  }

  return { totalDays, daysElapsed, daysRemaining, progress, isOngoing, isPast, isFuture, color, label };
};

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
      setFormData({ name: '', startDate: '', endDate: '' });
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

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

  if (loading) {
    return (
      <MainLayout>
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
          <CircularProgress size={48} />
        </Box>
      </MainLayout>
    );
  }

  return (
    <MainLayout>
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        {/* Header */}
        <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={3}>
          <Box>
            <Typography variant="h4" fontWeight={600} gutterBottom>
              Semesters
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {semesters.length} semester{semesters.length !== 1 ? 's' : ''} total
            </Typography>
          </Box>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => handleOpenDialog()}
            sx={{ textTransform: 'none', fontWeight: 600, borderRadius: 2, px: 3 }}
          >
            Add Semester
          </Button>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError('')}>
            {error}
          </Alert>
        )}

        {semesters.length === 0 ? (
          <Box textAlign="center" py={10}>
            <CalendarIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 2 }} />
            <Typography variant="h6" color="text.secondary" gutterBottom>
              No semesters yet
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
              Create your first semester to organize your subjects
            </Typography>
            <Button variant="outlined" startIcon={<AddIcon />} onClick={() => handleOpenDialog()}>
              Create Semester
            </Button>
          </Box>
        ) : (
          <Box
            sx={{
              display: 'grid',
              gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' },
              gap: 2.5,
            }}
          >
            {semesters.map((semester) => {
              const startDate = new Date(semester.startDate);
              const endDate = new Date(semester.endDate);
              const status = getStatusInfo(startDate, endDate, semester.isActive);

              return (
                <Card
                  key={semester.id}
                  variant="outlined"
                  sx={{
                    borderLeft: `4px solid ${status.color}`,
                    transition: 'all 0.2s ease',
                    opacity: status.isPast ? 0.75 : 1,
                    '&:hover': {
                      borderColor: status.color,
                      boxShadow: `0 4px 20px ${status.color}15`,
                      transform: 'translateY(-2px)',
                      opacity: 1,
                    },
                  }}
                >
                  <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
                    {/* Row 1: Name + Status + Actions */}
                    <Box display="flex" alignItems="center" gap={1.5} mb={2}>
                      <Box flex={1} minWidth={0}>
                        <Box display="flex" alignItems="center" gap={1.5} mb={0.5}>
                          <Typography variant="subtitle1" fontWeight={600} noWrap title={semester.name}>
                            {semester.name}
                          </Typography>
                          <Chip
                            label={status.label}
                            size="small"
                            sx={{
                              bgcolor: `${status.color}15`,
                              color: status.color,
                              fontWeight: 600,
                              fontSize: '0.75rem',
                              height: 24,
                            }}
                          />
                        </Box>
                      </Box>

                      {/* Active toggle + actions */}
                      <Box display="flex" alignItems="center" gap={0.5} flexShrink={0}>
                        <Tooltip title={semester.isActive ? 'Deactivate' : 'Activate'}>
                          <Switch
                            size="small"
                            checked={semester.isActive}
                            onChange={() => handleToggleActive(semester)}
                            color="primary"
                          />
                        </Tooltip>
                        <Tooltip title="Edit">
                          <IconButton
                            size="small"
                            onClick={() => handleOpenDialog(semester)}
                            sx={{ color: 'text.secondary', '&:hover': { color: 'primary.main' } }}
                          >
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Delete">
                          <IconButton
                            size="small"
                            onClick={() => handleDelete(semester.id)}
                            sx={{ color: 'text.secondary', '&:hover': { color: 'error.main' } }}
                          >
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </Box>

                    {/* Row 2: Date range */}
                    <Box
                      display="flex"
                      alignItems="center"
                      gap={1}
                      sx={{
                        p: 1.5,
                        borderRadius: 1.5,
                        bgcolor: 'grey.50',
                        mb: status.isOngoing ? 2 : 0,
                      }}
                    >
                      <CalendarIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                      <Typography variant="body2" color="text.secondary">
                        {formatDate(semester.startDate)}
                      </Typography>
                      <Typography variant="body2" color="text.disabled">
                        —
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {formatDate(semester.endDate)}
                      </Typography>
                      <Typography variant="caption" color="text.disabled" sx={{ ml: 'auto' }}>
                        {status.totalDays} days
                      </Typography>
                    </Box>

                    {/* Row 3: Progress bar (ongoing only) */}
                    {status.isOngoing && (
                      <Box>
                        <Box display="flex" justifyContent="space-between" mb={0.5}>
                          <Typography variant="caption" color="text.secondary">
                            {Math.round(status.progress)}% complete
                          </Typography>
                          <Typography variant="caption" fontWeight={600} sx={{ color: status.color }}>
                            {status.daysRemaining > 0 ? `${status.daysRemaining} days left` : 'Last day'}
                          </Typography>
                        </Box>
                        <LinearProgress
                          variant="determinate"
                          value={status.progress}
                          sx={{
                            height: 6,
                            borderRadius: 3,
                            bgcolor: `${status.color}15`,
                            '& .MuiLinearProgress-bar': {
                              borderRadius: 3,
                              bgcolor: status.color,
                            },
                          }}
                        />
                      </Box>
                    )}

                    {/* Row 3 alt: Future/Past info */}
                    {status.isFuture && (
                      <Typography variant="caption" color="text.secondary" sx={{ mt: 1.5, display: 'block' }}>
                        Starts in {Math.abs(status.daysElapsed)} days
                      </Typography>
                    )}
                    {status.isPast && (
                      <Typography variant="caption" color="text.disabled" sx={{ mt: 1.5, display: 'block' }}>
                        Ended {Math.abs(status.daysRemaining)} days ago
                      </Typography>
                    )}
                  </CardContent>
                </Card>
              );
            })}
          </Box>
        )}

        {/* Add/Edit Dialog */}
        <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
          <DialogTitle sx={{ fontWeight: 600 }}>
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

            <LocalizationProvider dateAdapter={AdapterDateFns}>
              <Box sx={{ display: 'flex', gap: 2, mt: 2 }}>
                <DatePicker
                  label="Start Date"
                  value={formData.startDate ? new Date(formData.startDate) : null}
                  onChange={(newValue) => {
                    if (newValue) {
                      setFormData({ ...formData, startDate: newValue.toISOString().split('T')[0] });
                    } else {
                      setFormData({ ...formData, startDate: '' });
                    }
                  }}
                  format="MM/dd/yyyy"
                  slotProps={{ textField: { fullWidth: true, required: true } }}
                />
                <DatePicker
                  label="End Date"
                  value={formData.endDate ? new Date(formData.endDate) : null}
                  onChange={(newValue) => {
                    if (newValue) {
                      setFormData({ ...formData, endDate: newValue.toISOString().split('T')[0] });
                    } else {
                      setFormData({ ...formData, endDate: '' });
                    }
                  }}
                  format="MM/dd/yyyy"
                  slotProps={{ textField: { fullWidth: true, required: true } }}
                />
              </Box>
            </LocalizationProvider>
          </DialogContent>
          <DialogActions sx={{ px: 3, py: 2 }}>
            <Button onClick={handleCloseDialog} sx={{ textTransform: 'none' }}>
              Cancel
            </Button>
            <Button
              onClick={handleSubmit}
              variant="contained"
              disabled={!formData.name.trim() || !formData.startDate || !formData.endDate}
              sx={{ textTransform: 'none', fontWeight: 600, px: 3 }}
            >
              {editingSemester ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </Dialog>
      </Container>
    </MainLayout>
  );
};
