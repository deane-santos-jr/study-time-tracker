import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/dashboard_stats_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/delete_semester_sheet.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/semester_form_sheet.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/widgets/subject_tile.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';

enum _TermAction { edit, delete }

/// Unified terms screen: term selector chip row on top, the selected term's
/// subjects below. All subject CRUD is gated through "edit term" — per
/// ADR-0015, subjects belong to a term, so the term owns their lifecycle.
class SemestersScreen extends StatefulWidget {
  const SemestersScreen({super.key});

  @override
  State<SemestersScreen> createState() => _SemestersScreenState();
}

class _SemestersScreenState extends State<SemestersScreen> {
  String? _selectedTermId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SemestersCubit>().load();
      final stats = context.read<DashboardStatsCubit>();
      if (stats.state is DashboardStatsInitial) {
        stats.load();
      }
    });
  }

  /// Default to the active term when the user hasn't picked one, falling back
  /// to the first term in the (active-first, then start-date-desc) order.
  Semester _resolveSelected(SemestersLoaded state, List<Semester> ordered) {
    final id = _selectedTermId;
    if (id != null) {
      for (final s in ordered) {
        if (s.id == id) return s;
      }
    }
    if (state.activeSemester != null) return state.activeSemester!;
    return ordered.first;
  }

  List<Semester> _orderedTerms(SemestersLoaded state) {
    final active = state.activeSemester;
    final past = state.semesters
        .where((s) => active == null || s.id != active.id)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return [?active, ...past];
  }

  Future<void> _createTerm(
    BuildContext context, {
    required bool noActiveYet,
  }) async {
    final result =
        await showSemesterFormSheet(context, noActiveYet: noActiveYet);
    if (!context.mounted || result == null || result.create == null) return;
    final cubit = context.read<SemestersCubit>();
    final created = await cubit.create(payload: result.create!);
    if (!context.mounted || created == null) return;
    if (result.makeActive && !created.isActive) {
      await cubit.activate(id: created.id);
    }
    if (!context.mounted) return;
    setState(() => _selectedTermId = created.id);
    final msg = result.makeActive
        ? '${created.name.toLowerCase()} is now your active term'
        : '${created.name.toLowerCase()} added';
    CoreUtils.showNotification(message: msg, success: true, context: context);
  }

  Future<void> _editTerm(BuildContext context, Semester term) async {
    final result = await showSemesterFormSheet(
      context,
      editing: term,
      noActiveYet: false,
    );
    if (!context.mounted || result == null || result.update == null) return;
    await context
        .read<SemestersCubit>()
        .update(id: term.id, payload: result.update!);
  }

  Future<void> _activateTerm(BuildContext context, Semester term) async {
    final ok = await context.read<SemestersCubit>().activate(id: term.id);
    if (!context.mounted || !ok) return;
    CoreUtils.showNotification(
      message: '${term.name.toLowerCase()} is now active',
      success: true,
      context: context,
    );
  }

  Future<void> _deleteTerm(
    BuildContext context,
    Semester term, {
    required bool isActive,
  }) async {
    final ok = await showDeleteSemesterSheet(
      context,
      semester: term,
      isActive: isActive,
    );
    if (!context.mounted || !ok) return;
    setState(() {
      if (_selectedTermId == term.id) _selectedTermId = null;
    });
    CoreUtils.showNotification(
      message: 'sessions preserved as ad-hoc activities',
      success: true,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk =
        theme.colorScheme.onSurface.withValues(alpha: InkOpacity.soft);

    return Scaffold(
      appBar: MainAppBar(
        title: 'terms',
        actions: [
          BlocBuilder<SemestersCubit, SemestersState>(
            builder: (context, state) {
              if (state is! SemestersLoaded || state.semesters.isEmpty) {
                return const SizedBox.shrink();
              }
              final ordered = _orderedTerms(state);
              final selected = _resolveSelected(state, ordered);
              final isActive = state.activeSemesterId == selected.id;
              return PopupMenuButton<_TermAction>(
                icon: Icon(Icons.more_horiz_rounded, color: softInk),
                tooltip: 'more',
                position: PopupMenuPosition.under,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                onSelected: (action) {
                  switch (action) {
                    case _TermAction.edit:
                      _editTerm(context, selected);
                    case _TermAction.delete:
                      _deleteTerm(context, selected, isActive: isActive);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _TermAction.edit,
                    child: Text('edit term'),
                  ),
                  const PopupMenuItem(
                    value: _TermAction.delete,
                    child: Text('delete term'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
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
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: softInk),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            SemestersLoaded() => _buildLoaded(context, state),
          };
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, SemestersLoaded state) {
    if (state.semesters.isEmpty) {
      return _EmptyBody(onCreate: () => _createTerm(context, noActiveYet: true));
    }
    final ordered = _orderedTerms(state);
    final selected = _resolveSelected(state, ordered);
    return _LoadedBody(
      ordered: ordered,
      selected: selected,
      activeId: state.activeSemesterId,
      onSelectTerm: (id) => setState(() => _selectedTermId = id),
      onCreateTerm: () => _createTerm(
        context,
        noActiveYet: state.activeSemesterId == null,
      ),
      onEditTerm: () => _editTerm(context, selected),
      onActivate: () => _activateTerm(context, selected),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk =
        theme.colorScheme.onSurface.withValues(alpha: InkOpacity.soft);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: Spacing.lg),
            Text('no terms yet', style: theme.textTheme.displaySmall),
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
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.ordered,
    required this.selected,
    required this.activeId,
    required this.onSelectTerm,
    required this.onCreateTerm,
    required this.onEditTerm,
    required this.onActivate,
  });

  final List<Semester> ordered;
  final Semester selected;
  final String? activeId;
  final ValueChanged<String> onSelectTerm;
  final VoidCallback onCreateTerm;
  final VoidCallback onEditTerm;
  final VoidCallback onActivate;

  static const _months = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  String _formatRange(DateTime start, DateTime end) {
    final s = '${_months[start.month - 1]} ${start.day}';
    final e = '${_months[end.month - 1]} ${end.day}';
    return '$s – $e';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk =
        theme.colorScheme.onSurface.withValues(alpha: InkOpacity.soft);
    final isActive = activeId == selected.id;

    return SafeArea(
      child: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          final sems = context.read<SemestersCubit>();
          final subs = context.read<SubjectsCubit>();
          final stats = context.read<DashboardStatsCubit>();
          await Future.wait([sems.load(), subs.load()]);
          if (context.mounted) await stats.load();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.lg),
          children: [
            _TermChipRow(
              ordered: ordered,
              selectedId: selected.id,
              activeId: activeId,
              onSelect: onSelectTerm,
              onCreate: onCreateTerm,
            ),
            const SizedBox(height: Spacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatRange(selected.startDate, selected.endDate),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: softInk),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kHoneyed.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(Radii.full),
                      ),
                      child: Text(
                        'active',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: kHoneyed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    _MakeActivePill(onTap: onActivate),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: _SubjectsSection(
                termId: selected.id,
                onEditTerm: onEditTerm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermChipRow extends StatelessWidget {
  const _TermChipRow({
    required this.ordered,
    required this.selectedId,
    required this.activeId,
    required this.onSelect,
    required this.onCreate,
  });

  final List<Semester> ordered;
  final String selectedId;
  final String? activeId;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        itemCount: ordered.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
        itemBuilder: (_, i) {
          if (i == ordered.length) {
            return _NewTermChip(onTap: onCreate);
          }
          final term = ordered[i];
          return _TermChip(
            label: term.name.toLowerCase(),
            selected: term.id == selectedId,
            active: term.id == activeId,
            onTap: () => onSelect(term.id),
          );
        },
      ),
    );
  }
}

class _TermChip extends StatelessWidget {
  const _TermChip({
    required this.label,
    required this.selected,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    // Selected chip flips to the same Cocoa-Ink-on-Pulp inversion the bottom
    // nav uses, so "currently viewing" reads as a single dark sliver.
    final bg = selected
        ? (brightness == Brightness.dark ? kPulp : kCocoaInk)
        : theme.colorScheme.surfaceContainer;
    final fg = selected
        ? (brightness == Brightness.dark ? kCocoaInk : kPulp)
        : theme.colorScheme.onSurface;
    final dotColor = brightness == Brightness.dark ? kHoneyedNight : kHoneyed;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.full),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(Radii.full),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFontGeist,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg,
                      height: 1.0,
                    ),
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cocoa Ink pill shown in the term metadata row when the viewed term isn't
/// the active one. Sized to match the "active" honey badge it replaces so the
/// row height stays stable when toggling between terms.
class _MakeActivePill extends StatelessWidget {
  const _MakeActivePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final bg = brightness == Brightness.dark ? kPulp : kCocoaInk;
    final fg = brightness == Brightness.dark ? kCocoaInk : kPulp;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Radii.full),
          ),
          child: Text(
            'make active',
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewTermChip extends StatelessWidget {
  const _NewTermChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(Radii.full),
          ),
          alignment: Alignment.center,
          child: Text(
            '+ new',
            style: TextStyle(
              fontFamily: kFontGeist,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: softInk,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectsSection extends StatelessWidget {
  const _SubjectsSection({required this.termId, required this.onEditTerm});

  final String termId;
  final VoidCallback onEditTerm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk =
        theme.colorScheme.onSurface.withValues(alpha: InkOpacity.soft);

    return BlocBuilder<SubjectsCubit, SubjectsState>(
      builder: (context, subjectsState) {
        if (subjectsState is SubjectsInitial ||
            subjectsState is SubjectsLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }
        if (subjectsState is SubjectsError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
            child: Text(
              subjectsState.errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(color: softInk),
              textAlign: TextAlign.center,
            ),
          );
        }

        final loaded = subjectsState as SubjectsLoaded;
        final termSubjects =
            loaded.subjects.where((s) => s.semesterId == termId).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              termSubjects.isEmpty
                  ? 'subjects'
                  : termSubjects.length == 1
                      ? '1 subject'
                      : '${termSubjects.length} subjects',
              style: theme.textTheme.labelSmall?.copyWith(color: softInk),
            ),
            const SizedBox(height: Spacing.sm),
            if (termSubjects.isEmpty)
              _EmptySubjects(onEditTerm: onEditTerm)
            else
              BlocBuilder<DashboardStatsCubit, DashboardStatsState>(
                builder: (context, statsState) {
                  final loadingStats = statsState is DashboardStatsInitial ||
                      statsState is DashboardStatsLoading;
                  final totalsBySubject = <String, int>{
                    if (statsState is DashboardStatsLoaded)
                      for (final s in statsState.subjectStats)
                        s.subjectId: s.totalTime,
                  };
                  return Column(
                    children: [
                      for (var i = 0; i < termSubjects.length; i++) ...[
                        SubjectTile(
                          subject: termSubjects[i],
                          semester: null,
                          totalSeconds: totalsBySubject[termSubjects[i].id],
                          loadingTotal: loadingStats,
                        ),
                        if (i < termSubjects.length - 1)
                          const SizedBox(height: Spacing.sm),
                      ],
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects({required this.onEditTerm});

  final VoidCallback onEditTerm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk =
        theme.colorScheme.onSurface.withValues(alpha: InkOpacity.soft);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'no subjects in this term yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'edit the term to add subjects.',
            style: theme.textTheme.bodyMedium?.copyWith(color: softInk),
          ),
          const SizedBox(height: Spacing.md),
          DefaultButton(
            title: 'edit term',
            fullWidth: true,
            size: ButtonSize.large,
            onPressed: onEditTerm,
          ),
        ],
      ),
    );
  }
}
