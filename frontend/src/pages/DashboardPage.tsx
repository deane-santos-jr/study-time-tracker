import { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Grid,
  Card,
  CardContent,
  Box,
  Button,
  CircularProgress,
} from '@mui/material';
import {
  TodayOutlined as TodayIcon,
  TrendingUpOutlined as TrendingIcon,
  StarOutlined as StarIcon,
  ArrowForwardOutlined as ArrowIcon,
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
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    }
    return `${minutes}m`;
  };

  const getMostStudiedSubject = () => {
    if (!weeklyStats || weeklyStats.subjectStats.length === 0) return null;
    const topSubject = weeklyStats.subjectStats.reduce((prev, current) =>
      prev.totalTime > current.totalTime ? prev : current
    );
    const subject = subjects.find((s) => s.id === topSubject.subjectId);
    return subject ? `${subject.icon} ${topSubject.subjectName}` : topSubject.subjectName;
  };

  const weeklyAverage = weeklyStats ? Math.floor(weeklyStats.totalStudyTime / 7) : 0;

  return (
    <MainLayout>
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h4" gutterBottom fontWeight={600} mb={3}>
          Dashboard
        </Typography>

        {/* Summary Statistics */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={4}>
            <Card
              elevation={2}
              sx={{
                background: 'linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%)',
                color: 'white',
                transition: 'all 0.3s ease',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: '0 12px 24px rgba(139, 92, 246, 0.3)',
                },
              }}
            >
              <CardContent>
                <Box display="flex" alignItems="center" gap={2} mb={1}>
                  <TodayIcon sx={{ fontSize: 40, opacity: 0.9 }} />
                  <Box>
                    <Typography variant="caption" sx={{ opacity: 0.9 }}>
                      Today's Study
                    </Typography>
                    <Typography variant="h4" fontWeight="bold">
                      {loading ? (
                        <CircularProgress size={24} sx={{ color: 'white' }} />
                      ) : (
                        formatDuration(todayStats?.totalStudyTime || 0)
                      )}
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={4}>
            <Card
              elevation={2}
              sx={{
                background: 'linear-gradient(135deg, #A78BFA 0%, #8B5CF6 100%)',
                color: 'white',
                transition: 'all 0.3s ease',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: '0 12px 24px rgba(167, 139, 250, 0.3)',
                },
              }}
            >
              <CardContent>
                <Box display="flex" alignItems="center" gap={2} mb={1}>
                  <TrendingIcon sx={{ fontSize: 40, opacity: 0.9 }} />
                  <Box>
                    <Typography variant="caption" sx={{ opacity: 0.9 }}>
                      Weekly Average
                    </Typography>
                    <Typography variant="h4" fontWeight="bold">
                      {loading ? (
                        <CircularProgress size={24} sx={{ color: 'white' }} />
                      ) : (
                        `${formatDuration(weeklyAverage)} / day`
                      )}
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={4}>
            <Card
              elevation={2}
              sx={{
                background: 'linear-gradient(135deg, #EC4899 0%, #DB2777 100%)',
                color: 'white',
                transition: 'all 0.3s ease',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: '0 12px 24px rgba(236, 72, 153, 0.3)',
                },
              }}
            >
              <CardContent>
                <Box display="flex" alignItems="center" gap={2} mb={1}>
                  <StarIcon sx={{ fontSize: 40, opacity: 0.9 }} />
                  <Box>
                    <Typography variant="caption" sx={{ opacity: 0.9 }}>
                      Most Studied
                    </Typography>
                    <Typography variant="h6" fontWeight="bold" noWrap>
                      {loading ? (
                        <CircularProgress size={24} sx={{ color: 'white' }} />
                      ) : (
                        getMostStudiedSubject() || 'No data yet'
                      )}
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Main Content: Timer and Recent Sessions */}
        <Grid container spacing={3}>
          <Grid item xs={12} md={5}>
            <Timer onSessionComplete={loadDashboardData} />
          </Grid>

          <Grid item xs={12} md={7}>
            <Card elevation={3} sx={{ height: '100%' }}>
              <CardContent sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
                <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                  <Typography variant="h5" fontWeight="600">
                    Recent Sessions
                  </Typography>
                  <Button
                    size="small"
                    endIcon={<ArrowIcon />}
                    onClick={() => navigate('/history')}
                    sx={{ textTransform: 'none' }}
                  >
                    View All
                  </Button>
                </Box>

{recentSessions.length === 0 ? (
                  <Box
                    flex={1}
                    display="flex"
                    flexDirection="column"
                    alignItems="center"
                    justifyContent="center"
                    sx={{ py: 8 }}
                  >
                    <Typography variant="h6" color="text.secondary" gutterBottom>
                      No sessions yet
                    </Typography>
                    <Typography variant="body2" color="text.secondary" textAlign="center">
                      Start tracking your study time!
                    </Typography>
                  </Box>
                ) : (
                  <Box sx={{ overflowY: 'auto' }}>
                    {recentSessions.map((session) => {
                      const subject = getSubjectById(session.subjectId);
                      return (
                        <Box
                          key={session.id}
                          sx={{
                            py: 2,
                            px: 1.5,
                            borderRadius: 1,
                            transition: 'background-color 0.2s ease',
                            '&:hover': {
                              bgcolor: 'action.hover',
                              cursor: 'pointer',
                            },
                            borderBottom: '1px solid',
                            borderColor: 'divider',
                            '&:last-child': { borderBottom: 'none' },
                          }}
                        >
                          <Box display="flex" alignItems="center" gap={2}>
                            {subject && (
                              <Box
                                sx={{
                                  width: 44,
                                  height: 44,
                                  borderRadius: '50%',
                                  backgroundColor: `${subject.color}20`,
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  fontSize: '1.4rem',
                                  flexShrink: 0,
                                }}
                              >
                                {subject.icon}
                              </Box>
                            )}
                            <Box flex={1} minWidth={0}>
                              <Box display="flex" justifyContent="space-between" alignItems="center" gap={2} mb={0.5}>
                                <Typography variant="body1" fontWeight="500" noWrap sx={{ flex: 1 }}>
                                  {subject?.name || 'Unknown Subject'}
                                </Typography>
                                <Typography
                                  variant="body1"
                                  fontWeight="bold"
                                  color="primary.main"
                                  sx={{ flexShrink: 0 }}
                                >
                                  {session.effectiveStudyTime
                                    ? formatDuration(session.effectiveStudyTime)
                                    : 'In progress'}
                                </Typography>
                              </Box>
                              <Typography variant="caption" color="text.secondary">
                                {format(new Date(session.startTime), 'MMM dd, yyyy')} at{' '}
                                {format(new Date(session.startTime), 'hh:mm a')}
                              </Typography>
                            </Box>
                          </Box>
                        </Box>
                      );
                    })}
                  </Box>
                )}
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Container>
    </MainLayout>
  );
};
