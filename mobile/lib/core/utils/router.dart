import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/screens/login_screen.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/screens/register_screen.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/screens/dashboard_screen.dart';
import 'package:study_time_tracker/src/presentation/modules/study/shell/screens/study_shell_screen.dart';

GoRouter createRouter(ITokenStorageService tokenStorageService) => GoRouter(
      debugLogDiagnostics: kDebugMode,
      initialLocation: '/dashboard',
      refreshListenable: _ValueListenableAdapter(tokenStorageService.isAuthenticated),
      redirect: (context, state) {
        final isAuthenticated = tokenStorageService.isAuthenticated.value;
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

/// Bridges `ValueListenable<bool>` (which exposes value changes) to the
/// `Listenable` shape `GoRouter.refreshListenable` expects.
class _ValueListenableAdapter extends ChangeNotifier {
  _ValueListenableAdapter(this._source) {
    _source.addListener(_forward);
  }

  final ValueListenable<bool> _source;

  void _forward() => notifyListeners();

  @override
  void dispose() {
    _source.removeListener(_forward);
    super.dispose();
  }
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
