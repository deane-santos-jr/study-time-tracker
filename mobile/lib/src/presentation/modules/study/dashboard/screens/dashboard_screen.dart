import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/analytics/analytics_summary.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/active_session_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/dashboard_stats_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/widgets/session_tile.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/widgets/subject_selector.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/active_semester_pill.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

enum _HomeMenuAction { signOut }

/// "The home screen is a single page that answers what am I doing right now
/// and how was today so far." — DESIGN.md home tile.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _pickedSubjectId;
  bool _adHocMode = false;
  late final TextEditingController _adHocController;

  @override
  void initState() {
    super.initState();
    _adHocController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActiveSessionCubit>().checkActive();
      context.read<DashboardStatsCubit>().load();
    });
  }

  @override
  void dispose() {
    _adHocController.dispose();
    super.dispose();
  }

  Subject? _resolveSubject(SubjectsState subjectsState, String id) {
    if (subjectsState is! SubjectsLoaded) return null;
    for (final s in subjectsState.subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  void _pickSubject(Subject subject) {
    setState(() {
      _pickedSubjectId = subject.id;
      _adHocMode = false;
    });
  }

  void _selectAdHoc() {
    setState(() {
      if (_adHocMode) {
        _adHocMode = false;
        _adHocController.clear();
      } else {
        _adHocMode = true;
        _pickedSubjectId = null;
      }
    });
  }

  Future<void> _start(BuildContext context) async {
    if (_adHocMode) {
      final activity = _adHocController.text.trim();
      if (activity.isEmpty) return;
      await context
          .read<ActiveSessionCubit>()
          .startAdHoc(activityName: activity);
    } else if (_pickedSubjectId != null) {
      await context
          .read<ActiveSessionCubit>()
          .start(subjectId: _pickedSubjectId!);
    }
  }

  Future<void> _pause(BuildContext context) async {
    await context.read<ActiveSessionCubit>().pause();
  }

  Future<void> _resume(BuildContext context) async {
    await context.read<ActiveSessionCubit>().resume();
  }

  Future<void> _stop(BuildContext context) async {
    final cubit = context.read<ActiveSessionCubit>();
    final completed = await cubit.stop();
    if (!context.mounted || completed == null) return;
    context.read<DashboardStatsCubit>().load();
    final mins = ((completed.effectiveStudyTime ?? 0) / 60).round();
    CoreUtils.showNotification(
      message: mins > 0 ? 'nice — $mins min logged' : 'session saved',
      success: true,
      context: context,
    );
    setState(() {
      _pickedSubjectId = null;
      _adHocMode = false;
      _adHocController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: '',
        titleWidget: BlocBuilder<SemestersCubit, SemestersState>(
          builder: (context, state) {
            if (state is! SemestersLoaded) return const SizedBox.shrink();
            final active = state.activeSemester;
            if (active == null) return const SizedBox.shrink();
            return ActiveSemesterPill(semester: active);
          },
        ),
        actions: [
          PopupMenuButton<_HomeMenuAction>(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'more',
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            onSelected: (action) {
              switch (action) {
                case _HomeMenuAction.signOut:
                  context.read<AuthenticationCubit>().logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _HomeMenuAction.signOut,
                child: Text('sign out'),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<ActiveSessionCubit, ActiveSessionState>(
        listenWhen: (prev, next) {
          final prevErr = _mutationErrorOf(prev);
          final nextErr = _mutationErrorOf(next);
          return nextErr != null && nextErr != prevErr;
        },
        listener: (context, state) {
          final err = _mutationErrorOf(state);
          if (err != null) {
            CoreUtils.showNotification(
              message: err,
              success: false,
              context: context,
            );
          }
        },
        builder: (context, sessionState) {
          return BlocBuilder<SubjectsCubit, SubjectsState>(
            builder: (context, subjectsState) {
              return _Body(
                sessionState: sessionState,
                subjectsState: subjectsState,
                pickedSubjectId: _pickedSubjectId,
                adHocMode: _adHocMode,
                adHocController: _adHocController,
                onPickSubject: _pickSubject,
                onSelectAdHoc: _selectAdHoc,
                onStart: () => _start(context),
                onPause: () => _pause(context),
                onResume: () => _resume(context),
                onStop: () => _stop(context),
                onActivityChanged: (_) => setState(() {}),
                resolveSubject: (id) => _resolveSubject(subjectsState, id),
              );
            },
          );
        },
      ),
    );
  }

  String? _mutationErrorOf(ActiveSessionState state) {
    return switch (state) {
      ActiveSessionIdle(:final mutationError) => mutationError,
      ActiveSessionRunning(:final mutationError) => mutationError,
      ActiveSessionPaused(:final mutationError) => mutationError,
      ActiveSessionError(:final errorMessage) => errorMessage,
      _ => null,
    };
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.sessionState,
    required this.subjectsState,
    required this.pickedSubjectId,
    required this.adHocMode,
    required this.adHocController,
    required this.onPickSubject,
    required this.onSelectAdHoc,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onActivityChanged,
    required this.resolveSubject,
  });

  final ActiveSessionState sessionState;
  final SubjectsState subjectsState;
  final String? pickedSubjectId;
  final bool adHocMode;
  final TextEditingController adHocController;
  final ValueChanged<Subject> onPickSubject;
  final VoidCallback onSelectAdHoc;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final ValueChanged<String> onActivityChanged;
  final Subject? Function(String id) resolveSubject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (sessionState is ActiveSessionChecking ||
        sessionState is ActiveSessionInitial) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }
    if (sessionState is ActiveSessionError) {
      return _ErrorBody(
        message: (sessionState as ActiveSessionError).errorMessage,
        onRetry: () => context.read<ActiveSessionCubit>().checkActive(),
      );
    }

    final subjects = subjectsState is SubjectsLoaded
        ? (subjectsState as SubjectsLoaded).subjects
        : const <Subject>[];

    final activeSession = switch (sessionState) {
      ActiveSessionRunning(:final session) => session,
      ActiveSessionPaused(:final session) => session,
      _ => null,
    };
    final activeSubject = activeSession == null || activeSession.subjectId == null
        ? null
        : resolveSubject(activeSession.subjectId!);
    final pickedSubject = pickedSubjectId == null
        ? null
        : resolveSubject(pickedSubjectId!);

    final todaySeconds = _todaySecondsOf(sessionState);
    final todaySubjectCount = _todaySubjectCountOf(sessionState);
    final mutating = _mutatingOf(sessionState);
    final isPaused = sessionState is ActiveSessionPaused;
    final isActive = sessionState is ActiveSessionRunning ||
        sessionState is ActiveSessionPaused;

    final startEnabled = !mutating &&
        !isActive &&
        (adHocMode
            ? adHocController.text.trim().isNotEmpty
            : pickedSubjectId != null);

    final bottomNavReserve = 56 +
        Spacing.md +
        MediaQuery.viewPaddingOf(context).bottom +
        Spacing.md;

    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          bottomNavReserve,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Greeting(),
            const SizedBox(height: Spacing.lg),
            SessionTile(
              activeSession: activeSession,
              activeSubject: activeSubject,
              pickedSubject: pickedSubject,
              adHocMode: adHocMode,
              adHocController: adHocController,
              isPaused: isPaused,
              mutating: mutating,
              onStart: startEnabled ? onStart : null,
              onPause: onPause,
              onResume: onResume,
              onStop: onStop,
              onActivityChanged: onActivityChanged,
            ),
            const SizedBox(height: Spacing.md),
            _StatTilesRow(
              todaySeconds: todaySeconds,
              todaySubjectCount: todaySubjectCount,
            ),
            const SizedBox(height: Spacing.lg),
            if (!isActive)
              _SubjectPickerSection(
                subjects: subjects,
                selectedId: pickedSubjectId,
                adHocSelected: adHocMode,
                onSelect: onPickSubject,
                onSelectAdHoc: onSelectAdHoc,
              ),
            if (isActive) const _SubjectTotalsList(),
          ],
        ),
      ),
    );
  }

  static int _todaySecondsOf(ActiveSessionState s) => switch (s) {
        ActiveSessionIdle(:final todaySeconds) => todaySeconds,
        ActiveSessionRunning(:final todaySeconds) => todaySeconds,
        ActiveSessionPaused(:final todaySeconds) => todaySeconds,
        _ => 0,
      };

  static int _todaySubjectCountOf(ActiveSessionState s) => switch (s) {
        ActiveSessionIdle(:final todaySubjectCount) => todaySubjectCount,
        ActiveSessionRunning(:final todaySubjectCount) => todaySubjectCount,
        ActiveSessionPaused(:final todaySubjectCount) => todaySubjectCount,
        _ => 0,
      };

  static bool _mutatingOf(ActiveSessionState s) => switch (s) {
        ActiveSessionIdle(:final mutating) => mutating,
        ActiveSessionRunning(:final mutating) => mutating,
        ActiveSessionPaused(:final mutating) => mutating,
        _ => false,
      };
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final greeting = _timeOfDayGreeting(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting.', style: theme.textTheme.displayMedium),
        const SizedBox(height: Spacing.xs),
        BlocBuilder<DashboardStatsCubit, DashboardStatsState>(
          builder: (context, state) {
            final streak = state is DashboardStatsLoaded ? state.streakDays : 0;
            final loading = state is DashboardStatsInitial ||
                state is DashboardStatsLoading;
            return Text(
              _streakLine(streak, loading: loading),
              style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
            );
          },
        ),
      ],
    );
  }

  String _timeOfDayGreeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'good morning';
    if (h < 18) return 'good afternoon';
    return 'good evening';
  }

  String _streakLine(int streak, {required bool loading}) {
    if (loading) return '…';
    if (streak == 0) return 'no streak yet — start your first session.';
    if (streak == 1) return 'day one. today is the day to make it two.';
    final next = streak + 1;
    final nextWord = _numberWord(next);
    return "on a $streak-day streak. today's the day to make it $nextWord.";
  }

  static String _numberWord(int n) {
    const words = [
      'zero',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
    ];
    if (n >= 0 && n < words.length) return words[n];
    return n.toString();
  }
}

