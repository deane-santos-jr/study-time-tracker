import { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Card,
  CardContent,
  Box,
  Button,
  CircularProgress,
  Divider,
} from '@mui/material';
import {
  ArrowForwardOutlined as ArrowIcon,
  AccessTimeOutlined as ClockIcon,
  CheckCircleOutline as CompleteIcon,
} from '@mui/icons-material';
import { format, startOfToday, subDays } from 'date-fns';
import { useNavigate } from 'react-router-dom';
import { Timer } from '../components/timer/Timer';
import { sessionService } from '../services/sessionService';
import { subjectService } from '../services/subjectService';
import { analyticsService } from '../services/analyticsService';
import type { StudySession, Subject } from '../types';
import type { AnalyticsData } from '../services/analyticsService';
import { MainLayout } from '../components/layout/MainLayout';

export const DashboardPage = () => {
  const navigate = useNavigate();
  const [recentSessions, setRecentSessions] = useState<StudySession[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [todayStats, setTodayStats] = useState<AnalyticsData | null>(null);
  const [weeklyStats, setWeeklyStats] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const today = startOfToday();
      const weekAgo = subDays(today, 7);

      const [sessions, subjectsData, todayData, weekData] = await Promise.all([
        sessionService.getAll(),
        subjectService.getAll(),
        analyticsService.getAnalytics({
          startDate: today.toISOString(),
          endDate: new Date().toISOString(),
        }),
        analyticsService.getAnalytics({
          startDate: weekAgo.toISOString(),
          endDate: new Date().toISOString(),
        }),
      ]);

      setRecentSessions(sessions.slice(0, 5));
      setSubjects(subjectsData);
      setTodayStats(todayData);
      setWeeklyStats(weekData);
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getSubjectById = (id: string) => subjects.find((s) => s.id === id);

  const formatDuration = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  };

  const getMostStudiedSubject = () => {
    if (!weeklyStats || weeklyStats.subjectStats.length === 0) return null;
    const topSubject = weeklyStats.subjectStats.reduce((prev, current) =>
      prev.totalTime > current.totalTime ? prev : current
    );
    const subject = subjects.find((s) => s.id === topSubject.subjectId);
    return { name: topSubject.subjectName, icon: subject?.icon };
  };

  const weeklyAverage = weeklyStats ? Math.floor(weeklyStats.totalEffectiveTime / 7) : 0;
  const topSubject = getMostStudiedSubject();

  const stats = [
    { label: 'Today', value: formatDuration(todayStats?.totalEffectiveTime || 0), color: '#8B5CF6' },
    { label: 'Sessions today', value: String(todayStats?.totalSessions || 0), color: '#EC4899' },
    { label: 'Daily avg (7d)', value: formatDuration(weeklyAverage), color: '#3B82F6' },
  ];

  return (
    <MainLayout>
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        {/* Header */}
        <Box sx={{ mb: 3 }}>
          <Typography variant="h4" fontWeight={600} gutterBottom>
            Dashboard
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {format(new Date(), 'EEEE, MMMM d, yyyy')}
          </Typography>
        </Box>

        {/* Stats */}
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', sm: 'repeat(3, 1fr)', md: topSubject ? 'repeat(4, 1fr)' : 'repeat(3, 1fr)' },
            gap: 2.5,
            mb: 4,
          }}
        >
          {stats.map((stat) => (
            <Card
              key={stat.label}
              variant="outlined"
              sx={{ borderTop: `3px solid ${stat.color}` }}
            >
              <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
                <Typography variant="caption" color="text.secondary" textTransform="uppercase" letterSpacing={0.5}>
                  {stat.label}
                </Typography>
                <Typography variant="h4" fontWeight={700} sx={{ mt: 0.5, color: stat.color }}>
                  {loading ? <CircularProgress size={24} /> : stat.value}
                </Typography>
              </CardContent>
            </Card>
          ))}

          {/* Top subject card - slightly different treatment */}
          {topSubject && (
            <Card
              variant="outlined"
              sx={{ borderTop: '3px solid #F59E0B' }}
            >
              <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
                <Typography variant="caption" color="text.secondary" textTransform="uppercase" letterSpacing={0.5}>
                  Top subject (7d)
                </Typography>
                <Box display="flex" alignItems="center" gap={1} sx={{ mt: 0.5 }}>
                  <Typography fontSize="1.5rem" lineHeight={1}>{topSubject.icon}</Typography>
                  <Typography variant="h5" fontWeight={700} noWrap sx={{ color: '#F59E0B' }}>
                    {loading ? <CircularProgress size={24} /> : topSubject.name}
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          )}
        </Box>

        {/* Timer + Recent Sessions */}
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', md: '5fr 7fr' },
            gap: 3,
            alignItems: 'start',
          }}
        >
          <Timer onSessionComplete={loadDashboardData} />

          {/* Recent Sessions */}
          <Card variant="outlined">
            <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
              <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ px: 3, py: 2 }}>
                <Typography variant="subtitle1" fontWeight={600}>
                  Recent Sessions
                </Typography>
                <Button
                  size="small"
                  endIcon={<ArrowIcon />}
                  onClick={() => navigate('/history')}
                  sx={{ textTransform: 'none', fontWeight: 500 }}
                >
                  History
                </Button>
              </Box>

              <Divider />

              {recentSessions.length === 0 ? (
                <Box sx={{ py: 8, textAlign: 'center' }}>
                  <ClockIcon sx={{ fontSize: 36, color: 'text.disabled', mb: 1 }} />
                  <Typography variant="body2" color="text.secondary">
                    No sessions yet. Start the timer to begin.
                  </Typography>
                </Box>
              ) : (
                recentSessions.map((session, idx) => {
                  const subject = getSubjectById(session.subjectId);
                  const isActive = !session.effectiveStudyTime;
                  return (
                    <Box key={session.id}>
                      <Box
                        onClick={() => navigate('/history')}
                        sx={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: 2,
                          px: 3,
                          py: 1.5,
                          cursor: 'pointer',
                          transition: 'background 0.15s',
                          '&:hover': { bgcolor: 'action.hover' },
                        }}
                      >
                        {/* Subject icon */}
                        <Box
                          sx={{
                            width: 38,
                            height: 38,
                            borderRadius: 1.5,
                            bgcolor: `${subject?.color || '#8B5CF6'}15`,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '1.15rem',
                            flexShrink: 0,
                          }}
                        >
                          {subject?.icon || '📚'}
                        </Box>

                        {/* Subject + timestamp */}
                        <Box flex={1} minWidth={0}>
                          <Typography variant="body2" fontWeight={500} noWrap>
                            {subject?.name || 'Unknown'}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {format(new Date(session.startTime), 'MMM d, h:mm a')}
                          </Typography>
                        </Box>

                        {/* Duration */}
                        <Box sx={{ flexShrink: 0, textAlign: 'right' }}>
                          {isActive ? (
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                              <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: 'success.main', animation: 'pulse 1.5s infinite',
                                '@keyframes pulse': {
                                  '0%': { opacity: 1 },
                                  '50%': { opacity: 0.4 },
                                  '100%': { opacity: 1 },
                                },
                              }} />
                              <Typography variant="body2" fontWeight={600} color="success.main">
                                Active
                              </Typography>
                            </Box>
                          ) : (
                            <Box display="flex" alignItems="center" gap={0.5}>
                              <CompleteIcon sx={{ fontSize: 14, color: subject?.color || 'text.disabled' }} />
                              <Typography variant="body2" fontWeight={600} sx={{ color: subject?.color || 'text.primary' }}>
                                {formatDuration(session.effectiveStudyTime)}
                              </Typography>
                            </Box>
                          )}
                        </Box>
                      </Box>
                      {idx < recentSessions.length - 1 && <Divider />}
                    </Box>
                  );
                })
              )}
            </CardContent>
          </Card>
        </Box>
      </Container>
    </MainLayout>
  );
};
