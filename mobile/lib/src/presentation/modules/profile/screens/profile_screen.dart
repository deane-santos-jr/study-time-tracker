import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/user/user_profile.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/profile/services/profile_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/profile/widgets/delete_account_sheet.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const MainAppBar(title: 'you'),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return switch (state) {
            ProfileInitial() || ProfileLoading() => Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ProfileError(:final errorMessage) => _ErrorBody(
                message: errorMessage,
                onRetry: () => context.read<ProfileCubit>().load(),
              ),
            ProfileLoaded(:final profile) => _LoadedBody(profile: profile),
            ProfileDeleted() => const Center(
                child: CircularProgressIndicator(),
              ),
          };
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.profile});

  final UserProfile profile;

  static const _months = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  String _formatJoined(DateTime when) {
    return 'joined ${_months[when.month - 1]} ${when.year}';
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthenticationCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final faintInk = ink.withValues(alpha: InkOpacity.faint);
    final bottomReserve = 56 +
        Spacing.md +
        MediaQuery.viewPaddingOf(context).bottom +
        Spacing.md;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.lg,
          Spacing.lg,
          bottomReserve,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              profile.fullName.toLowerCase(),
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              profile.email,
              style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              _formatJoined(profile.createdAt),
              style: theme.textTheme.bodyMedium?.copyWith(color: faintInk),
            ),
            const SizedBox(height: Spacing.xl),
            PulpTile(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'account',
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: softInk),
                  ),
                  const SizedBox(height: Spacing.sm),
                  DefaultButton(
                    title: 'sign out',
                    fullWidth: true,
                    size: ButtonSize.large,
                    type: ButtonType.secondary,
                    onPressed: () => _signOut(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            DefaultButton(
              title: 'delete my account',
              fullWidth: true,
              size: ButtonSize.medium,
              type: ButtonType.ghost,
              onPressed: () => showDeleteAccountSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk =
        theme.colorScheme.onSurface.withValues(alpha: InkOpacity.soft);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'something went wrong',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: softInk),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              TextButton(
                onPressed: onRetry,
                child: const Text('try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
