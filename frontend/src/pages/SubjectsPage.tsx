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
  MenuItem,
  Select,
  FormControl,
  InputLabel,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  CalendarMonth as CalendarIcon,
  CheckCircle as ActiveIcon,
} from '@mui/icons-material';
import { subjectService } from '../services/subjectService';
import { semesterService } from '../services/semesterService';
import type { Subject, CreateSubjectData, Semester } from '../types';

const PRESET_COLORS = [
  '#FF5733', '#33FF57', '#3357FF', '#FF33F5', '#F5FF33',
  '#33FFF5', '#FF8C33', '#8C33FF', '#33FF8C', '#FF3333',
  '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3',
  '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
  '#FFEB3B', '#FFC107', '#FF9800', '#FF5722', '#795548',
  '#607D8B', '#F06292', '#BA68C8', '#9575CD', '#7986CB',
];

const PRESET_ICONS = [
  '📚', '💻', '🔬', '📐', '🎨', '🎵', '⚽', '🌍', '🧮', '📖',
  '✏️', '📝', '🖊️', '📄', '📑', '🗂️', '📊', '📈', '💡', '🔍',
  '🧪', '⚗️', '🧬', '🔭', '🎓', '📕', '📗', '📘', '📙', '🏆',
  '⭐', '🌟', '💫', '🎯', '🎪', '🎭', '🎬', '📷', '🎸', '🎹',
  '🏃', '⚡', '🔥', '💪', '🧠', '❤️', '🌈', '☀️', '🌙', '⏰',
];

import { MainLayout } from '../components/layout/MainLayout';

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
      setSemesters(data.filter(s => s.isActive));
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
          My Subjects
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          Add Subject
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError('')}>
          {error}
        </Alert>
      )}

      <Grid container spacing={3}>
        {subjects.map((subject) => (
          <Grid item xs={12} sm={6} md={4} key={subject.id}>
            <Card
              sx={{
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
                position: 'relative',
                overflow: 'hidden',
                transition: 'all 0.3s ease',
                border: '1px solid',
                borderColor: 'divider',
                '&:hover': {
                  boxShadow: 6,
                  transform: 'translateY(-4px)',
                  borderColor: subject.color,
                },
              }}
            >
              {/* Color accent bar */}
              <Box
                sx={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 4,
                  bgcolor: subject.color,
                  borderTopLeftRadius: 16,
                  borderTopRightRadius: 16,
                }}
              />

              <CardContent sx={{ flexGrow: 1, pt: 3 }}>
                <Box display="flex" alignItems="flex-start" gap={2} mb={2}>
                  <Box
                    sx={{
                      width: 56,
                      height: 56,
                      borderRadius: 2,
                      background: `linear-gradient(135deg, ${subject.color}15 0%, ${subject.color}30 100%)`,
                      border: '2px solid',
                      borderColor: subject.color,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '2rem',
                      flexShrink: 0,
                      transition: 'transform 0.3s ease',
                      '&:hover': {
                        transform: 'scale(1.1) rotate(5deg)',
                      },
                    }}
                  >
                    {subject.icon}
                  </Box>
                  <Box flex={1}>
                    <Typography
                      variant="h6"
                      component="div"
                      fontWeight={600}
                      gutterBottom
                      sx={{
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        display: '-webkit-box',
                        WebkitLineClamp: 2,
                        WebkitBoxOrient: 'vertical',
                        lineHeight: 1.3,
                      }}
                    >
                      {subject.name}
                    </Typography>
                    {subject.isActive && (
                      <Box display="flex" alignItems="center" gap={0.5}>
                        <ActiveIcon sx={{ fontSize: 14, color: 'success.main' }} />
                        <Typography variant="caption" color="success.main" fontWeight={600}>
                          Active
                        </Typography>
                      </Box>
                    )}
                  </Box>
                </Box>

                {/* Created date with icon */}
                <Box display="flex" alignItems="center" gap={0.5} mt={2}>
                  <CalendarIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
                  <Typography variant="caption" color="text.disabled">
                    Created {new Date(subject.createdAt).toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric'
                    })}
                  </Typography>
                </Box>
              </CardContent>

              <CardActions
                sx={{
                  justifyContent: 'flex-end',
                  px: 2,
                  py: 1.5,
                  bgcolor: 'grey.50',
                  borderTop: '1px solid',
                  borderColor: 'divider',
                }}
              >
                <IconButton
                  size="small"
                  color="primary"
                  onClick={() => handleOpenDialog(subject)}
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
                  onClick={() => handleDelete(subject.id)}
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
        ))}
      </Grid>

      {subjects.length === 0 && (
        <Box textAlign="center" mt={8}>
          <Typography variant="h6" color="text.secondary" gutterBottom>
            No subjects yet
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Create your first subject to start tracking your study time
          </Typography>
        </Box>
      )}

      {/* Add/Edit Dialog */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
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

          <Typography variant="subtitle2" sx={{ mt: 2, mb: 1 }}>
            Select Color
          </Typography>
          <Box display="flex" gap={1} flexWrap="wrap">
            {PRESET_COLORS.map((color) => (
              <Box
                key={color}
                onClick={() => setFormData({ ...formData, color })}
                sx={{
                  width: 40,
                  height: 40,
                  borderRadius: '50%',
                  backgroundColor: color,
                  cursor: 'pointer',
                  border: formData.color === color ? '3px solid #000' : '2px solid #ddd',
                  '&:hover': {
                    transform: 'scale(1.1)',
                  },
                }}
              />
            ))}
          </Box>

          <Typography variant="subtitle2" sx={{ mt: 2, mb: 1 }}>
            Select Icon
          </Typography>
          <Box display="flex" gap={1} flexWrap="wrap">
            {PRESET_ICONS.map((icon) => (
              <Box
                key={icon}
                onClick={() => setFormData({ ...formData, icon })}
                sx={{
                  width: 40,
                  height: 40,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '1.5rem',
                  cursor: 'pointer',
                  border: formData.icon === icon ? '2px solid #1976d2' : '2px solid #ddd',
                  borderRadius: 1,
                  '&:hover': {
                    backgroundColor: '#f5f5f5',
                  },
                }}
              >
                {icon}
              </Box>
            ))}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button
            onClick={handleSubmit}
            variant="contained"
            disabled={!formData.name.trim() || (!editingSubject && !formData.semesterId)}
          >
            {editingSubject ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
      </Container>
    </MainLayout>
  );
};
