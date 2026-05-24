import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

/// Sits where the dashboard subject list would render when the active term has
/// no subjects. Surfaces the right next step so a fresh dashboard isn't a void.
class SubjectsEmptyHint extends StatelessWidget {
  const SubjectsEmptyHint({super.key, required this.hasActiveTerm});

  final bool hasActiveTerm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk =
        theme.colorScheme.onSurface.withValues(alpha: InkOpacity.soft);

    final title =
        hasActiveTerm ? 'no subjects in this term yet' : 'no subjects yet';
    final body = hasActiveTerm
        ? 'open the menu to manage the term and add subjects.'
        : "add a term first to start grouping subjects. tap '+ add a term' above, or use the menu.";

    return PulpTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.xs),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(color: softInk),
          ),
        ],
      ),
    );
  }
}
