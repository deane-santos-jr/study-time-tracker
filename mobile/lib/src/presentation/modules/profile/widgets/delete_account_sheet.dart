import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/presentation/modules/profile/services/profile_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';

/// Modal that confirms account deletion via password re-entry. The actual
/// delete + token-clear is driven by [ProfileCubit.deleteAccount]; this
/// widget closes once the cubit reports [ProfileDeleted].
Future<void> showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<ProfileCubit>(),
      child: const _DeleteAccountSheet(),
    ),
  );
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final password = _password.text;
    if (password.isEmpty) return;
    await context.read<ProfileCubit>().deleteAccount(password: password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final danger = theme.colorScheme.error;
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileDeleted) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final loaded = state is ProfileLoaded ? state : null;
        final deleting = loaded?.deleting ?? false;
        final errorMessage = loaded?.deleteError;
        final canConfirm = !deleting && _password.text.isNotEmpty;

        return Padding(
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.sm,
                Spacing.lg,
                Spacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(Radii.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'delete your account?',
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    "this is permanent. your terms, subjects, sessions, breaks, and notes will be removed and cannot be restored.",
                    style:
                        theme.textTheme.bodyLarge?.copyWith(color: softInk),
                  ),
                  const SizedBox(height: Spacing.lg),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autofocus: true,
                    enabled: !deleting,
                    decoration: const InputDecoration(
                      labelText: 'password',
                      hintText: 'enter your password to confirm',
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => canConfirm ? _confirm() : null,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      errorMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.xl),
                  DefaultButton(
                    title: 'delete forever',
                    fullWidth: true,
                    size: ButtonSize.large,
                    isLoading: deleting,
                    onPressed: canConfirm ? _confirm : null,
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextButton(
                    onPressed:
                        deleting ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: softInk),
                    child: const Text('cancel'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
