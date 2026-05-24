import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';

class ActiveSemesterPill extends StatelessWidget {
  const ActiveSemesterPill({
    super.key,
    this.semester,
    this.isLoading = false,
  });

  /// Null when there's no active term — pill renders the "+ add a term"
  /// affordance and still routes to /semesters on tap.
  final Semester? semester;

  /// True while semesters are still loading. Renders a non-interactive
  /// "…" placeholder so the title doesn't flash empty.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final bg = theme.colorScheme.surfaceContainer;

    final String label;
    if (isLoading) {
      label = '…';
    } else if (semester != null) {
      label = semester!.name.toLowerCase();
    } else {
      label = '+ add a term';
    }

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
          label,
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
