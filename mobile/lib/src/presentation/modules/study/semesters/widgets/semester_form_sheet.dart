import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_textfield.dart';

/// Bottom-sheet form for creating or editing a semester. Returns
/// (`SemesterCreatePayload | SemesterUpdatePayload`, makeActive: bool) on
/// submit; the caller dispatches to the right cubit method.
class SemesterFormResult {
  const SemesterFormResult.create({required this.create, required this.makeActive})
      : update = null;
  const SemesterFormResult.update({required this.update, required this.makeActive})
      : create = null;

  final SemesterCreatePayload? create;
  final SemesterUpdatePayload? update;
  final bool makeActive;
}

Future<SemesterFormResult?> showSemesterFormSheet(
  BuildContext context, {
  Semester? editing,
  required bool noActiveYet,
}) {
  return showModalBottomSheet<SemesterFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
    ),
    builder: (_) => _SemesterFormSheet(
      editing: editing,
      noActiveYet: noActiveYet,
    ),
  );
}

class _SemesterFormSheet extends StatefulWidget {
  const _SemesterFormSheet({required this.editing, required this.noActiveYet});

  final Semester? editing;
  final bool noActiveYet;

  @override
  State<_SemesterFormSheet> createState() => _SemesterFormSheetState();
}

class _SemesterFormSheetState extends State<_SemesterFormSheet> {
  late final TextEditingController _name;
  DateTime? _start;
  DateTime? _end;
  late bool _makeActive;

  bool get _isEdit => widget.editing != null;
  bool get _toggleDisabled => _isEdit && widget.editing!.isActive;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.editing?.name ?? '');
    _start = widget.editing?.startDate ?? DateTime.now();
    _end = widget.editing?.endDate ??
        DateTime.now().add(const Duration(days: 120));
    _makeActive = _isEdit
        ? widget.editing!.isActive
        : widget.noActiveYet; // first semester auto-activates
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = start ? (_start ?? now) : (_end ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
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
    if (_start == null || _end == null || !_start!.isBefore(_end!)) {
      CoreUtils.showNotification(
        message: 'start date must be before end date',
        success: false,
        context: context,
      );
      return;
    }
    if (_isEdit) {
      Navigator.of(context).pop(
        SemesterFormResult.update(
          update: SemesterUpdatePayload(
            name: name,
            startDate: _start,
            endDate: _end,
            isActive: _toggleDisabled ? null : _makeActive,
          ),
          makeActive: _makeActive && !_toggleDisabled,
        ),
      );
    } else {
      Navigator.of(context).pop(
        SemesterFormResult.create(
          create: SemesterCreatePayload(
            name: name,
            startDate: _start!,
            endDate: _end!,
          ),
          makeActive: _makeActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DragHandle(),
              const SizedBox(height: Spacing.md),
              Text(
                _isEdit ? 'edit term' : 'new term',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: Spacing.lg),
              DefaultTextfield(
                controller: _name,
                label: 'term name',
                placeholder: 'fall 2026',
                textInputAction: TextInputAction.next,
                required: true,
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'start',
                      value: _start,
                      onTap: () => _pickDate(start: true),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: _DateField(
                      label: 'end',
                      value: _end,
                      onTap: () => _pickDate(start: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              Opacity(
                opacity: _toggleDisabled ? 0.45 : 1.0,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _toggleDisabled
                            ? "this is your active term — switch elsewhere to deactivate"
                            : 'make this the active term',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: _makeActive,
                      onChanged: _toggleDisabled
                          ? null
                          : (v) => setState(() => _makeActive = v),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              DefaultButton(
                title: _isEdit ? 'save changes' : 'create term',
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

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Radii.full),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final hintInk = ink.withValues(alpha: InkOpacity.faint);

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
                    value != null ? CoreUtils.formatDate(value!) : 'pick',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: value != null ? ink : hintInk,
                    ),
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
