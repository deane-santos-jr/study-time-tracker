import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Alert,
  Box,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
} from '@mui/material';
import { sessionService } from '../../services/sessionService';
import type { StudySession, Subject } from '../../types';

interface EditSessionDialogProps {
  session: StudySession | null;
  subjects: Subject[];
  onClose: () => void;
  onSaved: () => void;
}

const toLocalDateTimeString = (date: Date): string => {
  const offset = date.getTimezoneOffset();
  const local = new Date(date.getTime() - offset * 60000);
  return local.toISOString().slice(0, 16);
};

export const EditSessionDialog: React.FC<EditSessionDialogProps> = ({
  session,
  subjects,
  onClose,
  onSaved,
}) => {
  const [subjectId, setSubjectId] = useState('');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (session) {
      setSubjectId(session.subjectId);
      setStartTime(toLocalDateTimeString(new Date(session.startTime)));
      setEndTime(session.endTime ? toLocalDateTimeString(new Date(session.endTime)) : '');
      setError('');
    }
  }, [session]);

  const handleSave = async () => {
    if (!session) return;

    if (!subjectId) {
      setError('Subject is required');
      return;
    }
    if (!startTime) {
      setError('Start time is required');
      return;
    }
    if (endTime && new Date(startTime) >= new Date(endTime)) {
      setError('Start time must be before end time');
      return;
    }

    try {
      setSaving(true);
      setError('');
      await sessionService.update(session.id, {
        subjectId,
        startTime: new Date(startTime).toISOString(),
        endTime: endTime ? new Date(endTime).toISOString() : undefined,
      });
      onSaved();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to update session. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={!!session} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Edit Session</DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2, mt: 1 }}>
            {error}
          </Alert>
        )}
        {session && (
          <Box sx={{ mt: 1 }}>
            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Subject *</InputLabel>
              <Select
                value={subjectId}
                label="Subject *"
                onChange={(e) => setSubjectId(e.target.value)}
              >
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

            <TextField
              fullWidth
              label="Start Time *"
              type="datetime-local"
              value={startTime}
              onChange={(e) => setStartTime(e.target.value)}
              InputLabelProps={{ shrink: true }}
              sx={{ mb: 2 }}
            />

            <TextField
              fullWidth
              label="End Time"
              type="datetime-local"
              value={endTime}
              onChange={(e) => setEndTime(e.target.value)}
              InputLabelProps={{ shrink: true }}
              helperText="Leave empty if session is still active or paused"
            />
          </Box>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Cancel
        </Button>
        <Button onClick={handleSave} variant="contained" disabled={saving}>
          {saving ? 'Saving...' : 'Save Changes'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
