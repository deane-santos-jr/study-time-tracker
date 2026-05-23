import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';

enum ButtonSize { small, medium, large }

/// Visual variant for [DefaultButton]. Default app actions are `primary`
/// (Cocoa Ink pill — see DESIGN.md home tile). `accent` is reserved for
/// celebratory / brand-forward moments (Riso Fig). Use sparingly.
enum ButtonType { primary, secondary, ghost, accent }

/// App-wide button. Cocoa Ink pill in `primary` matches the home-tile
/// pause/start visual and is the default for general actions across the app.
class DefaultButton extends StatelessWidget {
  const DefaultButton({
    super.key,
    required this.title,
    this.onPressed,
    this.fullWidth = false,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.type = ButtonType.primary,
    this.icon,
  });

  final String title;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final bool isLoading;
  final ButtonSize size;
  final ButtonType type;
  final IconData? icon;

  double get _height => switch (size) {
        ButtonSize.small => 40,
        ButtonSize.medium => 48,
        ButtonSize.large => 56,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    // Cocoa Ink pill in light mode flips to a Pulp pill in dark mode so the
    // pill always reads as the high-contrast control against the surface.
    final inkBg = isDark ? kPulp : kCocoaInk;
    final inkFg = isDark ? kCocoaInk : kPulp;

    final Color bg = switch (type) {
      ButtonType.primary => inkBg,
      ButtonType.secondary => scheme.onSurface.withValues(alpha: 0.08),
      ButtonType.ghost => Colors.transparent,
      ButtonType.accent => scheme.primary,
    };
    final Color fg = switch (type) {
      ButtonType.primary => inkFg,
      ButtonType.secondary => scheme.onSurface,
      ButtonType.ghost => scheme.onSurface,
      ButtonType.accent => scheme.onPrimary,
    };

    final label = Text(
      title,
      style: textTheme.labelLarge?.copyWith(
        color: fg,
        fontWeight: FontWeight.w600,
      ),
    );

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        : icon == null
            ? label
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: Spacing.sm),
                  label,
                ],
              );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          disabledForegroundColor: fg.withValues(alpha: 0.7),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.full),
          ),
        ),
        child: child,
      ),
    );
  }
}
