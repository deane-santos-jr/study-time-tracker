import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Alert,
  Typography,
} from '@mui/material';
import { sessionService } from '../../services/sessionService';

interface DeleteSessionDialogProps {
  sessionId: string | null;
  onClose: () => void;
  onDeleted: () => void;
}

export const DeleteSessionDialog: React.FC<DeleteSessionDialogProps> = ({
  sessionId,
  onClose,
  onDeleted,
}) => {
  const [error, setError] = useState('');

  const handleConfirm = async () => {
    if (!sessionId) return;
    try {
      await sessionService.delete(sessionId);
      onDeleted();
    } catch {
      setError('Failed to delete session. Please try again.');
    }
  };

  const handleClose = () => {
    setError('');
    onClose();
  };

  return (
    <Dialog open={!!sessionId} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>Delete Session</DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}
        <Typography>
          Are you sure you want to delete this session? This action cannot be undone.
        </Typography>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} color="inherit">
          Cancel
        </Button>
        <Button onClick={handleConfirm} color="error" variant="contained" autoFocus>
          Delete
        </Button>
      </DialogActions>
    </Dialog>
  );
};
