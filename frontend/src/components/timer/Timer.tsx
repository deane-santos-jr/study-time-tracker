import { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Alert,
  CircularProgress,
  Divider,
  Chip,
  Dialog,
  IconButton,
} from '@mui/material';
import {
  PlayArrow as PlayIcon,
  Pause as PauseIcon,
  Stop as StopIcon,
  Coffee as CoffeeIcon,
  EventBusy as BusyIcon,
  Fullscreen as FullscreenIcon,
  CloseFullscreen as MinimizeIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { sessionService } from '../../services/sessionService';
import { subjectService } from '../../services/subjectService';
import type { StudySession, Subject, SessionStatus as SessionStatusType } from '../../types';

interface TimerProps {
  onSessionComplete?: () => void;
}

export const Timer: React.FC<TimerProps> = ({ onSessionComplete }) => {
  const [activeSession, setActiveSession] = useState<StudySession | null>(null);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [selectedSubjectId, setSelectedSubjectId] = useState('');
  const [currentTime, setCurrentTime] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [isFullscreen, setIsFullscreen] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    let interval: NodeJS.Timeout | null = null;

    if (activeSession && activeSession.status === 'ACTIVE') {
      interval = setInterval(() => {
        const start = new Date(activeSession.startTime).getTime();
        const now = Date.now();
        const totalElapsed = Math.floor((now - start) / 1000);
        const effectiveTime = totalElapsed - (activeSession.accumulatedBreakTime || 0) - (activeSession.accumulatedPauseTime || 0);
        setCurrentTime(effectiveTime);
      }, 1000);
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [activeSession]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [sessionData, subjectsData] = await Promise.all([
        sessionService.getActive(),
        subjectService.getAll(),
      ]);
      setActiveSession(sessionData);
      setSubjects(subjectsData);

      if (sessionData) {
        const start = new Date(sessionData.startTime).getTime();
        const now = Date.now();
        const totalElapsed = Math.floor((now - start) / 1000);
        const effectiveTime = totalElapsed - (sessionData.accumulatedBreakTime || 0) - (sessionData.accumulatedPauseTime || 0);
        setCurrentTime(effectiveTime);
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  const handleStart = async () => {
    if (!selectedSubjectId) {
      setError('Please select a subject');
      return;
    }

    try {
      setLoading(true);
      const session = await sessionService.start({ subjectId: selectedSubjectId });
      setActiveSession(session);
      setError('');
      setIsFullscreen(true); 
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to start session');
    } finally {
      setLoading(false);
    }
  };

  const handleTakeBreak = async () => {
    if (!activeSession) return;

    try {
      setLoading(true);
      const session = await sessionService.pause(activeSession.id, true); 
      setActiveSession(session);
      setError('');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to take break');
    } finally {
      setLoading(false);
    }
  };

  const handlePause = async () => {
    if (!activeSession) return;

    try {
      setLoading(true);
      const session = await sessionService.pause(activeSession.id, false); 
      setActiveSession(session);
      setError('');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to pause session');
    } finally {
      setLoading(false);
    }
  };

  const handleResume = async () => {
    if (!activeSession) return;

    try {
      setLoading(true);
      const session = await sessionService.resume(activeSession.id);
      setActiveSession(session);
      setError('');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to resume session');
    } finally {
      setLoading(false);
    }
  };

  const handleStop = async () => {
    if (!activeSession) return;

    try {
      setLoading(true);
      await sessionService.stop(activeSession.id);
      setActiveSession(null);
      setCurrentTime(0);
      setSelectedSubjectId('');
      setError('');

      if (onSessionComplete) {
        onSessionComplete();
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to stop session');
    } finally {
      setLoading(false);
    }
  };

  const formatTime = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const getSubjectById = (id: string) => subjects.find((s) => s.id === id);

  const activeSubject = activeSession ? getSubjectById(activeSession.subjectId) : null;

  return (
    <>
      {/* Fullscreen Dialog */}
      <Dialog
        fullScreen
        open={isFullscreen && !!activeSession}
        onClose={() => setIsFullscreen(false)}
      >
        <Box
          sx={{
            height: '100vh',
            background: activeSession?.hasActiveBreak
              ? 'linear-gradient(135deg, #FEF3C7 0%, #FDE68A 100%)'
              : 'linear-gradient(135deg, #EDE9FE 0%, #DDD6FE 100%)',
            display: 'flex',
            flexDirection: 'column',
            p: 4,
          }}
        >
          {/* Header with minimize button */}
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
            <Box display="flex" alignItems="center" gap={2}>
              {activeSubject && (
                <Box
                  sx={{
                    width: 80,
                    height: 80,
                    borderRadius: '50%',
                    backgroundColor: activeSubject.color,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '3rem',
                    boxShadow: 4,
                  }}
                >
                  {activeSubject.icon}
                </Box>
              )}
              <Box>
                <Typography variant="h3" fontWeight="700">
                  {activeSubject?.name}
                </Typography>
                <Typography variant="body1" color="text.secondary">
                  Started at {activeSession && format(new Date(activeSession.startTime), 'hh:mm a')}
                </Typography>
              </Box>
            </Box>
            <Box display="flex" alignItems="center" gap={2}>
              <Chip
                label={
                  activeSession?.status === 'PAUSED'
                    ? activeSession?.hasActiveBreak
                      ? 'On Break'
                      : 'Paused'
                    : 'Active'
                }
                color={
                  activeSession?.status === 'PAUSED'
                    ? activeSession?.hasActiveBreak
                      ? 'warning'
                      : 'default'
                    : 'success'
                }
                sx={{ fontSize: '1.1rem', py: 3, px: 2 }}
              />
              <IconButton
                onClick={() => setIsFullscreen(false)}
                size="large"
                sx={{
                  bgcolor: 'background.paper',
                  '&:hover': { bgcolor: 'action.hover' },
                }}
              >
                <MinimizeIcon fontSize="large" />
              </IconButton>
            </Box>
          </Box>

          {/* Giant Timer Display */}
          <Box
            flex={1}
            display="flex"
            flexDirection="column"
            alignItems="center"
            justifyContent="center"
            gap={4}
          >
            <Typography
              variant="h1"
              sx={{
                fontFamily: 'monospace',
                fontSize: { xs: '6rem', sm: '8rem', md: '12rem' },
                fontWeight: 'bold',
                color: activeSession?.hasActiveBreak ? 'warning.dark' : 'primary.main',
                letterSpacing: 8,
                textShadow: '0 4px 8px rgba(0,0,0,0.1)',
              }}
            >
              {formatTime(currentTime)}
            </Typography>
            {activeSession?.hasActiveBreak && (
              <Typography variant="h4" color="warning.dark" fontWeight={600}>
                Break Time - Take a rest
              </Typography>
            )}
          </Box>

          {/* Control Buttons */}
          <Box display="flex" gap={3} justifyContent="center" flexWrap="wrap">
            {activeSession?.status === 'ACTIVE' ? (
              <>
                <Button
                  variant="contained"
                  color="warning"
                  size="large"
                  startIcon={<CoffeeIcon />}
                  onClick={handleTakeBreak}
                  disabled={loading}
                  sx={{ minWidth: 180, py: 2.5, fontSize: '1.2rem' }}
                >
                  Take Break
                </Button>
                <Button
                  variant="outlined"
                  color="secondary"
                  size="large"
                  startIcon={<BusyIcon />}
                  onClick={handlePause}
                  disabled={loading}
                  sx={{ minWidth: 180, py: 2.5, fontSize: '1.2rem' }}
                >
                  Pause
                </Button>
              </>
            ) : (
              <Button
                variant="contained"
                color="success"
                size="large"
                startIcon={<PlayIcon />}
                onClick={handleResume}
                disabled={loading}
                sx={{ minWidth: 180, py: 2.5, fontSize: '1.2rem' }}
              >
                Resume Study
              </Button>
            )}
            <Button
              variant="contained"
              color="error"
              size="large"
              startIcon={<StopIcon />}
              onClick={handleStop}
              disabled={loading}
              sx={{ minWidth: 180, py: 2.5, fontSize: '1.2rem' }}
            >
              End Session
            </Button>
          </Box>
        </Box>
      </Dialog>

      {/* Regular Timer Card */}
      <Card elevation={3} sx={{ height: '100%' }}>
        <CardContent sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
            <Typography variant="h5" fontWeight="600">
              Study Timer
            </Typography>
            <Box display="flex" alignItems="center" gap={1}>
              {activeSession && (
                <>
                  <Chip
                    label={
                      activeSession.status === 'PAUSED'
                        ? activeSession.hasActiveBreak
                          ? 'On Break'
                          : 'Paused'
                        : 'Active'
                    }
                    color={
                      activeSession.status === 'PAUSED'
                        ? activeSession.hasActiveBreak
                          ? 'warning'
                          : 'default'
                        : 'success'
                    }
                    size="small"
                  />
                  <IconButton
                    size="small"
                    onClick={() => setIsFullscreen(true)}
                    sx={{ ml: 1 }}
                  >
                    <FullscreenIcon />
                  </IconButton>
                </>
              )}
            </Box>
          </Box>

        <Divider sx={{ mb: 3 }} />

        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError('')}>
            {error}
          </Alert>
        )}

        {activeSession ? (
          <Box flex={1} display="flex" flexDirection="column">
            {activeSubject && (
              <Box display="flex" alignItems="center" gap={2} mb={3}>
                <Box
                  sx={{
                    width: 60,
                    height: 60,
                    borderRadius: '50%',
                    backgroundColor: activeSubject.color,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '2rem',
                    boxShadow: 2,
                  }}
                >
                  {activeSubject.icon}
                </Box>
                <Box>
                  <Typography variant="h6" fontWeight="600">
                    {activeSubject.name}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Started at {format(new Date(activeSession.startTime), 'hh:mm a')}
                  </Typography>
                </Box>
              </Box>
            )}

            <Box
              flex={1}
              display="flex"
              alignItems="center"
              justifyContent="center"
              sx={{
                backgroundColor: activeSession.hasActiveBreak ? '#FEF3C7' : '#EDE9FE',
                borderRadius: 2,
                py: 4,
                my: 3,
              }}
            >
              <Box textAlign="center">
                <Typography
                  variant="h1"
                  sx={{
                    fontFamily: 'monospace',
                    fontSize: { xs: '3rem', md: '4rem' },
                    fontWeight: 'bold',
                    color: activeSession.hasActiveBreak ? 'warning.dark' : 'primary.dark',
                    letterSpacing: 2,
                  }}
                >
                  {formatTime(currentTime)}
                </Typography>
                {activeSession.hasActiveBreak && (
                  <Typography variant="body1" color="warning.dark" sx={{ mt: 1, fontWeight: 500 }}>
                    Break Time
                  </Typography>
                )}
                {activeSession.status === 'PAUSED' && !activeSession.hasActiveBreak && (
                  <Typography variant="body1" color="text.secondary" sx={{ mt: 1, fontWeight: 500 }}>
                    Paused
                  </Typography>
                )}
              </Box>
            </Box>

            <Box display="flex" gap={2} justifyContent="center" flexWrap="wrap">
              {activeSession.status === 'ACTIVE' ? (
                <>
                  <Button
                    variant="contained"
                    color="warning"
                    size="large"
                    startIcon={<CoffeeIcon />}
                    onClick={handleTakeBreak}
                    disabled={loading}
                    sx={{ minWidth: 140, py: 1.5 }}
                  >
                    Take Break
                  </Button>
                  <Button
                    variant="outlined"
                    color="secondary"
                    size="large"
                    startIcon={<BusyIcon />}
                    onClick={handlePause}
                    disabled={loading}
                    sx={{ minWidth: 140, py: 1.5 }}
                  >
                    Pause
                  </Button>
                </>
              ) : (
                <Button
                  variant="contained"
                  color="success"
                  size="large"
                  startIcon={<PlayIcon />}
                  onClick={handleResume}
                  disabled={loading}
                  sx={{ minWidth: 140, py: 1.5 }}
                >
                  Resume
                </Button>
              )}
              <Button
                variant="contained"
                color="error"
                size="large"
                startIcon={<StopIcon />}
                onClick={handleStop}
                disabled={loading}
                sx={{ minWidth: 140, py: 1.5 }}
              >
                End Session
              </Button>
            </Box>
          </Box>
        ) : (
          <Box>
            <Typography variant="body2" color="text.secondary" mb={3}>
              Select a subject and start tracking your study time
            </Typography>

            <FormControl fullWidth sx={{ mb: 3 }}>
              <InputLabel>Select Subject</InputLabel>
              <Select
                value={selectedSubjectId}
                onChange={(e) => setSelectedSubjectId(e.target.value)}
                label="Select Subject"
              >
                {subjects.map((subject) => (
                  <MenuItem key={subject.id} value={subject.id}>
                    <Box display="flex" alignItems="center" gap={1.5}>
                      <Box
                        sx={{
                          width: 32,
                          height: 32,
                          borderRadius: '50%',
                          backgroundColor: subject.color,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontSize: '1.2rem',
                        }}
                      >
                        {subject.icon}
                      </Box>
                      <Typography>{subject.name}</Typography>
                    </Box>
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <Button
              variant="contained"
              size="large"
              fullWidth
              startIcon={<PlayIcon />}
              onClick={handleStart}
              disabled={!selectedSubjectId || loading}
              sx={{ py: 1.5, fontSize: '1.1rem' }}
            >
              {loading ? <CircularProgress size={24} /> : 'Start Study Session'}
            </Button>

            {subjects.length === 0 && (
              <Alert severity="info" sx={{ mt: 3 }}>
                Create a subject first to start tracking your study time
              </Alert>
            )}
          </Box>
        )}
      </CardContent>
    </Card>
    </>
  );
};
