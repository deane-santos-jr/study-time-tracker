import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';

class ActiveSemesterPill extends StatelessWidget {
  const ActiveSemesterPill({super.key, required this.semester});

  /// Null while semesters are still loading. Renders the `"…"` placeholder
  /// in that case, with no tap target.
  final Semester? semester;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final bg = theme.colorScheme.surfaceContainer;

    final label = semester?.name ?? '…';
    final isLoading = semester == null;

    final pill = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 32,
        maxWidth: 200,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.full),
        ),
        alignment: Alignment.center,
        child: Text(
          label.toLowerCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: kFontGeist,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ink,
            height: 1.0,
          ),
        ),
      ),
    );

    if (isLoading) return pill;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.full),
      child: InkWell(
        onTap: () => context.push('/semesters'),
        borderRadius: BorderRadius.circular(Radii.full),
        child: pill,
      ),
    );
  }
}
