import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/delete_semester_sheet.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/semester_card.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/semester_form_sheet.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';

class SemestersScreen extends StatefulWidget {
  const SemestersScreen({super.key});

  @override
  State<SemestersScreen> createState() => _SemestersScreenState();
}

class _SemestersScreenState extends State<SemestersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SemestersCubit>().load();
    });
  }

  Future<void> _create(BuildContext context, {required bool noActiveYet}) async {
    final result = await showSemesterFormSheet(context, noActiveYet: noActiveYet);
    if (!context.mounted || result == null || result.create == null) return;
    final cubit = context.read<SemestersCubit>();
    final created = await cubit.create(payload: result.create!);
    if (!context.mounted || created == null) return;
    if (result.makeActive && !created.isActive) {
      await cubit.activate(id: created.id);
    }
    if (!context.mounted) return;
    final msg = result.makeActive
        ? '${created.name.toLowerCase()} is now your active term'
        : '${created.name.toLowerCase()} added';
    CoreUtils.showNotification(message: msg, success: true, context: context);
  }

  Future<void> _edit(BuildContext context, Semester semester) async {
    final result = await showSemesterFormSheet(
      context,
      editing: semester,
      noActiveYet: false,
    );
    if (!context.mounted || result == null || result.update == null) return;
    final cubit = context.read<SemestersCubit>();
    await cubit.update(id: semester.id, payload: result.update!);
  }

  Future<void> _delete(BuildContext context, Semester semester, {required bool isActive}) async {
    final ok = await showDeleteSemesterSheet(
      context,
      semester: semester,
      isActive: isActive,
    );
    if (!context.mounted || !ok) return;
    CoreUtils.showNotification(
      message: 'sessions preserved as ad-hoc activities',
      success: true,
      context: context,
    );
  }

  Future<void> _activate(BuildContext context, Semester semester) async {
    final cubit = context.read<SemestersCubit>();
    final ok = await cubit.activate(id: semester.id);
    if (!context.mounted || !ok) return;
    CoreUtils.showNotification(
      message: '${semester.name.toLowerCase()} is now active',
      success: true,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);

    return Scaffold(
      appBar: const MainAppBar(title: 'terms'),
      body: BlocConsumer<SemestersCubit, SemestersState>(
        listenWhen: (prev, next) =>
            next is SemestersLoaded && next.mutationError != null,
        listener: (context, state) {
          if (state is SemestersLoaded && state.mutationError != null) {
            CoreUtils.showNotification(
              message: state.mutationError!,
              success: false,
              context: context,
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            SemestersInitial() || SemestersLoading() => Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            SemestersError(:final errorMessage) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Text(
                    errorMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(color: softInk),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            SemestersLoaded(:final semesters, :final activeSemester) =>
              _LoadedBody(
                semesters: semesters,
                active: activeSemester,
                onCreate: () =>
                    _create(context, noActiveYet: activeSemester == null),
                onEdit: (s) => _edit(context, s),
                onDelete: (s) => _delete(
                  context,
                  s,
                  isActive: activeSemester?.id == s.id,
                ),
                onActivate: (s) => _activate(context, s),
              ),
          };
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.semesters,
    required this.active,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onActivate,
  });

  final List<Semester> semesters;
  final Semester? active;
  final VoidCallback onCreate;
  final ValueChanged<Semester> onEdit;
  final ValueChanged<Semester> onDelete;
  final ValueChanged<Semester> onActivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);

    if (semesters.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Spacing.lg),
              Text(
                'no terms yet',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'add one to start grouping subjects.',
                style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
              ),
              const Spacer(),
              DefaultButton(
                title: 'add a term',
                fullWidth: true,
                size: ButtonSize.large,
                onPressed: onCreate,
              ),
              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      );
    }

    final pastTerms = semesters
        .where((s) => active == null || s.id != active!.id)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.sm,
                Spacing.lg,
                Spacing.lg,
              ),
              children: [
                if (active != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: Text(
                      'active',
                      style: theme.textTheme.labelSmall?.copyWith(color: softInk),
                    ),
                  ),
                  SemesterCard(
                    semester: active!,
                    isActive: true,
                    onActivate: () {}, // already active
                    onAction: (a) => switch (a) {
                      SemesterCardAction.edit => onEdit(active!),
                      SemesterCardAction.delete => onDelete(active!),
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                if (pastTerms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: Text(
                      'past terms',
                      style: theme.textTheme.labelSmall?.copyWith(color: softInk),
                    ),
                  ),
                  for (final s in pastTerms) ...[
                    SemesterCard(
                      semester: s,
                      isActive: false,
                      onActivate: () => onActivate(s),
                      onAction: (a) => switch (a) {
                        SemesterCardAction.edit => onEdit(s),
                        SemesterCardAction.delete => onDelete(s),
                      },
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              0,
              Spacing.lg,
              Spacing.lg,
            ),
            child: DefaultButton(
              title: 'add a term',
              fullWidth: true,
              size: ButtonSize.large,
              onPressed: onCreate,
            ),
          ),
        ],
      ),
    );
  }
}
