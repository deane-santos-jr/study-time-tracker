import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Alert,
  Box,
  TextField,
  Typography,
  Rating,
  CircularProgress,
} from '@mui/material';
import { format } from 'date-fns';
import { noteService } from '../../services/noteService';
import type { StudySession, Note } from '../../types';

interface NoteSessionDialogProps {
  session: StudySession | null;
  subjectName: string;
  onClose: () => void;
}

export const NoteSessionDialog: React.FC<NoteSessionDialogProps> = ({
  session,
  subjectName,
  onClose,
}) => {
  const [note, setNote] = useState<Note | null>(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const [content, setContent] = useState('');
  const [topics, setTopics] = useState('');
  const [difficulty, setDifficulty] = useState<number | null>(null);
  const [focus, setFocus] = useState<number | null>(null);

  useEffect(() => {
    if (!session) return;

    let cancelled = false;
    setLoading(true);
    noteService
      .getBySession(session.id)
      .then((data) => {
        if (cancelled) return;
        setNote(data);
      })
      .catch(() => {
        if (!cancelled) setNote(null);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [session]);

  useEffect(() => {
    if (note) {
      setContent(note.content || '');
      setTopics(note.topics || '');
      setDifficulty(note.difficultyLevel || null);
      setFocus(note.focusLevel || null);
    } else {
      setContent('');
      setTopics('');
      setDifficulty(null);
      setFocus(null);
    }
    setError('');
  }, [note]);

  const handleSave = async () => {
    if (!session) return;
    if (!content.trim()) {
      setError('Note content is required');
      return;
    }

    try {
      setSaving(true);
      setError('');
      const payload = {
        content,
        topics: topics || undefined,
        difficultyLevel: difficulty || undefined,
        focusLevel: focus || undefined,
      };

      if (note) {
        await noteService.update(note.id, payload);
      } else {
        await noteService.create({ sessionId: session.id, ...payload });
      }
      onClose();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to save note. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!note) return;
    try {
      setSaving(true);
      await noteService.delete(note.id);
      onClose();
    } catch {
      setError('Failed to delete note. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={!!session} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>{note ? 'Edit Session Note' : 'Add Session Note'}</DialogTitle>
      <DialogContent>
        {loading ? (
          <Box display="flex" justifyContent="center" py={4}>
            <CircularProgress />
          </Box>
        ) : (
          <>
            {error && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            )}

            {session && (
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  Session: {subjectName} &bull;{' '}
                  {format(new Date(session.startTime), 'MMM dd, yyyy hh:mm a')}
                </Typography>
              </Box>
            )}

            <TextField
              fullWidth
              multiline
              rows={4}
              label="Note Content *"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="What did you study? Key takeaways, reflections, or important points..."
              sx={{ mb: 2 }}
            />

            <TextField
              fullWidth
              label="Topics Covered"
              value={topics}
              onChange={(e) => setTopics(e.target.value)}
              placeholder="e.g., Linear Algebra, Calculus, React Hooks"
              helperText="Separate multiple topics with commas"
              sx={{ mb: 2 }}
            />

            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <Box sx={{ flex: '1 1 200px' }}>
                <Typography component="legend" variant="body2" gutterBottom>
                  Difficulty Level
                </Typography>
                <Rating
                  name="difficulty-rating"
                  value={difficulty}
                  onChange={(_, v) => setDifficulty(v)}
                  max={5}
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  How challenging was this session?
                </Typography>
              </Box>
              <Box sx={{ flex: '1 1 200px' }}>
                <Typography component="legend" variant="body2" gutterBottom>
                  Focus Level
                </Typography>
                <Rating
                  name="focus-rating"
                  value={focus}
                  onChange={(_, v) => setFocus(v)}
                  max={5}
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  How focused were you?
                </Typography>
              </Box>
            </Box>
          </>
        )}
      </DialogContent>
      <DialogActions>
        {note && (
          <Button onClick={handleDelete} color="error" disabled={saving}>
            Delete Note
          </Button>
        )}
        <Box sx={{ flex: 1 }} />
        <Button onClick={onClose} disabled={saving}>
          Cancel
        </Button>
        <Button onClick={handleSave} variant="contained" disabled={saving || loading}>
          {saving ? 'Saving...' : note ? 'Update' : 'Save'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
