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
import { Refresh, TrendingUp, Assessment } from '@mui/icons-material';
import { MainLayout } from '../components/layout/MainLayout';
import { analyticsService } from '../services/analyticsService';
import { subjectService } from '../services/subjectService';
import type { Subject } from '../types';

const AnalyticsPage: React.FC = () => {
  // Get today's date in YYYY-MM-DD format
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
      // Load all data without filters initially
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
    analyticsService.getAnalytics(query)
      .then(data => {
        setAnalytics(data);
        setIsFiltered(true);
      })
      .catch(error => console.error('Failed to load analytics:', error))
      .finally(() => setLoading(false));
  };

  const formatTime = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
  };

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#82CA9D', '#FF6B9D', '#C9A0DC'];

  if (loading) {
    return (
      <MainLayout>
        <Container maxWidth="xl" sx={{ py: 4 }}>
          <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
            <CircularProgress size={60} />
          </Box>
        </Container>
      </MainLayout>
    );
  }

  return (
    <MainLayout>
      <Container maxWidth="xl" sx={{ py: 4 }}>
        {/* Header */}
        <Box sx={{ mb: 4 }}>
          <Box display="flex" alignItems="center" gap={2} mb={2}>
            <Assessment sx={{ fontSize: 40, color: 'primary.main' }} />
            <Box>
              <Typography variant="h3" fontWeight={700}>
                Analytics Dashboard
              </Typography>
              {isFiltered && startDate === endDate && startDate === getTodayDate() && (
                <Typography variant="subtitle1" color="primary" fontWeight={600}>
                  Today's Analytics
                </Typography>
              )}
              {!isFiltered && (
                <Typography variant="subtitle1" color="text.secondary" fontWeight={500}>
                  All Time
                </Typography>
              )}
            </Box>
          </Box>
          <Typography variant="body1" color="text.secondary">
            Comprehensive insights into your study patterns and progress
          </Typography>
        </Box>

        {/* Filters */}
        <Paper elevation={2} sx={{ p: 3, mb: 4 }}>
          <Typography variant="h6" fontWeight={600} gutterBottom>
            Filters
          </Typography>
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
                    textField: {
                      fullWidth: true,
                      size: 'small',
                    },
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
                    textField: {
                      fullWidth: true,
                      size: 'small',
                    },
                  }}
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                  <Button
                    variant="contained"
                    onClick={handleTodayFilter}
                    sx={{ flex: '1 1 auto' }}
                  >
                    Today
                  </Button>
                  <Button
                    variant="contained"
                    onClick={handleApplyFilters}
                    startIcon={<TrendingUp />}
                    sx={{ flex: '1 1 auto' }}
                  >
                    Apply
                  </Button>
                  <Button
                    variant="outlined"
                    onClick={handleClearFilters}
                    startIcon={<Refresh />}
                  >
                    Clear
                  </Button>
                </Box>
              </Grid>
            </Grid>
          </LocalizationProvider>
        </Paper>

        {/* Stats Cards */}
        {analytics && (
          <Grid container spacing={3} sx={{ mb: 4 }}>
            <Grid item xs={12} sm={6} md={3}>
              <Card elevation={3} sx={{ height: '100%', background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
                <CardContent>
                  <Typography color="white" gutterBottom variant="body2" fontWeight={500}>
                    Total Study Time
                  </Typography>
                  <Typography variant="h3" fontWeight="bold" color="white">
                    {formatTime(analytics.totalEffectiveTime)}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card elevation={3} sx={{ height: '100%', background: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)' }}>
                <CardContent>
                  <Typography color="white" gutterBottom variant="body2" fontWeight={500}>
                    Total Sessions
                  </Typography>
                  <Typography variant="h3" fontWeight="bold" color="white">
                    {analytics.totalSessions}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card elevation={3} sx={{ height: '100%', background: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)' }}>
                <CardContent>
                  <Typography color="white" gutterBottom variant="body2" fontWeight={500}>
                    Average Session
                  </Typography>
                  <Typography variant="h3" fontWeight="bold" color="white">
                    {formatTime(Math.round(analytics.averageSessionDuration))}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card elevation={3} sx={{ height: '100%', background: 'linear-gradient(135deg, #fa709a 0%, #fee140 100%)' }}>
                <CardContent>
                  <Typography color="white" gutterBottom variant="body2" fontWeight={500}>
                    Break Time
                  </Typography>
                  <Typography variant="h3" fontWeight="bold" color="white">
                    {formatTime(analytics.totalBreakTime)}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        )}

        {/* Charts */}
        {analytics && analytics.subjectStats.length > 0 ? (
          <Grid container spacing={3}>
            {/* Subject Distribution Pie Chart */}
            <Grid item xs={12} lg={6}>
              <Paper elevation={3} sx={{ p: 4, height: 650 }}>
                <Typography variant="h5" fontWeight={600} gutterBottom>
                  Study Time Distribution by Subject
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                  See how your study time is distributed across different subjects
                </Typography>
                <ResponsiveContainer width="100%" height={520}>
                  <PieChart>
                    <Pie
                      data={analytics.subjectStats}
                      dataKey="totalTime"
                      nameKey="subjectName"
                      cx="50%"
                      cy="50%"
                      outerRadius={180}
                    >
                      {analytics.subjectStats.map((entry: any, index: number) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip formatter={(value: any) => formatTime(value)} />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </Paper>
            </Grid>

            {/* Subject Sessions Bar Chart */}
            <Grid item xs={12} lg={6}>
              <Paper elevation={3} sx={{ p: 4, height: 650 }}>
                <Typography variant="h5" fontWeight={600} gutterBottom>
                  Sessions per Subject
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                  Number of study sessions completed for each subject
                </Typography>
                <ResponsiveContainer width="100%" height={520}>
                  <BarChart data={analytics.subjectStats}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="subjectName" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Bar dataKey="sessionCount" fill="#8884d8" name="Sessions" radius={[8, 8, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </Paper>
            </Grid>

            {/* Daily Trends Line Chart */}
            <Grid item xs={12}>
              <Paper elevation={3} sx={{ p: 4 }}>
                <Typography variant="h5" fontWeight={600} gutterBottom>
                  Daily Study Trends
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                  Track your daily study time over the selected period
                </Typography>
                <ResponsiveContainer width="100%" height={450}>
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
                      stroke="#8884d8"
                      strokeWidth={3}
                      name="Study Time"
                      dot={{ r: 5 }}
                      activeDot={{ r: 8 }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </Paper>
            </Grid>

            {/* Subject Performance Table */}
            <Grid item xs={12}>
              <Paper elevation={3} sx={{ p: 4 }}>
                <Typography variant="h5" fontWeight={600} gutterBottom sx={{ mb: 3 }}>
                  Subject Performance Summary
                </Typography>
                <Grid container spacing={2}>
                  {analytics.subjectStats.map((stat: any, index: number) => (
                    <Grid item xs={12} sm={6} md={4} key={stat.subjectId}>
                      <Card elevation={2} sx={{ background: `linear-gradient(135deg, ${COLORS[index % COLORS.length]}22 0%, ${COLORS[index % COLORS.length]}11 100%)` }}>
                        <CardContent>
                          <Box display="flex" alignItems="center" gap={1} mb={2}>
                            <Box
                              sx={{
                                width: 16,
                                height: 16,
                                borderRadius: '50%',
                                bgcolor: COLORS[index % COLORS.length],
                              }}
                            />
                            <Typography variant="h6" fontWeight={600}>
                              {stat.subjectName}
                            </Typography>
                          </Box>
                          <Box sx={{ mt: 2 }}>
                            <Box display="flex" justifyContent="space-between" mb={1}>
                              <Typography variant="body2" color="text.secondary">
                                Total Time:
                              </Typography>
                              <Typography variant="body2" fontWeight={600}>
                                {formatTime(stat.totalTime)}
                              </Typography>
                            </Box>
                            <Box display="flex" justifyContent="space-between" mb={1}>
                              <Typography variant="body2" color="text.secondary">
                                Sessions:
                              </Typography>
                              <Typography variant="body2" fontWeight={600}>
                                {stat.sessionCount}
                              </Typography>
                            </Box>
                            <Box display="flex" justifyContent="space-between">
                              <Typography variant="body2" color="text.secondary">
                                Avg. Duration:
                              </Typography>
                              <Typography variant="body2" fontWeight={600}>
                                {formatTime(Math.round(stat.averageSessionDuration))}
                              </Typography>
                            </Box>
                          </Box>
                        </CardContent>
                      </Card>
                    </Grid>
                  ))}
                </Grid>
              </Paper>
            </Grid>
          </Grid>
        ) : (
          <Paper sx={{ p: 8, textAlign: 'center' }}>
            <Assessment sx={{ fontSize: 80, color: 'text.secondary', mb: 2 }} />
            <Typography variant="h5" color="text.secondary" gutterBottom>
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
