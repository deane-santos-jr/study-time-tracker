import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';

/// Chip row of the six curated brand colors (ADR-0011). Replaces the
/// arbitrary hex picker the React frontend uses — subjects must pick from
/// this palette so mascot / share-card backgrounds always harmonize.
class SubjectColorPicker extends StatelessWidget {
  const SubjectColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SubjectColor selected;
  final ValueChanged<SubjectColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final ink = Theme.of(context).colorScheme.onSurface;

    return Wrap(
      spacing: Spacing.md,
      runSpacing: Spacing.sm,
      children: [
        for (final color in SubjectColor.values)
          _ColorSwatch(
            color: color.resolve(brightness),
            label: color.label,
            isSelected: color == selected,
            ringColor: ink,
            onTap: () => onChanged(color),
          ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.ringColor,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool isSelected;
  final Color ringColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 44.0 : 36.0;
    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.short,
          curve: Motion.move,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: ringColor, width: 2)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ringColor.withValues(alpha: 0.08),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
