import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

enum SemesterCardAction { edit, delete }

class SemesterCard extends StatelessWidget {
  const SemesterCard({
    super.key,
    required this.semester,
    required this.isActive,
    required this.onActivate,
    required this.onAction,
  });

  final Semester semester;
  final bool isActive;
  final VoidCallback onActivate;
  final ValueChanged<SemesterCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return PulpTile(
      onTap: isActive ? null : onActivate,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  semester.name.toLowerCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  _formatRange(semester.startDate, semester.endDate),
                  style: theme.textTheme.labelMedium?.copyWith(color: softInk),
                ),
              ],
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: Spacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            ),
          ],
          PopupMenuButton<SemesterCardAction>(
            icon: Icon(Icons.more_horiz_rounded, color: softInk),
            tooltip: 'more',
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            onSelected: onAction,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: SemesterCardAction.edit,
                child: Text('edit'),
              ),
              PopupMenuItem(
                value: SemesterCardAction.delete,
                child: Text('delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _months = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  String _formatRange(DateTime start, DateTime end) {
    final s = '${_months[start.month - 1]} ${start.day}';
    final e = '${_months[end.month - 1]} ${end.day}';
    return '$s – $e';
  }
}
