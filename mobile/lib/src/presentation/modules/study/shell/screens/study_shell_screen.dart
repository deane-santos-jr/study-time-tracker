import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';

/// Bottom-nav shell. Renders the active tab via [StatefulNavigationShell] and
/// frames it with a dark Cocoa Ink floating pill nav, per DESIGN.md
/// "in-app — the home tile".
class StudyShellScreen extends StatefulWidget {
  const StudyShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<StudyShellScreen> createState() => _StudyShellScreenState();
}

class _StudyShellScreenState extends State<StudyShellScreen> {
  static const List<_NavItem> _items = [
    _NavItem(label: 'home'),
    // MARK: subjects-nav-start
    _NavItem(label: 'subjects'),
    // MARK: subjects-nav-end
    _NavItem(label: 'analytics'),
    _NavItem(label: 'profile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SemestersCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return MultiBlocListener(
      listeners: [
        BlocListener<SemestersCubit, SemestersState>(
          listenWhen: (prev, next) {
            final prevId = prev is SemestersLoaded ? prev.activeSemesterId : null;
            final nextId = next is SemestersLoaded ? next.activeSemesterId : null;
            return prevId != nextId;
          },
          listener: (context, state) {
            if (state is SemestersLoaded) {
              context.read<SubjectsCubit>().loadForSemester(state.activeSemesterId);
            }
          },
        ),
      ],
      child: Scaffold(
        body: widget.navigationShell,
        extendBody: true,
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            Spacing.lg,
            0,
            Spacing.lg,
            Spacing.md,
          ),
          child: _NavPill(
            items: _items,
            currentIndex: currentIndex,
            onSelect: (i) => widget.navigationShell.goBranch(
              i,
              initialLocation: i == currentIndex,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label});

  final String label;
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    // Cocoa Ink pill on light surface; Pulp-on-night does the inverse so the
    // nav still reads as a single dark sliver in "Reading Lamp" mode.
    final pillBg = brightness == Brightness.dark ? kPulp : kCocoaInk;
    final label = brightness == Brightness.dark ? kCocoaInk : kPulp;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _NavSlot(
                item: items[i],
                selected: i == currentIndex,
                labelColor: label,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.selected,
    required this.labelColor,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? labelColor
        : labelColor.withValues(alpha: 0.55);

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.full),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.full),
          splashColor: labelColor.withValues(alpha: 0.08),
          highlightColor: labelColor.withValues(alpha: 0.04),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: Motion.short,
              curve: Motion.move,
              style: TextStyle(
                fontFamily: kFontGeist,
                fontSize: 13.5,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.1,
                color: color,
                height: 1.0,
              ),
              child: Text(item.label),
            ),
          ),
        ),
      ),
    );
  }
}
