import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';

/// Sentinel callback fired when the user taps the "+ something else" row.
/// The parent decides what to do (typically: switch the session-tile chip
/// slot into an input field).
typedef AdHocSelectCallback = void Function();

/// Vertical list of subject rows for the idle dashboard. Each row is a
/// full-width tappable target (color dot + name + a soft check on selection),
/// so picking what to study reads like ticking a checkbox in a notebook rather
/// than scanning a row of chips. The last row is always "+ something else" —
/// the ad-hoc escape valve.
class SubjectSelector extends StatelessWidget {
  const SubjectSelector({
    super.key,
    required this.subjects,
    required this.selectedId,
    required this.adHocSelected,
    required this.onSelect,
    required this.onSelectAdHoc,
  });

  final List<Subject> subjects;
  final String? selectedId;
  final bool adHocSelected;
  final ValueChanged<Subject> onSelect;
  final AdHocSelectCallback onSelectAdHoc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final ink = theme.colorScheme.onSurface;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: subjects.length + 1, // +1 for the ad-hoc row
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.xs),
      itemBuilder: (context, index) {
        if (index == subjects.length) {
          return _AdHocRow(
            isSelected: adHocSelected,
            onTap: onSelectAdHoc,
          );
        }

        final subject = subjects[index];
        final brand =
            SubjectColor.fromHex(subject.color).resolve(brightness);
        final isSelected = subject.id == selectedId && !adHocSelected;

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

class _AdHocRow extends StatelessWidget {
  const _AdHocRow({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return Material(
      color: isSelected
          ? ink.withValues(alpha: 0.06)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(
          color: isSelected ? ink : ink.withValues(alpha: InkOpacity.hint),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 16, color: softInk),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  'something else',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected ? ink : softInk,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, color: ink, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
