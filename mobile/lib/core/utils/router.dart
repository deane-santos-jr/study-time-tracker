import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/screens/login_screen.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/screens/register_screen.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/screens/dashboard_screen.dart';
import 'package:study_time_tracker/src/presentation/modules/study/shell/screens/study_shell_screen.dart';

GoRouter createRouter(ITokenStorageService tokenStorageService) => GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/dashboard',
      redirect: (context, state) async {
        final hasToken = await tokenStorageService.hasAccessToken();
        final isExpired = await tokenStorageService.isAccessTokenExpired();
        final isAuthenticated = hasToken && !isExpired;
        final isPublic = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isAuthenticated && !isPublic) return '/login';
        if (isAuthenticated && isPublic) return '/dashboard';
        if (state.matchedLocation == '/') return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (_, state) => _page(const LoginScreen(), state.pageKey),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (_, state) => _page(const RegisterScreen(), state.pageKey),
        ),
        // MARK: study-shell-routes-start
        StatefulShellRoute.indexedStack(
          pageBuilder: (_, state, navigationShell) => _page(
            StudyShellScreen(navigationShell: navigationShell),
            state.pageKey,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  pageBuilder: (_, state) =>
                      _page(const DashboardScreen(), state.pageKey),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/analytics',
                  pageBuilder: (_, state) => _page(
                    const _Placeholder(title: 'Analytics'),
                    state.pageKey,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  pageBuilder: (_, state) => _page(
                    const _Placeholder(title: 'Profile'),
                    state.pageKey,
                  ),
                ),
              ],
            ),
          ],
        ),
        // MARK: study-shell-routes-end
      ],
    );

CustomTransitionPage<void> _page(Widget child, LocalKey key) {
  return CustomTransitionPage<void>(
    child: child,
    key: key,
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurveTween(curve: Curves.easeIn).animate(animation),
      child: child,
    ),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen — coming soon')),
    );
  }
}
