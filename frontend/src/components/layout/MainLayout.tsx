import { useState } from 'react';
import {
  Box,
  AppBar,
  Toolbar,
  Typography,
  Button,
  Avatar,
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  IconButton,
  Chip,
} from '@mui/material';
import {
  Logout as LogoutIcon,
  Menu as MenuIcon,
  Dashboard as DashboardIcon,
  Subject as SubjectIcon,
  History as HistoryIcon,
  Analytics as AnalyticsIcon,
  CalendarMonth as CalendarIcon,
  Timer as TimerIcon,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { useNavigate, useLocation } from 'react-router-dom';

const drawerWidth = 260;

interface MainLayoutProps {
  children: React.ReactNode;
}

export const MainLayout: React.FC<MainLayoutProps> = ({ children }) => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const menuItems = [
    { text: 'Dashboard', icon: <DashboardIcon />, path: '/dashboard', color: '#8B5CF6' },
    { text: 'Semesters', icon: <CalendarIcon />, path: '/semesters', color: '#EC4899' },
    { text: 'Subjects', icon: <SubjectIcon />, path: '/subjects', color: '#3B82F6' },
    { text: 'Analytics', icon: <AnalyticsIcon />, path: '/analytics', color: '#10B981' },
    { text: 'History', icon: <HistoryIcon />, path: '/history', color: '#F59E0B' },
  ];

  const isActive = (path: string) => location.pathname === path;

  const drawer = (
    <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column', bgcolor: '#FAFAFA' }}>
      <Toolbar sx={{ borderBottom: '1px solid #E5E7EB', mb: 1 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box
            sx={{
              width: 36,
              height: 36,
              borderRadius: 2,
              background: 'linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <TimerIcon sx={{ color: 'white', fontSize: 20 }} />
          </Box>
          <Typography variant="h6" fontWeight={700} sx={{
            background: 'linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
          }}>
            TimeTracker
          </Typography>
        </Box>
      </Toolbar>
      <List sx={{ px: 1.5, flex: 1 }}>
        {menuItems.map((item) => (
          <ListItem key={item.text} disablePadding sx={{ mb: 0.5 }}>
            <ListItemButton
              onClick={() => navigate(item.path)}
              sx={{
                borderRadius: 2,
                py: 1.5,
                px: 2,
                transition: 'all 0.2s ease',
                bgcolor: isActive(item.path) ? `${item.color}15` : 'transparent',
                borderLeft: isActive(item.path) ? `3px solid ${item.color}` : '3px solid transparent',
                '&:hover': {
                  bgcolor: isActive(item.path) ? `${item.color}20` : `${item.color}08`,
                  transform: 'translateX(4px)',
                },
              }}
            >
              <ListItemIcon sx={{
                minWidth: 40,
                color: isActive(item.path) ? item.color : '#6B7280',
              }}>
                {item.icon}
              </ListItemIcon>
              <ListItemText
                primary={item.text}
                primaryTypographyProps={{
                  fontWeight: isActive(item.path) ? 600 : 400,
                  fontSize: '0.95rem',
                  color: isActive(item.path) ? item.color : '#374151',
                }}
              />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar
        position="fixed"
        elevation={0}
        sx={{
          zIndex: (theme) => theme.zIndex.drawer + 1,
          bgcolor: 'white',
          borderBottom: '1px solid #E5E7EB',
        }}
      >
        <Toolbar sx={{ gap: 2 }}>
          <IconButton
            color="default"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{
              mr: 1,
              display: { sm: 'none' },
              color: '#6B7280',
            }}
          >
            <MenuIcon />
          </IconButton>

          {/* Logo for mobile */}
          <Box sx={{ display: { xs: 'flex', sm: 'none' }, alignItems: 'center', gap: 1 }}>
            <Box
              sx={{
                width: 32,
                height: 32,
                borderRadius: 1.5,
                background: 'linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <TimerIcon sx={{ color: 'white', fontSize: 18 }} />
            </Box>
            <Typography variant="h6" fontWeight={700} sx={{
              background: 'linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
            }}>
              TimeTracker
            </Typography>
          </Box>

          <Box sx={{ flexGrow: 1 }} />

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box
              sx={{
                display: { xs: 'none', md: 'flex' },
                flexDirection: 'column',
                alignItems: 'flex-end',
              }}
            >
              <Typography variant="body2" fontWeight={600} sx={{ color: '#111827' }}>
                {user?.firstName} {user?.lastName}
              </Typography>
              <Typography variant="caption" sx={{ color: '#6B7280' }}>
                {user?.email}
              </Typography>
            </Box>
            <Avatar
              sx={{
                bgcolor: '#8B5CF6',
                width: 40,
                height: 40,
                fontWeight: 600,
                fontSize: '1rem',
              }}
            >
              {user?.firstName?.[0]}{user?.lastName?.[0]}
            </Avatar>
            <Button
              variant="outlined"
              startIcon={<LogoutIcon />}
              onClick={handleLogout}
              sx={{
                color: '#6B7280',
                borderColor: '#E5E7EB',
                textTransform: 'none',
                fontWeight: 500,
                borderRadius: 2,
                px: 2,
                '&:hover': {
                  borderColor: '#D1D5DB',
                  bgcolor: '#F9FAFB',
                },
              }}
            >
              <Box sx={{ display: { xs: 'none', sm: 'block' } }}>Logout</Box>
            </Button>
          </Box>
        </Toolbar>
      </AppBar>

      <Box
        component="nav"
        sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }}
      >
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{ keepMounted: true }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: drawerWidth,
              border: 'none',
            },
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: drawerWidth,
              border: 'none',
              borderRight: '1px solid #E5E7EB',
            },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          mt: 8,
          bgcolor: '#F9FAFB',
          minHeight: '100vh',
        }}
      >
        {children}
      </Box>
    </Box>
  );
};