class _StatTilesRow extends StatelessWidget {
  const _StatTilesRow({
    required this.todaySeconds,
    required this.todaySubjectCount,
  });

  final int todaySeconds;
  final int todaySubjectCount;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardStatsCubit, DashboardStatsState>(
      builder: (context, state) {
        final loaded = state is DashboardStatsLoaded ? state : null;
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'today total',
                value: CoreUtils.formatHm(todaySeconds, dashOnZero: true),
                caption: _todayCaption(todaySubjectCount),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _StatTile(
                label: '7-day window',
                value: CoreUtils.formatHm(
                  loaded?.windowSeconds ?? 0,
                  dashOnZero: true,
                ),
                caption: _windowCaption(loaded),
              ),
            ),
          ],
        );
      },
    );
  }

  String _todayCaption(int subjects) {
    if (todaySeconds == 0) return 'no sessions yet';
    if (subjects <= 1) return 'across 1 focus area';
    return 'across $subjects focus areas';
  }

  String _windowCaption(DashboardStatsLoaded? loaded) {
    if (loaded == null) return '…';
    final window = loaded.windowSeconds;
    final best = loaded.bestWindowSeconds;
    if (window == 0) return 'no sessions yet this week';
    if (best <= window) return 'your best 7-day window';
    final percent = (((best - window) / best) * 100).round();
    return '$percent% under your best';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);

    return PulpTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: softInk)),
          const SizedBox(height: Spacing.xs),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(height: 1.1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            caption,
            style: theme.textTheme.labelSmall?.copyWith(color: softInk),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SubjectTotalsList extends StatelessWidget {
  const _SubjectTotalsList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return BlocBuilder<DashboardStatsCubit, DashboardStatsState>(
      builder: (context, state) {
        if (state is! DashboardStatsLoaded) return const SizedBox.shrink();
        final stats = state.subjectStats.where((s) => s.totalTime > 0).toList();
        final adHocSeconds = state.adHocSeconds;
        if (stats.isEmpty && adHocSeconds == 0) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'your subjects',
              style: theme.textTheme.labelSmall?.copyWith(color: softInk),
            ),
            const SizedBox(height: Spacing.sm),
            for (var i = 0; i < stats.length; i++) ...[
              _SubjectTotalRow(stat: stats[i], brightness: brightness),
              if (i < stats.length - 1 || adHocSeconds > 0)
                Divider(
                  color: ink.withValues(alpha: 0.08),
                  height: 1,
                  thickness: 1,
                ),
            ],
            if (adHocSeconds > 0) _OtherRow(totalSeconds: adHocSeconds),
          ],
        );
      },
    );
  }
}

