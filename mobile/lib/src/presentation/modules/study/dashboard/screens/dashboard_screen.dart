import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // No BlocListener for LogoutSuccess: the router's refreshListenable already
  // redirects to /login when TokenStorageService.isAuthenticated flips to
  // false inside clearAll(), so listening here would just race with that.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthenticationCubit>().logout(),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Study sessions, subjects, timer, and analytics land here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
