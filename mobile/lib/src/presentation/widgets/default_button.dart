import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';

enum ButtonSize { small, medium, large }

enum ButtonType { primary, secondary, ghost }

class DefaultButton extends StatelessWidget {
  const DefaultButton({
    super.key,
    required this.title,
    this.onPressed,
    this.fullWidth = false,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.type = ButtonType.primary,
  });

  final String title;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final bool isLoading;
  final ButtonSize size;
  final ButtonType type;

  double get _height => switch (size) {
        ButtonSize.small => 36,
        ButtonSize.medium => 44,
        ButtonSize.large => 52,
      };

  @override
  Widget build(BuildContext context) {
    final Color bg = switch (type) {
      ButtonType.primary => kPrimaryBase,
      ButtonType.secondary => kPrimary100,
      ButtonType.ghost => Colors.transparent,
    };
    final Color fg = switch (type) {
      ButtonType.primary => kWhite,
      ButtonType.secondary => kPrimaryBase,
      ButtonType.ghost => kPrimaryBase,
    };

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w600));

    final button = SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMd),
          ),
        ),
        child: child,
      ),
    );
    return button;
  }
}
