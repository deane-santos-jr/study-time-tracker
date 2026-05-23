import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';

/// Rounded "tile" surface from DESIGN.md's home-tile composition.
///
/// Borderless cream rectangle (Pulp tile in light mode, near-black tile in
/// dark "Reading Lamp" mode). Use for any home / settings / detail screen
/// card so the cream-stack hierarchy stays consistent across the app.
class PulpTile extends StatelessWidget {
  const PulpTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.md),
    this.radius = Radii.lg,
    this.onTap,
    this.inset = false,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// True for a nested sub-tile inside another tile (deeper cream).
  final bool inset;

  /// Override the tile color. Defaults to the scheme's tile or inset cream.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = color ??
        (inset ? scheme.surfaceContainerHigh : scheme.surfaceContainer);
    final borderRadius = BorderRadius.circular(radius);

    final tile = Container(
      decoration: BoxDecoration(
        color: resolved,
        borderRadius: borderRadius,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: tile,
      ),
    );
  }
}
