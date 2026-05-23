import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kWhite,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: kGray900,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      actions: actions,
    );
  }
}
