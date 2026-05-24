import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';

/// Top app bar styled per Warm Studygram (Pulp surface, Fraunces italic title).
/// Title-styling here is intentional — the global `appBarTheme` provides the
/// Fraunces default, but this widget exists so screens can pass `actions` and
/// still get a single visual baseline without each screen writing its own bar.
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
  });

  final String title;

  /// Overrides the [title] string with an arbitrary widget. Used by the
  /// dashboard to slot in the ActiveSemesterPill conditionally.
  final Widget? titleWidget;

  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ??
          Text(
            title,
            style: TextStyle(
              fontFamily: kFontFraunces,
              fontStyle: FontStyle.italic,
              fontSize: 22,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
      actions: actions,
    );
  }
}
