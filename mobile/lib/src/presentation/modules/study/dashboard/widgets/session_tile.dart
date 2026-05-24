import 'dart:async';

import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

/// Home-tile session card. Two idle paths now: subject-picked (chip slot shows
/// the subject chip + color dot) and ad-hoc (chip slot becomes an inline
/// text field). One running path: subject sessions show the chip; ad-hoc
/// sessions show the activity name as plain Cocoa Ink text (absence of
/// color is the ad-hoc signal).
class SessionTile extends StatefulWidget {
  const SessionTile({
    super.key,
    required this.activeSession,
    required this.activeSubject,
    required this.pickedSubject,
    required this.adHocMode,
    required this.adHocController,
    required this.isPaused,
    required this.mutating,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onActivityChanged,
    required this.onToggleAdHoc,
  });

  final StudySession? activeSession;
  final Subject? activeSubject;
  final Subject? pickedSubject;

  /// True when the user has tapped the "or start an independent activity"
  /// link below the start button.
  final bool adHocMode;

  /// Owned by the parent so re-builds don't destroy in-flight text. The
  /// parent reads `controller.text.trim()` when wiring [onStart].
  final TextEditingController adHocController;

  final bool isPaused;
  final bool mutating;

  /// Null when start is disabled (no subject picked AND not in ad-hoc mode
  /// with non-empty text, or already mutating).
  final VoidCallback? onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  /// Fires on every text change in the ad-hoc input. Parent updates start
  /// button enabled state based on `text.trim().isNotEmpty`.
  final ValueChanged<String> onActivityChanged;

  /// Toggles ad-hoc mode (the snippet below the start button). When entering
  /// ad-hoc, the parent also clears the picked subject; leaving ad-hoc clears
  /// the activity-name input.
  final VoidCallback onToggleAdHoc;

  @override
  State<SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<SessionTile> {
  bool get _isActive => widget.activeSession != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final brightness = theme.brightness;

    final displaySubject = widget.activeSubject ?? widget.pickedSubject;
    final accent = displaySubject == null
        ? null
        : SubjectColor.fromHex(displaySubject.color).resolve(brightness);

    final activeIsAdHoc = widget.activeSession?.isAdHoc ?? false;

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
            isPaused: widget.isPaused,
            adHocMode: widget.adHocMode && !_isActive,
            adHocLabel: activeIsAdHoc
                ? widget.activeSession!.activityName ?? ''
                : null,
            adHocController: widget.adHocController,
            onActivityChanged: widget.onActivityChanged,
          ),
          const SizedBox(height: Spacing.lg),
          Center(child: _TimerLine(session: widget.activeSession)),
          const SizedBox(height: Spacing.sm),
          Center(
            child: Text(
              _subtitle(
                widget.activeSession,
                isPaused: widget.isPaused,
                hasPick: widget.pickedSubject != null,
                adHocMode: widget.adHocMode,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ink.withValues(alpha: InkOpacity.soft),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          DefaultButton(
            title: _actionLabel(isActive: _isActive, isPaused: widget.isPaused),
            fullWidth: true,
            size: ButtonSize.large,
            isLoading: widget.mutating,
            onPressed: _resolveAction(),
          ),
          if (_isActive) ...[
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: widget.mutating ? null : widget.onStop,
              style: TextButton.styleFrom(
                foregroundColor: ink.withValues(alpha: InkOpacity.soft),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
              ),
              child: const Text('end session'),
            ),
          ] else ...[
            const SizedBox(height: Spacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.mutating ? null : widget.onToggleAdHoc,
                style: TextButton.styleFrom(
                  foregroundColor: ink.withValues(alpha: InkOpacity.soft),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.xs,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: theme.textTheme.labelSmall,
                ),
                child: Text(
                  widget.adHocMode
                      ? 'use a subject instead'
                      : '+ independent activity',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  VoidCallback? _resolveAction() {
    if (widget.mutating) return null;
    if (_isActive) return widget.isPaused ? widget.onResume : widget.onPause;
    return widget.onStart;
  }

  String _actionLabel({required bool isActive, required bool isPaused}) {
    if (isActive) return isPaused ? 'resume' : 'pause';
    return 'start';
  }

  String _subtitle(
    StudySession? session, {
    required bool isPaused,
    required bool hasPick,
    required bool adHocMode,
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
    if (adHocMode) return 'name your activity, then start';
    return hasPick ? 'ready when you are' : 'tap a subject below to start';
  }
}

class _TileHeader extends StatelessWidget {
  const _TileHeader({
    required this.subject,
    required this.accent,
    required this.isActive,
    required this.isPaused,
    required this.adHocMode,
    required this.adHocLabel,
    required this.adHocController,
    required this.onActivityChanged,
  });

  final Subject? subject;
  final Color? accent;
  final bool isActive;
  final bool isPaused;

  /// True when in idle ad-hoc input mode.
  final bool adHocMode;

  /// Non-null when there's a running ad-hoc session; renders the activity
  /// name as plain Cocoa Ink text (no chip, no color dot).
  final String? adHocLabel;

  final TextEditingController adHocController;
  final ValueChanged<String> onActivityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    Widget leading;
    if (adHocMode) {
      leading = Expanded(
        child: _AdHocInput(
          controller: adHocController,
          onChanged: onActivityChanged,
        ),
      );
    } else if (adHocLabel != null && isActive) {
      // Running ad-hoc — plain text, no chip, no dot.
      leading = Expanded(
        child: Text(
          adHocLabel!.toLowerCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(color: ink),
        ),
      );
    } else if (subject != null && accent != null) {
      leading = _SubjectChip(name: subject!.name, color: accent!);
    } else {
      leading = Expanded(
        child: Text(
          isActive ? 'session' : 'no subject picked',
          style: theme.textTheme.labelSmall?.copyWith(color: softInk),
        ),
      );
    }

    return Row(
      children: [
        leading,
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

class _AdHocInput extends StatelessWidget {
  const _AdHocInput({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    return TextField(
      controller: controller,
      autofocus: true,
      maxLength: 100,
      textInputAction: TextInputAction.done,
      style: theme.textTheme.titleMedium?.copyWith(color: ink),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'what are you doing?',
        hintStyle: theme.textTheme.titleMedium?.copyWith(
          color: ink.withValues(alpha: InkOpacity.faint),
        ),
        counterText: '',
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
