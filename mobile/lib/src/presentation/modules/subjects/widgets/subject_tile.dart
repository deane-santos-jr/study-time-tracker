import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

/// Subject row composed from home-tile primitives: borderless [PulpTile]
/// (cream `surfaceContainer`), rounded color square that matches the
/// dashboard "your subjects" list, name in bodyLarge ink, semester caption
/// in faint ink, lifetime total on the right in tabular figures.
class SubjectTile extends StatelessWidget {
  const SubjectTile({
    super.key,
    required this.subject,
    required this.semester,
    this.onTap,
    this.onDelete,
    this.totalSeconds,
    this.loadingTotal = false,
  });

  final Subject subject;
  final Semester? semester;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  /// Lifetime effective study time for the subject in seconds, or `null` if
  /// the user has no sessions yet (no row in `subjectStats`).
  final int? totalSeconds;

  /// True while analytics are still loading — renders a subtle placeholder
  /// instead of "—" so the tile doesn't flash empty on first paint.
  final bool loadingTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final brand = SubjectColor.fromHex(subject.color).resolve(brightness);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final faintInk = ink.withValues(alpha: InkOpacity.faint);

    return PulpTile(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: brand,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (semester != null) ...[
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    semester!.name,
                    style: theme.textTheme.bodySmall?.copyWith(color: faintInk),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          _TotalLabel(
            seconds: totalSeconds,
            loading: loadingTotal,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: softInk,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w500,
            ),
            faintStyle: theme.textTheme.bodySmall?.copyWith(color: faintInk),
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: softInk),
              tooltip: 'delete subject',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _TotalLabel extends StatelessWidget {
  const _TotalLabel({
    required this.seconds,
    required this.loading,
    required this.style,
    required this.faintStyle,
  });

  final int? seconds;
  final bool loading;
  final TextStyle? style;
  final TextStyle? faintStyle;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Text('…', style: faintStyle);
    }
    if (seconds == null || seconds! <= 0) {
      return Text('no time yet', style: faintStyle);
    }
    return Text(CoreUtils.formatHm(seconds!), style: style);
  }
}
