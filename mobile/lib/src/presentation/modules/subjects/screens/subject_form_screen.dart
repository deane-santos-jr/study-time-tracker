import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/widgets/subject_color_picker.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_textfield.dart';

class SubjectFormScreen extends StatefulWidget {
  const SubjectFormScreen({super.key, this.subjectId});

  /// Null for create, the subject id for edit.
  final String? subjectId;

  bool get isEditing => subjectId != null;

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _nameController = TextEditingController();
  SubjectColor _color = SubjectColor.risoFig;
  String? _semesterId;
  bool _submitting = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _hydrateFromState(SubjectsLoaded state) {
    if (_initialized) return;
    _initialized = true;
    _semesterId = state.activeSemesterId;
    if (widget.isEditing) {
      final existing = state.subjects.firstWhere(
        (s) => s.id == widget.subjectId,
        orElse: () => Subject(
          id: '',
          semesterId: state.activeSemesterId,
          name: '',
          color: SubjectColor.risoFig.hex,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (existing.id.isNotEmpty) {
        _nameController.text = existing.name;
        _color = SubjectColor.fromHex(existing.color);
        _semesterId = existing.semesterId;
      }
    }
  }

  Future<void> _submit(BuildContext context, SubjectsLoaded state) async {
    final nameErr = CoreUtils.validateRequired(_nameController.text, field: 'Name');
    if (nameErr != null) {
      CoreUtils.showNotification(message: nameErr, success: false, context: context);
      return;
    }
    final semesterId = _semesterId;
    if (semesterId == null) {
      CoreUtils.showNotification(
        message: 'Pick a semester',
        success: false,
        context: context,
      );
      return;
    }

    setState(() => _submitting = true);
    final cubit = context.read<SubjectsCubit>();
    final ok = widget.isEditing
        ? await cubit.updateSubject(
            id: widget.subjectId!,
            payload: SubjectUpdatePayload(
              name: _nameController.text.trim(),
              color: _color.hex,
            ),
          )
        : await cubit.createSubject(
            payload: SubjectCreatePayload(
              name: _nameController.text.trim(),
              color: _color.hex,
              semesterId: semesterId,
            ),
          );
    if (!context.mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      CoreUtils.showNotification(
        message: widget.isEditing ? 'Subject updated' : 'Subject created',
        success: true,
        context: context,
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/subjects');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: widget.isEditing ? 'edit subject' : 'new subject'),
      body: BlocBuilder<SubjectsCubit, SubjectsState>(
        builder: (context, state) {
          if (state is! SubjectsLoaded) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }
          _hydrateFromState(state);
          return _Form(
            nameController: _nameController,
            color: _color,
            onColorChanged: (c) => setState(() => _color = c),
            semesters: state.semesters,
            semesterId: _semesterId,
            onSemesterChanged: widget.isEditing
                ? null // backend update schema doesn't accept semesterId
                : (id) => setState(() => _semesterId = id),
            submitting: _submitting,
            submitLabel: widget.isEditing ? 'Save changes' : 'Create subject',
            onSubmit: () => _submit(context, state),
          );
        },
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.nameController,
    required this.color,
    required this.onColorChanged,
    required this.semesters,
    required this.semesterId,
    required this.onSemesterChanged,
    required this.submitting,
    required this.submitLabel,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final SubjectColor color;
  final ValueChanged<SubjectColor> onColorChanged;
  final List<Semester> semesters;
  final String? semesterId;
  final ValueChanged<String>? onSemesterChanged;
  final bool submitting;
  final String submitLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DefaultTextfield(
              controller: nameController,
              label: 'Name',
              placeholder: 'Calculus II',
              textInputAction: TextInputAction.next,
              required: true,
            ),
            const SizedBox(height: Spacing.lg),
            Text('Color', style: theme.textTheme.labelMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              color.label,
              style: theme.textTheme.bodySmall?.copyWith(color: softInk),
            ),
            const SizedBox(height: Spacing.sm),
            SubjectColorPicker(selected: color, onChanged: onColorChanged),
            const SizedBox(height: Spacing.lg),
            if (semesters.length > 1 || onSemesterChanged == null) ...[
              Text('Semester', style: theme.textTheme.labelMedium),
              const SizedBox(height: Spacing.sm),
              _SemesterDropdown(
                semesters: semesters,
                value: semesterId,
                onChanged: onSemesterChanged,
              ),
              const SizedBox(height: Spacing.lg),
            ],
            DefaultButton(
              title: submitLabel,
              fullWidth: true,
              size: ButtonSize.large,
              isLoading: submitting,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterDropdown extends StatelessWidget {
  const _SemesterDropdown({
    required this.semesters,
    required this.value,
    required this.onChanged,
  });

  final List<Semester> semesters;
  final String? value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;

    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged == null ? null : (v) {
        if (v != null) onChanged!(v);
      },
      style: theme.textTheme.bodyMedium,
      iconEnabledColor: ink.withValues(alpha: InkOpacity.soft),
      dropdownColor: theme.colorScheme.surface,
      items: [
        for (final s in semesters)
          DropdownMenuItem(
            value: s.id,
            child: Row(
              children: [
                Expanded(child: Text(s.name)),
                if (s.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Text(
                      'active',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
