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
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  Chip,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  CheckCircle as ActiveIcon,
} from '@mui/icons-material';
import { subjectService } from '../services/subjectService';
import { semesterService } from '../services/semesterService';
import type { Subject, CreateSubjectData, Semester } from '../types';
import { MainLayout } from '../components/layout/MainLayout';

const PRESET_COLORS = [
  '#8B5CF6', '#7C3AED', '#6D28D9',
  '#EC4899', '#DB2777', '#BE185D',
  '#3B82F6', '#2563EB', '#1D4ED8',
  '#10B981', '#059669', '#047857',
  '#F59E0B', '#D97706', '#B45309',
  '#EF4444', '#DC2626', '#B91C1C',
  '#06B6D4', '#0891B2', '#0E7490',
  '#8B5CF6', '#F97316', '#14B8A6',
  '#6366F1', '#A855F7', '#D946EF',
  '#78716C', '#57534E', '#44403C',
];

const PRESET_ICONS = [
  '📚', '💻', '🔬', '📐', '🎨', '🎵', '⚽', '🌍', '🧮', '📖',
  '✏️', '📝', '🖊️', '📄', '📑', '🗂️', '📊', '📈', '💡', '🔍',
  '🧪', '⚗️', '🧬', '🔭', '🎓', '📕', '📗', '📘', '📙', '🏆',
  '⭐', '🌟', '💫', '🎯', '🎪', '🎭', '🎬', '📷', '🎸', '🎹',
  '🏃', '⚡', '🔥', '💪', '🧠', '❤️', '🌈', '☀️', '🌙', '⏰',
];

