import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/presentation/modules/history/services/history_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HistoryCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);

    return Scaffold(
      appBar: const MainAppBar(title: 'history'),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          return switch (state) {
            HistoryInitial() || HistoryLoading() => Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            HistoryError(:final errorMessage) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Text(
                    errorMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(color: softInk),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            HistoryLoaded(:final sessions) => _LoadedBody(sessions: sessions),
          };
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.sessions});

  final List<StudySession> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);
    final bottomReserve = 56 +
        Spacing.md +
        MediaQuery.viewPaddingOf(context).bottom +
        Spacing.md;

    if (sessions.isEmpty) {
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
                "no sessions yet",
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'start a session from the home tab — it lands here when it ends.',
                style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: () => context.read<HistoryCubit>().load(),
      child: BlocBuilder<SubjectsCubit, SubjectsState>(
        builder: (context, subjectsState) {
          final subjectsById = <String, Subject>{
            if (subjectsState is SubjectsLoaded)
              for (final s in subjectsState.subjects) s.id: s,
          };
          final count = sessions.length;
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              bottomReserve,
            ),
            itemCount: sessions.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: Spacing.xs,
                    bottom: Spacing.xs,
                  ),
                  child: Text(
                    count == 1 ? '1 session' : '$count sessions',
                    style: theme.textTheme.labelSmall?.copyWith(color: softInk),
                  ),
                );
              }
              final session = sessions[index - 1];
              final subject = session.subjectId == null
                  ? null
                  : subjectsById[session.subjectId];
              return _SessionRow(session: session, subject: subject);
            },
          );
        },
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.subject});

  final StudySession session;
  final Subject? subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final faintInk = ink.withValues(alpha: InkOpacity.faint);
    final isAdHoc = session.subjectId == null;
    final dotColor = isAdHoc
        ? ink.withValues(alpha: 0.18)
        : (subject != null
            ? SubjectColor.fromHex(subject!.color).resolve(brightness)
            : ink.withValues(alpha: 0.18));
    final label = isAdHoc
        ? session.adHocLabel
        : subject?.name ?? 'unknown subject';
    final seconds = session.effectiveStudyTime ?? 0;

    return PulpTile(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toLowerCase(),
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.xxs),
                Text(
                  '${CoreUtils.formatDate(session.startTime)} • '
                  '${CoreUtils.formatTime(session.startTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: faintInk),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            seconds > 0
                ? CoreUtils.formatHm(seconds)
                : _statusLabel(session.status),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: softInk,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(SessionStatus status) => switch (status) {
        SessionStatus.active => 'running',
        SessionStatus.paused => 'paused',
        SessionStatus.completed => '—',
      };
}
