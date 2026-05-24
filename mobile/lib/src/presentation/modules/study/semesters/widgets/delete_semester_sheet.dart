import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_stats.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';

/// Returns true if the user confirmed deletion (and the cubit succeeded).
Future<bool> showDeleteSemesterSheet(
  BuildContext context, {
  required Semester semester,
  required bool isActive,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
    ),
    builder: (_) => _DeleteSemesterSheet(
      semester: semester,
      isActive: isActive,
    ),
  );
  return result ?? false;
}

class _DeleteSemesterSheet extends StatefulWidget {
  const _DeleteSemesterSheet({required this.semester, required this.isActive});

  final Semester semester;
  final bool isActive;

  @override
  State<_DeleteSemesterSheet> createState() => _DeleteSemesterSheetState();
}

class _DeleteSemesterSheetState extends State<_DeleteSemesterSheet> {
  SemesterStats? _stats;
  bool _loadingStats = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = context.read<SemestersCubit>();
      final stats = await cubit.getStats(id: widget.semester.id);
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    });
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    final ok = await context
        .read<SemestersCubit>()
        .delete(id: widget.semester.id);
    if (!mounted) return;
    setState(() => _deleting = false);
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);
    final mediaQuery = MediaQuery.of(context);

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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Radii.full),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'delete ${widget.semester.name.toLowerCase()}?',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: Spacing.md),
              if (widget.isActive)
                Text(
                  "you can't delete your active term. switch to another term first, then try again.",
                  style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
                )
              else if (_loadingStats)
                Text(
                  'checking what will be preserved…',
                  style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
                )
              else if (_stats != null && _stats!.sessionCount == 0)
                Text(
                  "this term has nothing logged against it. it'll just be removed.",
                  style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
                )
              else if (_stats != null)
                Text(
                  '${_stats!.sessionCount} session${_stats!.sessionCount == 1 ? '' : 's'} · '
                  '${CoreUtils.formatHm(_stats!.totalSeconds, dashOnZero: false)} '
                  'will be preserved as ad-hoc activities.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
                ),
              const SizedBox(height: Spacing.xl),
              if (widget.isActive)
                DefaultButton(
                  title: 'got it',
                  fullWidth: true,
                  size: ButtonSize.large,
                  onPressed: () => Navigator.of(context).pop(false),
                )
              else
                DefaultButton(
                  title: 'delete term',
                  fullWidth: true,
                  size: ButtonSize.large,
                  isLoading: _deleting,
                  onPressed: _delete,
                ),
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: _deleting
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: softInk),
                child: const Text('cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