export const SubjectsPage = () => {
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [semesters, setSemesters] = useState<Semester[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [editingSubject, setEditingSubject] = useState<Subject | null>(null);
  const [formData, setFormData] = useState<CreateSubjectData>({
    name: '',
    color: PRESET_COLORS[0],
    icon: PRESET_ICONS[0],
    semesterId: '',
  });

  useEffect(() => {
    loadSubjects();
    loadSemesters();
  }, []);

  const loadSubjects = async () => {
    try {
      setLoading(true);
      const data = await subjectService.getAll();
      setSubjects(data);
      setError('');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load subjects');
    } finally {
      setLoading(false);
    }
  };

  const loadSemesters = async () => {
    try {
      const data = await semesterService.getAll();
      setSemesters(data.filter((s) => s.isActive));
    } catch (err: any) {
      console.error('Failed to load semesters:', err);
    }
  };

  const handleOpenDialog = (subject?: Subject) => {
    if (subject) {
      setEditingSubject(subject);
      setFormData({
        name: subject.name,
        color: subject.color,
        icon: subject.icon,
        semesterId: '',
      });
    } else {
      setEditingSubject(null);
      setFormData({
        name: '',
        color: PRESET_COLORS[0],
        icon: PRESET_ICONS[0],
        semesterId: semesters.length > 0 ? semesters[0].id : '',
      });
    }
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setEditingSubject(null);
  };

  const handleSubmit = async () => {
    try {
      if (editingSubject) {
        await subjectService.update(editingSubject.id, formData);
      } else {
        await subjectService.create(formData);
      }
      await loadSubjects();
      handleCloseDialog();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to save subject');
    }
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this subject?')) {
      try {
        await subjectService.delete(id);
        await loadSubjects();
      } catch (err: any) {
        setError(err.response?.data?.message || 'Failed to delete subject');
      }
    }
  };

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
              Subjects
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {subjects.length} subject{subjects.length !== 1 ? 's' : ''} total
            </Typography>
          </Box>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => handleOpenDialog()}
            sx={{ textTransform: 'none', fontWeight: 600, borderRadius: 2, px: 3 }}
          >
            Add Subject
          </Button>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError('')}>
            {error}
          </Alert>
        )}

        {/* Subject Cards */}
        {subjects.length === 0 ? (
          <Box textAlign="center" py={10}>
            <Typography variant="h6" color="text.secondary" gutterBottom>
              No subjects yet
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
              Create your first subject to start tracking your study time
            </Typography>
            <Button variant="outlined" startIcon={<AddIcon />} onClick={() => handleOpenDialog()}>
              Create Subject
            </Button>
          </Box>
        ) : (
          <Box
            sx={{
              display: 'grid',
              gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: 'repeat(3, 1fr)' },
              gap: 2.5,
            }}
          >
            {subjects.map((subject) => (
              <Card
                key={subject.id}
                variant="outlined"
                sx={{
                  borderLeft: `4px solid ${subject.color}`,
                  transition: 'all 0.2s ease',
                  '&:hover': {
                    borderColor: subject.color,
                    boxShadow: `0 4px 20px ${subject.color}20`,
                    transform: 'translateY(-2px)',
                  },
                }}
              >
                <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
                  {/* Top row: icon + name + actions */}
                  <Box display="flex" alignItems="center" gap={2}>
                    {/* Icon */}
                    <Box
                      sx={{
                        width: 48,
                        height: 48,
                        borderRadius: 2,
                        bgcolor: `${subject.color}15`,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '1.6rem',
                        flexShrink: 0,
                      }}
                    >
                      {subject.icon}
                    </Box>

                    {/* Name + status */}
                    <Box flex={1} minWidth={0}>
                      <Typography
                        variant="subtitle1"
                        fontWeight={600}
                        noWrap
                        title={subject.name}
                      >
                        {subject.name}
                      </Typography>
                      {subject.isActive && (
                        <Box display="flex" alignItems="center" gap={0.5}>
                          <ActiveIcon sx={{ fontSize: 13, color: 'success.main' }} />
                          <Typography variant="caption" color="success.main" fontWeight={500}>
                            Active
                          </Typography>
                        </Box>
                      )}
                    </Box>

                    {/* Actions */}
                    <Box sx={{ display: 'flex', gap: 0.5, flexShrink: 0 }}>
                      <Tooltip title="Edit">
                        <IconButton
                          size="small"
                          onClick={() => handleOpenDialog(subject)}
                          sx={{ color: 'text.secondary', '&:hover': { color: 'primary.main' } }}
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Delete">
                        <IconButton
                          size="small"
                          onClick={() => handleDelete(subject.id)}
                          sx={{ color: 'text.secondary', '&:hover': { color: 'error.main' } }}
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </Box>
                  </Box>

                  {/* Color indicator + date */}
                  <Box display="flex" alignItems="center" justifyContent="space-between" mt={1.5}>
                    <Box
                      sx={{
                        width: 20,
                        height: 20,
                        borderRadius: '50%',
                        bgcolor: subject.color,
                        border: '2px solid white',
                        boxShadow: `0 0 0 1px ${subject.color}40`,
                      }}
                    />
                    <Typography variant="caption" color="text.disabled">
                      {new Date(subject.createdAt).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                      })}
                    </Typography>
                  </Box>
                </CardContent>
              </Card>
            ))}
          </Box>
        )}

        {/* Add/Edit Dialog */}
        <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
          <DialogTitle sx={{ fontWeight: 600 }}>
            {editingSubject ? 'Edit Subject' : 'Add New Subject'}
          </DialogTitle>
          <DialogContent>
            {!editingSubject && (
              <FormControl fullWidth margin="normal" required>
                <InputLabel>Semester</InputLabel>
                <Select
                  value={formData.semesterId}
                  label="Semester"
                  onChange={(e) => setFormData({ ...formData, semesterId: e.target.value })}
                >
                  {semesters.map((semester) => (
                    <MenuItem key={semester.id} value={semester.id}>
                      {semester.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            )}

            <TextField
              fullWidth
              label="Subject Name"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              margin="normal"
              required
            />

            {/* Preview */}
            {formData.name && (
              <Box
                sx={{
                  mt: 2,
                  p: 2,
                  borderRadius: 2,
                  border: '1px solid',
                  borderColor: 'divider',
                  borderLeft: `4px solid ${formData.color}`,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 2,
                  bgcolor: `${formData.color}08`,
                }}
              >
                <Box
                  sx={{
                    width: 40,
                    height: 40,
                    borderRadius: 1.5,
                    bgcolor: `${formData.color}15`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '1.4rem',
                  }}
                >
                  {formData.icon}
                </Box>
                <Typography variant="subtitle2" fontWeight={600}>
                  {formData.name}
                </Typography>
              </Box>
            )}

            {/* Color Picker */}
            <Typography variant="subtitle2" sx={{ mt: 3, mb: 1 }} color="text.secondary">
              Color
            </Typography>
            <Box display="flex" gap={0.75} flexWrap="wrap">
              {PRESET_COLORS.map((color) => (
                <Box
                  key={color}
                  onClick={() => setFormData({ ...formData, color })}
                  sx={{
                    width: 32,
                    height: 32,
                    borderRadius: '50%',
                    bgcolor: color,
                    cursor: 'pointer',
                    border: formData.color === color ? '3px solid' : '2px solid transparent',
                    borderColor: formData.color === color ? 'text.primary' : 'transparent',
                    outline: formData.color === color ? `2px solid ${color}` : 'none',
                    outlineOffset: 2,
                    transition: 'all 0.15s ease',
                    '&:hover': {
                      transform: 'scale(1.15)',
                    },
                  }}
                />
              ))}
            </Box>

            {/* Icon Picker */}
            <Typography variant="subtitle2" sx={{ mt: 3, mb: 1 }} color="text.secondary">
              Icon
            </Typography>
            <Box display="flex" gap={0.5} flexWrap="wrap">
              {PRESET_ICONS.map((icon) => (
                <Box
                  key={icon}
                  onClick={() => setFormData({ ...formData, icon })}
                  sx={{
                    width: 36,
                    height: 36,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '1.3rem',
                    cursor: 'pointer',
                    borderRadius: 1.5,
                    border: '2px solid',
                    borderColor: formData.icon === icon ? 'primary.main' : 'transparent',
                    bgcolor: formData.icon === icon ? 'primary.50' : 'transparent',
                    transition: 'all 0.15s ease',
                    '&:hover': {
                      bgcolor: 'action.hover',
                    },
                  }}
                >
                  {icon}
                </Box>
              ))}
            </Box>
          </DialogContent>
          <DialogActions sx={{ px: 3, py: 2 }}>
            <Button onClick={handleCloseDialog} sx={{ textTransform: 'none' }}>
              Cancel
            </Button>
            <Button
              onClick={handleSubmit}
              variant="contained"
              disabled={!formData.name.trim() || (!editingSubject && !formData.semesterId)}
              sx={{ textTransform: 'none', fontWeight: 600, px: 3 }}
            >
              {editingSubject ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </Dialog>
      </Container>
    </MainLayout>
  );
};