class _SubjectTotalRow extends StatelessWidget {
  const _SubjectTotalRow({required this.stat, required this.brightness});

  final SubjectStat stat;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<SubjectsCubit, SubjectsState>(
      buildWhen: (a, b) => a.runtimeType != b.runtimeType,
      builder: (context, subjectsState) {
        final color = _colorForSubject(subjectsState).resolve(brightness);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  stat.subjectName,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CoreUtils.formatHm(stat.totalTime, dashOnZero: false),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: InkOpacity.soft),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SubjectColor _colorForSubject(SubjectsState subjectsState) {
    if (subjectsState is SubjectsLoaded) {
      for (final s in subjectsState.subjects) {
        if (s.id == stat.subjectId) return SubjectColor.fromHex(s.color);
      }
    }
    return SubjectColor.risoFig;
  }
}

class _OtherRow extends StatelessWidget {
  const _OtherRow({required this.totalSeconds});

  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text('other', style: theme.textTheme.bodyLarge),
          ),
          Text(
            CoreUtils.formatHm(totalSeconds, dashOnZero: false),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: ink.withValues(alpha: InkOpacity.soft),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectPickerSection extends StatelessWidget {
  const _SubjectPickerSection({
    required this.subjects,
    required this.selectedId,
    required this.adHocSelected,
    required this.onSelect,
    required this.onSelectAdHoc,
  });

  final List<Subject> subjects;
  final String? selectedId;
  final bool adHocSelected;
  final ValueChanged<Subject> onSelect;
  final VoidCallback onSelectAdHoc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'your subjects',
          style: theme.textTheme.labelSmall?.copyWith(color: softInk),
        ),
        const SizedBox(height: Spacing.sm),
        SubjectSelector(
          subjects: subjects,
          selectedId: selectedId,
          adHocSelected: adHocSelected,
          onSelect: onSelect,
          onSelectAdHoc: onSelectAdHoc,
        ),
      ],
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
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 48,
              ),
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
