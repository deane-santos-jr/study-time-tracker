import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/dashboard_stats_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/widgets/subject_tile.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_textfield.dart';

class SubjectsListScreen extends StatefulWidget {
  const SubjectsListScreen({super.key});

  @override
  State<SubjectsListScreen> createState() => _SubjectsListScreenState();
}

class _SubjectsListScreenState extends State<SubjectsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubjectsCubit>().load();
      // Per-subject totals come from the same `/analytics` summary the
      // dashboard reads. Trigger a load if it hasn't already happened (e.g.
      // user lands directly on /subjects after deep-link).
      final stats = context.read<DashboardStatsCubit>();
      if (stats.state is DashboardStatsInitial) {
        stats.load();
      }
    });
  }

  void _onAddSubject(BuildContext context) {
    context.push('/subjects/new');
  }

  Future<void> _confirmDelete(BuildContext context, Subject subject) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        title: Text('delete ${subject.name}?', style: theme.textTheme.titleLarge),
        content: Text(
          'sessions for this subject keep their history, but the subject will no longer appear in the list.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final cubit = context.read<SubjectsCubit>();
    final ok = await cubit.deleteSubject(id: subject.id);
    if (!ok && context.mounted) {
      final s = cubit.state;
      final msg = s is SubjectsLoaded ? s.mutationError : null;
      if (msg != null) {
        CoreUtils.showNotification(message: msg, success: false, context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: 'subjects',
        actions: [
          BlocBuilder<SubjectsCubit, SubjectsState>(
            builder: (context, state) {
              if (state is! SubjectsLoaded || state.subjects.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'add subject',
                onPressed: () => _onAddSubject(context),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<SubjectsCubit, SubjectsState>(
        listenWhen: (prev, next) =>
            next is SubjectsLoaded && next.mutationError != null,
        listener: (context, state) {
          if (state is SubjectsLoaded && state.mutationError != null) {
            CoreUtils.showNotification(
              message: state.mutationError!,
              success: false,
              context: context,
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            SubjectsInitial() || SubjectsLoading() => const _LoadingBody(),
            SubjectsNoSemesters() => const _NoSemesterBody(),
            SubjectsError(:final errorMessage) => _ErrorBody(message: errorMessage),
            SubjectsLoaded() => _LoadedBody(
                state: state,
                onAdd: () => _onAddSubject(context),
                onEdit: (s) => context.push('/subjects/${s.id}'),
                onDelete: _confirmDelete,
              ),
          };
        },
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _NoSemesterBody extends StatefulWidget {
  const _NoSemesterBody();

  @override
  State<_NoSemesterBody> createState() => _NoSemesterBodyState();
}

class _NoSemesterBodyState extends State<_NoSemesterBody> {
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = start
        ? (_startDate ?? now)
        : (_endDate ?? _startDate?.add(const Duration(days: 90)) ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final nameErr = CoreUtils.validateRequired(_nameController.text, field: 'name');
    if (nameErr != null) {
      CoreUtils.showNotification(message: nameErr, success: false, context: context);
      return;
    }
    if (_startDate == null || _endDate == null) {
      CoreUtils.showNotification(
        message: 'pick both a start and end date',
        success: false,
        context: context,
      );
      return;
    }
    if (!_startDate!.isBefore(_endDate!)) {
      CoreUtils.showNotification(
        message: 'start date must be before end date',
        success: false,
        context: context,
      );
      return;
    }
    setState(() => _submitting = true);
    await context.read<SubjectsCubit>().createSemester(
          name: _nameController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface.withValues(alpha: InkOpacity.soft);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.lg,
          Spacing.lg,
          _bottomNavReserve(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: Spacing.md),
            Text('start with a semester', style: theme.textTheme.displaySmall),
            const SizedBox(height: Spacing.xs),
            Text(
              'subjects live inside semesters. give yours a name and dates.',
              style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
            ),
            const SizedBox(height: Spacing.xl),
            DefaultTextfield(
              controller: _nameController,
              label: 'semester name',
              placeholder: 'spring 2026',
              textInputAction: TextInputAction.next,
              required: true,
            ),
            const SizedBox(height: Spacing.md),
            _DateField(
              label: 'start date',
              value: _startDate,
              onTap: () => _pickDate(start: true),
            ),
            const SizedBox(height: Spacing.md),
            _DateField(
              label: 'end date',
              value: _endDate,
              onTap: () => _pickDate(start: false),
            ),
            const SizedBox(height: Spacing.lg),
            DefaultButton(
              title: 'create semester',
              fullWidth: true,
              size: ButtonSize.large,
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final hintInk = ink.withValues(alpha: InkOpacity.faint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: Text(
            '$label *',
            style: theme.textTheme.labelMedium,
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: ink.withValues(alpha: InkOpacity.hint)),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? CoreUtils.formatDate(value!) : 'pick a date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: value != null ? ink : hintInk,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 18, color: softInk),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 48),
              const SizedBox(height: Spacing.md),
              Text(
                'something went wrong',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: InkOpacity.soft),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              DefaultButton(
                title: 'try again',
                type: ButtonType.secondary,
                onPressed: () => context.read<SubjectsCubit>().load(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.state,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final SubjectsLoaded state;
  final VoidCallback onAdd;
  final ValueChanged<Subject> onEdit;
  final void Function(BuildContext, Subject) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);
    final bottomReserve = _bottomNavReserve(context);

    if (state.subjects.isEmpty) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.lg,
            Spacing.lg,
            bottomReserve,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Spacing.md),
              Text("you haven't added any subjects yet",
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: Spacing.xs),
              Text(
                'pick a color, name your subject, and start tracking.',
                style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
              ),
              const SizedBox(height: Spacing.xl),
              DefaultButton(
                title: 'add your first subject',
                fullWidth: true,
                size: ButtonSize.large,
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<SubjectsCubit>().load();
        if (context.mounted) {
          await context.read<DashboardStatsCubit>().load();
        }
      },
      color: theme.colorScheme.primary,
      child: BlocBuilder<DashboardStatsCubit, DashboardStatsState>(
        builder: (context, statsState) {
          final loadingStats = statsState is DashboardStatsInitial ||
              statsState is DashboardStatsLoading;
          final totalsBySubject = <String, int>{
            if (statsState is DashboardStatsLoaded)
              for (final s in statsState.subjectStats) s.subjectId: s.totalTime,
          };
          final count = state.subjects.length;
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              bottomReserve,
            ),
            itemCount: state.subjects.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: Spacing.xs,
                    bottom: Spacing.xs,
                  ),
                  child: Text(
                    count == 1 ? '1 subject' : '$count subjects',
                    style: theme.textTheme.labelSmall?.copyWith(color: softInk),
                  ),
                );
              }
              final subject = state.subjects[index - 1];
              return SubjectTile(
                subject: subject,
                semester: state.semesterFor(subject.semesterId),
                totalSeconds: totalsBySubject[subject.id],
                loadingTotal: loadingStats,
                onTap: () => onEdit(subject),
                onDelete: () => onDelete(context, subject),
              );
            },
          );
        },
      ),
    );
  }
}

/// Match the dashboard's bottom-nav clearance so the last row clears the
/// floating Cocoa Ink pill in `study_shell_screen.dart`.
double _bottomNavReserve(BuildContext context) {
  return 56 +
      Spacing.md +
      MediaQuery.viewPaddingOf(context).bottom +
      Spacing.md;
}
