import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';

/// Vertical list of subject rows for the idle dashboard. Each row is a
/// full-width tappable target (color dot + name + a soft check on selection),
/// so picking what to study reads like ticking a checkbox in a notebook rather
/// than scanning a row of chips. Ad-hoc entry lives below the start button on
/// the session tile, not in this list.
class SubjectSelector extends StatelessWidget {
  const SubjectSelector({
    super.key,
    required this.subjects,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Subject> subjects;
  final String? selectedId;
  final ValueChanged<Subject> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final ink = theme.colorScheme.onSurface;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: subjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.xs),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final brand =
            SubjectColor.fromHex(subject.color).resolve(brightness);
        final isSelected = subject.id == selectedId;

        return Material(
          color: isSelected
              ? brand.withValues(alpha: 0.08)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
            side: BorderSide(
              color: isSelected
                  ? brand
                  : ink.withValues(alpha: InkOpacity.hint),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.md),
            onTap: () => onSelect(subject),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      subject.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isSelected ? brand : ink,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_rounded, color: brand, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
