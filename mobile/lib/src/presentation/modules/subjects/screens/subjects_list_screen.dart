import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/dashboard_stats_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/active_semester_pill.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/widgets/subject_form_sheet.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/widgets/subject_tile.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';

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
      final stats = context.read<DashboardStatsCubit>();
      if (stats.state is DashboardStatsInitial) {
        stats.load();
      }
    });
  }

  Future<void> _onAddSubject(BuildContext context) async {
    final semestersState = context.read<SemestersCubit>().state;
    final availableSemesters = semestersState is SemestersLoaded
        ? semestersState.semesters
        : <Semester>[];
    final defaultSemesterId = semestersState is SemestersLoaded
        ? semestersState.activeSemesterId
        : null;

    final result = await showSubjectFormSheet(
      context,
      availableSemesters: availableSemesters,
      defaultSemesterId: defaultSemesterId,
    );
    if (!context.mounted || result == null) return;

    String semesterId;
    if (result.inlineSemester != null) {
      final newSemester = await context
          .read<SemestersCubit>()
          .create(payload: result.inlineSemester!);
      if (!context.mounted || newSemester == null) return;
      if (!newSemester.isActive) {
        await context.read<SemestersCubit>().activate(id: newSemester.id);
      }
      semesterId = newSemester.id;
    } else {
      semesterId = result.subject.semesterId;
    }

    if (!context.mounted) return;
    final ok = await context.read<SubjectsCubit>().createSubject(
          payload: SubjectCreatePayload(
            name: result.subject.name,
            color: result.subject.color,
            semesterId: semesterId,
          ),
        );
    if (!context.mounted) return;
    if (ok) {
      CoreUtils.showNotification(
        message: '${result.subject.name.toLowerCase()} added',
        success: true,
        context: context,
      );
    }
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
        title: Text(
          'delete ${subject.name.toLowerCase()}?',
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          'sessions for this subject will be preserved as ad-hoc activities.',
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
        CoreUtils.showNotification(
          message: msg,
          success: false,
          context: context,
        );
      }
    } else if (ok && context.mounted) {
      CoreUtils.showNotification(
        message: 'sessions preserved as ad-hoc activities',
        success: true,
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: 'subjects',
        titleWidget: BlocBuilder<SemestersCubit, SemestersState>(
          builder: (context, state) {
            if (state is! SemestersLoaded) return const SizedBox.shrink();
            final active = state.activeSemester;
            if (active == null) return const SizedBox.shrink();
            return ActiveSemesterPill(semester: active);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'add subject',
            onPressed: () => _onAddSubject(context),
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
            SubjectsInitial() || SubjectsLoading() => Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            SubjectsError(:final errorMessage) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Text(errorMessage, textAlign: TextAlign.center),
                ),
              ),
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
              Text(
                "you haven't added any subjects yet",
                style: theme.textTheme.displaySmall,
              ),
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
        final sub = context.read<SubjectsCubit>();
        final stats = context.read<DashboardStatsCubit>();
        await sub.loadForSemester(state.semesterId);
        if (context.mounted) await stats.load();
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
                semester: null,
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

double _bottomNavReserve(BuildContext context) {
  return 56 +
      Spacing.md +
      MediaQuery.viewPaddingOf(context).bottom +
      Spacing.md;
}
