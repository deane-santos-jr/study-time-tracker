import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        if (state is LogoutSuccess) context.go('/login');
      },
      child: Scaffold(
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
      ),
    );
  }
}
