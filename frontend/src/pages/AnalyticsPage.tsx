import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Grid,
  Card,
  CardContent,
  Box,
  Paper,
  CircularProgress,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  IconButton,
  Tooltip as MuiTooltip,
} from '@mui/material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import {
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { Refresh, TrendingUp, Assessment, FilterList } from '@mui/icons-material';
import { MainLayout } from '../components/layout/MainLayout';
import { analyticsService } from '../services/analyticsService';
import { subjectService } from '../services/subjectService';
import type { Subject } from '../types';

const COLORS = ['#8B5CF6', '#EC4899', '#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#06B6D4', '#8B5CF6', '#F97316', '#14B8A6', '#A855F7', '#6366F1'];

const AnalyticsPage: React.FC = () => {
  const getTodayDate = () => {
    const today = new Date();
    return today.toISOString().split('T')[0];
  };

  const [analytics, setAnalytics] = useState<any>(null);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSubject, setSelectedSubject] = useState<string>('all');
  const [startDate, setStartDate] = useState<string>('');
  const [endDate, setEndDate] = useState<string>('');
  const [isFiltered, setIsFiltered] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [analyticsData, subjectsData] = await Promise.all([
        analyticsService.getAnalytics(),
        subjectService.getAll(),
      ]);
      setAnalytics(analyticsData);
      setSubjects(subjectsData);
    } catch (error) {
      console.error('Failed to load analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleApplyFilters = async () => {
    try {
      setLoading(true);
      const query: any = {};
      if (startDate) query.startDate = startDate;
      if (endDate) query.endDate = endDate;
      if (selectedSubject !== 'all') query.subjectId = selectedSubject;

      const data = await analyticsService.getAnalytics(query);
      setAnalytics(data);
      setIsFiltered(true);
    } catch (error) {
      console.error('Failed to apply filters:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleClearFilters = () => {
    setSelectedSubject('all');
    setStartDate('');
    setEndDate('');
    setIsFiltered(false);
    loadData();
  };

  const handleTodayFilter = () => {
    const today = getTodayDate();
    setStartDate(today);
    setEndDate(today);
    setSelectedSubject('all');

    const query: any = {
      startDate: today,
      endDate: today,
    };

    setLoading(true);
    analyticsService
      .getAnalytics(query)
      .then((data) => {
        setAnalytics(data);
        setIsFiltered(true);
      })
      .catch((error) => console.error('Failed to load analytics:', error))
      .finally(() => setLoading(false));
  };

  const formatTime = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
  };

  if (loading) {
    return (
      <MainLayout>
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '60vh' }}>
          <CircularProgress size={48} />
        </Box>
      </MainLayout>
    );
  }

  return (
    <MainLayout>
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        {/* Header */}
        <Box sx={{ mb: 3 }}>
          <Typography variant="h4" fontWeight={600} gutterBottom>
            Analytics
            {isFiltered && startDate === endDate && startDate === getTodayDate() && (
              <Typography component="span" variant="body1" color="primary" fontWeight={600} sx={{ ml: 2 }}>
                — Today
              </Typography>
            )}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Insights into your study patterns and progress
          </Typography>
        </Box>

        {/* Filters */}
        <Paper sx={{ p: 3, mb: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <FilterList sx={{ mr: 1 }} />
            <Typography variant="h6">Filters</Typography>
          </Box>
          <LocalizationProvider dateAdapter={AdapterDateFns}>
            <Grid container spacing={2} alignItems="center">
              <Grid item xs={12} sm={6} md={3}>
                <FormControl fullWidth size="small">
                  <InputLabel>Subject</InputLabel>
                  <Select
                    value={selectedSubject}
                    label="Subject"
                    onChange={(e) => setSelectedSubject(e.target.value)}
                  >
                    <MenuItem value="all">All Subjects</MenuItem>
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
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <DatePicker
                  label="Start Date"
                  value={startDate ? new Date(startDate) : null}
                  onChange={(newValue) => {
                    if (newValue) {
                      setStartDate(newValue.toISOString().split('T')[0]);
                    } else {
                      setStartDate('');
                    }
                  }}
                  format="MM/dd/yyyy"
                  slotProps={{
                    textField: { fullWidth: true, size: 'small' },
                  }}
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <DatePicker
                  label="End Date"
                  value={endDate ? new Date(endDate) : null}
                  onChange={(newValue) => {
                    if (newValue) {
                      setEndDate(newValue.toISOString().split('T')[0]);
                    } else {
                      setEndDate('');
                    }
                  }}
                  format="MM/dd/yyyy"
                  slotProps={{
                    textField: { fullWidth: true, size: 'small' },
                  }}
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ display: 'flex', gap: 1 }}>
                  <Button variant="outlined" size="small" onClick={handleTodayFilter}>
                    Today
                  </Button>
                  <Button variant="contained" size="small" onClick={handleApplyFilters} startIcon={<TrendingUp />}>
                    Apply
                  </Button>
                  <MuiTooltip title="Clear Filters">
                    <IconButton onClick={handleClearFilters} color="primary" size="small">
                      <FilterList />
                    </IconButton>
                  </MuiTooltip>
                  <MuiTooltip title="Refresh">
                    <IconButton onClick={loadData} color="primary" size="small">
                      <Refresh />
                    </IconButton>
                  </MuiTooltip>
                </Box>
              </Grid>
            </Grid>
          </LocalizationProvider>
        </Paper>

        {/* Stats Cards */}
        {analytics && (
          <Box
            sx={{
              display: 'grid',
              gridTemplateColumns: { xs: '1fr 1fr', md: 'repeat(4, 1fr)' },
              gap: 3,
              mb: 4,
            }}
          >
            {[
              { label: 'Total Study Time', value: formatTime(analytics.totalEffectiveTime), gradient: 'linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%)', shadow: 'rgba(139,92,246,0.3)' },
              { label: 'Total Sessions', value: analytics.totalSessions, gradient: 'linear-gradient(135deg, #EC4899 0%, #DB2777 100%)', shadow: 'rgba(236,72,153,0.3)' },
              { label: 'Average Session', value: formatTime(Math.round(analytics.averageSessionDuration)), gradient: 'linear-gradient(135deg, #3B82F6 0%, #2563EB 100%)', shadow: 'rgba(59,130,246,0.3)' },
              { label: 'Break Time', value: formatTime(analytics.totalBreakTime), gradient: 'linear-gradient(135deg, #F59E0B 0%, #D97706 100%)', shadow: 'rgba(245,158,11,0.3)' },
            ].map((card) => (
              <Card
                key={card.label}
                elevation={2}
                sx={{
                  background: card.gradient,
                  color: 'white',
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: `0 12px 24px ${card.shadow}`,
                  },
                }}
              >
                <CardContent sx={{ p: 3 }}>
                  <Typography variant="body2" sx={{ opacity: 0.9, mb: 0.5 }}>
                    {card.label}
                  </Typography>
                  <Typography variant="h4" fontWeight="bold">
                    {card.value}
                  </Typography>
                </CardContent>
              </Card>
            ))}
          </Box>
        )}

        {/* Charts - each full width, stacked vertically */}
        {analytics && analytics.subjectStats.length > 0 ? (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            {/* Pie Chart - Study Time Distribution */}
            <Paper elevation={2} sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={600} gutterBottom>
                Study Time by Subject
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                How your study time is distributed across subjects
              </Typography>
              <ResponsiveContainer width="100%" height={400}>
                <PieChart>
                  <Pie
                    data={analytics.subjectStats}
                    dataKey="totalTime"
                    nameKey="subjectName"
                    cx="35%"
                    cy="50%"
                    outerRadius={140}
                    innerRadius={70}
                    paddingAngle={2}
                  >
                    {analytics.subjectStats.map((_entry: any, index: number) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value: any) => formatTime(value)} />
                  <Legend
                    layout="vertical"
                    align="right"
                    verticalAlign="middle"
                    wrapperStyle={{ paddingLeft: 30 }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </Paper>

            {/* Bar Chart - Sessions per Subject */}
            <Paper elevation={2} sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={600} gutterBottom>
                Sessions per Subject
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Number of study sessions completed for each subject
              </Typography>
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={analytics.subjectStats} margin={{ bottom: 60 }}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis
                    dataKey="subjectName"
                    angle={-35}
                    textAnchor="end"
                    interval={0}
                    height={80}
                    tick={{ fontSize: 12 }}
                  />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="sessionCount" fill="#8B5CF6" name="Sessions" radius={[6, 6, 0, 0]}>
                    {analytics.subjectStats.map((_entry: any, index: number) => (
                      <Cell key={`bar-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </Paper>

            {/* Line Chart - Daily Trends */}
            <Paper elevation={2} sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={600} gutterBottom>
                Daily Study Trends
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Your daily study time over the selected period
              </Typography>
              <ResponsiveContainer width="100%" height={350}>
                <LineChart data={analytics.dailyStats}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis
                    dataKey="date"
                    tickFormatter={(date) => {
                      const d = new Date(date);
                      return `${d.getMonth() + 1}/${d.getDate()}`;
                    }}
                  />
                  <YAxis
                    tickFormatter={(value) => {
                      const hours = Math.floor(value / 3600);
                      return `${hours}h`;
                    }}
                  />
                  <Tooltip
                    labelFormatter={(date) => new Date(date).toLocaleDateString()}
                    formatter={(value: any) => [formatTime(value), 'Study Time']}
                  />
                  <Legend />
                  <Line
                    type="monotone"
                    dataKey="totalTime"
                    stroke="#8B5CF6"
                    strokeWidth={2}
                    name="Study Time"
                    dot={{ r: 3 }}
                    activeDot={{ r: 6 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </Paper>

            {/* Subject Performance Summary */}
            <Paper elevation={2} sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
                Subject Performance Summary
              </Typography>
              <Box
                sx={{
                  display: 'grid',
                  gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: 'repeat(3, 1fr)' },
                  gap: 2,
                }}
              >
                {analytics.subjectStats.map((stat: any, index: number) => (
                  <Card
                    key={stat.subjectId}
                    variant="outlined"
                    sx={{
                      borderLeft: `4px solid ${COLORS[index % COLORS.length]}`,
                      transition: 'all 0.2s ease',
                      '&:hover': {
                        bgcolor: `${COLORS[index % COLORS.length]}08`,
                        transform: 'translateX(4px)',
                      },
                    }}
                  >
                    <CardContent sx={{ py: 2, '&:last-child': { pb: 2 } }}>
                      <Box display="flex" alignItems="center" gap={1} mb={1.5}>
                        <Box
                          sx={{
                            width: 14,
                            height: 14,
                            borderRadius: '50%',
                            bgcolor: COLORS[index % COLORS.length],
                            flexShrink: 0,
                          }}
                        />
                        <Typography variant="subtitle2" fontWeight={600} noWrap>
                          {stat.subjectName}
                        </Typography>
                      </Box>
                      <Box display="flex" justifyContent="space-between" mb={0.5}>
                        <Typography variant="body2" color="text.secondary">
                          Total Time
                        </Typography>
                        <Typography variant="body2" fontWeight={600}>
                          {formatTime(stat.totalTime)}
                        </Typography>
                      </Box>
                      <Box display="flex" justifyContent="space-between" mb={0.5}>
                        <Typography variant="body2" color="text.secondary">
                          Sessions
                        </Typography>
                        <Typography variant="body2" fontWeight={600}>
                          {stat.sessionCount}
                        </Typography>
                      </Box>
                      <Box display="flex" justifyContent="space-between">
                        <Typography variant="body2" color="text.secondary">
                          Avg. Duration
                        </Typography>
                        <Typography variant="body2" fontWeight={600}>
                          {formatTime(Math.round(stat.averageSessionDuration))}
                        </Typography>
                      </Box>
                    </CardContent>
                  </Card>
                ))}
              </Box>
            </Paper>
          </Box>
        ) : (
          <Paper sx={{ p: 8, textAlign: 'center' }}>
            <Assessment sx={{ fontSize: 60, color: 'text.disabled', mb: 2 }} />
            <Typography variant="h6" color="text.secondary" gutterBottom>
              No Data Available
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Start tracking your study sessions to see analytics here!
            </Typography>
          </Paper>
        )}
      </Container>
    </MainLayout>
  );
};

export default AnalyticsPage;
