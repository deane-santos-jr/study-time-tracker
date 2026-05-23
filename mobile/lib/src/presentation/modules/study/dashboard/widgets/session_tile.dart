import 'dart:async';

import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

/// Home tile's central card per DESIGN.md "in-app — the home tile".
///
/// Renders both states (active session or idle "ready to start") so the
/// layout stays identical across the dashboard's two modes. Only the card's
/// contents change — chip, timer, subtitle, and action row swap with the
/// session state.
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.activeSession,
    required this.activeSubject,
    required this.pickedSubject,
    required this.isPaused,
    required this.mutating,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  /// Non-null when a session is running or paused.
  final StudySession? activeSession;

  /// Subject for the active session (already resolved by the screen).
  final Subject? activeSubject;

  /// Subject the user has tapped in the idle picker, if any.
  final Subject? pickedSubject;

  final bool isPaused;
  final bool mutating;

  /// Null when start is disabled (no subject picked or already mutating).
  final VoidCallback? onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  bool get _isActive => activeSession != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final brightness = theme.brightness;

    final displaySubject = activeSubject ?? pickedSubject;
    final accent = displaySubject == null
        ? null
        : SubjectColor.fromHex(displaySubject.color).resolve(brightness);

    return PulpTile(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TileHeader(
            subject: displaySubject,
            accent: accent,
            isActive: _isActive,
            isPaused: isPaused,
          ),
          const SizedBox(height: Spacing.lg),
          Center(
            child: _TimerLine(session: activeSession),
          ),
          const SizedBox(height: Spacing.sm),
          Center(
            child: Text(
              _subtitle(activeSession, isPaused: isPaused, hasPick: pickedSubject != null),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ink.withValues(alpha: InkOpacity.soft),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          DefaultButton(
            title: _actionLabel(isActive: _isActive, isPaused: isPaused),
            fullWidth: true,
            size: ButtonSize.large,
            isLoading: mutating,
            onPressed: _resolveAction(),
          ),
          if (_isActive) ...[
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: mutating ? null : onStop,
              style: TextButton.styleFrom(
                foregroundColor: ink.withValues(alpha: InkOpacity.soft),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
              ),
              child: const Text('end session'),
            ),
          ],
        ],
      ),
    );
  }

  VoidCallback? _resolveAction() {
    if (mutating) return null;
    if (_isActive) return isPaused ? onResume : onPause;
    return onStart;
  }

  String _actionLabel({required bool isActive, required bool isPaused}) {
    if (isActive) return isPaused ? 'resume' : 'pause';
    return 'start';
  }

  String _subtitle(
    StudySession? session, {
    required bool isPaused,
    required bool hasPick,
  }) {
    if (session != null) {
      if (isPaused) return 'paused';
      final breaks = session.breakCount;
      final breaksLine = breaks == 0
          ? 'no breaks yet'
          : breaks == 1
              ? '1 break taken'
              : '$breaks breaks taken';
      return 'effective focus · $breaksLine';
    }
    return hasPick ? 'ready when you are' : 'tap a subject below to start';
  }
}

class _TileHeader extends StatelessWidget {
  const _TileHeader({
    required this.subject,
    required this.accent,
    required this.isActive,
    required this.isPaused,
  });

  final Subject? subject;
  final Color? accent;
  final bool isActive;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return Row(
      children: [
        if (subject != null && accent != null)
          _SubjectChip(name: subject!.name, color: accent!)
        else
          Expanded(
            child: Text(
              isActive ? 'session' : 'no subject picked',
              style: theme.textTheme.labelSmall?.copyWith(color: softInk),
            ),
          ),
        const Spacer(),
        if (isActive)
          _LiveIndicator(isPaused: isPaused)
        else
          Text(
            'ready',
            style: theme.textTheme.labelSmall?.copyWith(color: softInk),
          ),
      ],
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final tintBg = brightness == Brightness.dark
        ? color.withValues(alpha: 0.20)
        : color.withValues(alpha: 0.16);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tintBg,
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            name.toLowerCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator({required this.isPaused});

  final bool isPaused;

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);
    if (widget.isPaused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: softInk,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'paused',
            style: theme.textTheme.labelSmall?.copyWith(color: softInk),
          ),
        ],
      );
    }
    // Live state: tiny dot in Matcha (universal "session in progress")
    // softly fading in and out — restrained per DESIGN.md anti-slop rules.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.45 + 0.55 * _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: kMatchaStain.withValues(alpha: alpha),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'live',
              style: theme.textTheme.labelSmall?.copyWith(color: softInk),
            ),
          ],
        );
      },
    );
  }
}

class _TimerLine extends StatefulWidget {
  const _TimerLine({required this.session});

  final StudySession? session;

  @override
  State<_TimerLine> createState() => _TimerLineState();
}

class _TimerLineState extends State<_TimerLine> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(_TimerLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session?.status != widget.session?.status ||
        oldWidget.session?.id != widget.session?.id) {
      _syncTicker();
    }
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (widget.session?.status == SessionStatus.active) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final session = widget.session;
    final seconds =
        session == null ? 0 : session.effectiveElapsedAt(DateTime.now());
    final color = session == null
        ? ink.withValues(alpha: InkOpacity.faint)
        : ink;
    return Text(
      _format(seconds),
      style: TextStyle(
        fontFamily: kFontGeistMono,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w600,
        fontSize: 48,
        height: 1.0,
        letterSpacing: -0.5,
        color: color,
      ),
    );
  }

  String _format(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

