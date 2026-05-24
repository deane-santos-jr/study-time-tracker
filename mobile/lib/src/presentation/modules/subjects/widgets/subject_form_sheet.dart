import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/widgets/subject_color_picker.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_textfield.dart';

class SubjectFormResult {
  const SubjectFormResult({
    required this.subject,
    required this.inlineSemester,
  });

  final SubjectCreatePayload subject;

  /// Non-null when the user filled in the inline semester section — the
  /// caller must create that semester first, then create the subject using
  /// the returned semester id.
  final SemesterCreatePayload? inlineSemester;
}

Future<SubjectFormResult?> showSubjectFormSheet(
  BuildContext context, {
  required List<Semester> availableSemesters,
  required String? defaultSemesterId,
}) {
  return showModalBottomSheet<SubjectFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
    ),
    builder: (_) => _SubjectFormSheet(
      availableSemesters: availableSemesters,
      defaultSemesterId: defaultSemesterId,
    ),
  );
}

class _SubjectFormSheet extends StatefulWidget {
  const _SubjectFormSheet({
    required this.availableSemesters,
    required this.defaultSemesterId,
  });

  final List<Semester> availableSemesters;
  final String? defaultSemesterId;

  @override
  State<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends State<_SubjectFormSheet> {
  final _name = TextEditingController();
  SubjectColor _color = SubjectColor.risoFig;
  String? _semesterId;

  // Inline semester section state — used when no semesters exist
  final _semesterName = TextEditingController();
  DateTime _semesterStart = DateTime.now();
  DateTime _semesterEnd = DateTime.now().add(const Duration(days: 120));

  bool get _needsInlineSemester => widget.availableSemesters.isEmpty;

  @override
  void initState() {
    super.initState();
    _semesterId = widget.defaultSemesterId;
  }

  @override
  void dispose() {
    _name.dispose();
    _semesterName.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = start ? _semesterStart : _semesterEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _semesterStart = picked;
      } else {
        _semesterEnd = picked;
      }
    });
  }

  void _submit() {
    final subjectName = _name.text.trim();
    if (subjectName.isEmpty) {
      CoreUtils.showNotification(
        message: 'name is required',
        success: false,
        context: context,
      );
      return;
    }

    SemesterCreatePayload? inlineSemester;
    String? semesterIdToUse = _semesterId;

    if (_needsInlineSemester) {
      final termName = _semesterName.text.trim();
      if (termName.isEmpty) {
        CoreUtils.showNotification(
          message: 'term name is required',
          success: false,
          context: context,
        );
        return;
      }
      if (!_semesterStart.isBefore(_semesterEnd)) {
        CoreUtils.showNotification(
          message: 'start date must be before end date',
          success: false,
          context: context,
        );
        return;
      }
      inlineSemester = SemesterCreatePayload(
        name: termName,
        startDate: _semesterStart,
        endDate: _semesterEnd,
      );
      semesterIdToUse = null; // caller resolves after creating the semester
    } else if (semesterIdToUse == null) {
      CoreUtils.showNotification(
        message: 'pick a term to attach this subject to',
        success: false,
        context: context,
      );
      return;
    }

    Navigator.of(context).pop(
      SubjectFormResult(
        subject: SubjectCreatePayload(
          name: subjectName,
          color: _color.hex,
          semesterId: semesterIdToUse ?? '__inline__', // sentinel for caller
        ),
        inlineSemester: inlineSemester,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Radii.full),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('new subject', style: theme.textTheme.displaySmall),
              ),
              const SizedBox(height: Spacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DefaultTextfield(
                        controller: _name,
                        label: 'subject name',
                        placeholder: 'calculus 101',
                        textInputAction: TextInputAction.next,
                        required: true,
                      ),
                      const SizedBox(height: Spacing.md),
                      Text('color', style: theme.textTheme.labelMedium),
                      const SizedBox(height: Spacing.sm),
                      SubjectColorPicker(
                        selected: _color,
                        onChanged: (c) => setState(() => _color = c),
                      ),
                      if (_needsInlineSemester) ...[
                        const SizedBox(height: Spacing.xl),
                        Text(
                          'to organize subjects, group them into a term',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: softInk),
                        ),
                        const SizedBox(height: Spacing.md),
                        DefaultTextfield(
                          controller: _semesterName,
                          label: 'term name',
                          placeholder: 'fall 2026',
                          textInputAction: TextInputAction.next,
                          required: true,
                        ),
                        const SizedBox(height: Spacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _DateCell(
                                label: 'start',
                                value: _semesterStart,
                                onTap: () => _pickDate(start: true),
                              ),
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: _DateCell(
                                label: 'end',
                                value: _semesterEnd,
                                onTap: () => _pickDate(start: false),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: Spacing.lg),
                        Text('term', style: theme.textTheme.labelMedium),
                        const SizedBox(height: Spacing.sm),
                        _SemesterDropdown(
                          options: widget.availableSemesters,
                          selectedId: _semesterId,
                          onSelect: (id) => setState(() => _semesterId = id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              DefaultButton(
                title: 'add subject',
                fullWidth: true,
                size: ButtonSize.large,
                onPressed: _submit,
              ),
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: softInk),
                child: const Text('cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.xs),
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: ink.withValues(alpha: InkOpacity.hint)),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    CoreUtils.formatDate(value),
                    style: theme.textTheme.bodyMedium?.copyWith(color: ink),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 16, color: softInk),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Slim edit-only sheet: just name + color picker. The term is fixed (the
/// caller owns that decision — subject can't move terms via this UI), so we
/// skip the term dropdown and inline-term creation flow.
Future<SubjectUpdatePayload?> showSubjectEditSheet(
  BuildContext context, {
  required Subject subject,
}) {
  return showModalBottomSheet<SubjectUpdatePayload>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
    ),
    builder: (_) => _SubjectEditSheet(subject: subject),
  );
}

class _SubjectEditSheet extends StatefulWidget {
  const _SubjectEditSheet({required this.subject});

  final Subject subject;

  @override
  State<_SubjectEditSheet> createState() => _SubjectEditSheetState();
}

class _SubjectEditSheetState extends State<_SubjectEditSheet> {
  late final TextEditingController _name;
  late SubjectColor _color;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.subject.name);
    _color = SubjectColor.fromHex(widget.subject.color);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      CoreUtils.showNotification(
        message: 'name is required',
        success: false,
        context: context,
      );
      return;
    }
    Navigator.of(context).pop(
      SubjectUpdatePayload(name: name, color: _color.hex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Radii.full),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('edit subject', style: theme.textTheme.displaySmall),
            ),
            const SizedBox(height: Spacing.lg),
            DefaultTextfield(
              controller: _name,
              label: 'subject name',
              placeholder: 'calculus 101',
              textInputAction: TextInputAction.done,
              required: true,
            ),
            const SizedBox(height: Spacing.md),
            Text('color', style: theme.textTheme.labelMedium),
            const SizedBox(height: Spacing.sm),
            SubjectColorPicker(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: Spacing.xl),
            DefaultButton(
              title: 'save changes',
              fullWidth: true,
              size: ButtonSize.large,
              onPressed: _submit,
            ),
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: softInk),
              child: const Text('cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterDropdown extends StatelessWidget {
  const _SemesterDropdown({
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Semester> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: ink.withValues(alpha: InkOpacity.hint)),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          hint: Text(
            'pick a term',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: ink.withValues(alpha: InkOpacity.faint)),
          ),
          items: [
            for (final s in options)
              DropdownMenuItem(
                value: s.id,
                child: Text(s.name.toLowerCase()),
              ),
          ],
          onChanged: (v) {
            if (v != null) onSelect(v);
          },
        ),
      ),
    );
  }
}
