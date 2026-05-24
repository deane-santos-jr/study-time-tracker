import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/widgets/subject_color_picker.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_textfield.dart';

/// Edit-only subject form. Creation lives in [showSubjectFormSheet]; this
/// screen is reached via the legacy `/subjects/:id` route. Semester
/// reassignment isn't exposed — the backend update schema doesn't accept it.
class SubjectFormScreen extends StatefulWidget {
  const SubjectFormScreen({super.key, required this.subjectId});

  final String? subjectId;

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _nameController = TextEditingController();
  SubjectColor _color = SubjectColor.risoFig;
  bool _submitting = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _hydrateFromState(SubjectsLoaded state) {
    if (_initialized || widget.subjectId == null) return;
    _initialized = true;
    for (final s in state.subjects) {
      if (s.id == widget.subjectId) {
        _nameController.text = s.name;
        _color = SubjectColor.fromHex(s.color);
        return;
      }
    }
  }

  Future<void> _submit(BuildContext context) async {
    final nameErr = CoreUtils.validateRequired(
      _nameController.text,
      field: 'name',
    );
    if (nameErr != null) {
      CoreUtils.showNotification(
        message: nameErr,
        success: false,
        context: context,
      );
      return;
    }
    final id = widget.subjectId;
    if (id == null) return;

    setState(() => _submitting = true);
    final cubit = context.read<SubjectsCubit>();
    final ok = await cubit.updateSubject(
      id: id,
      payload: SubjectUpdatePayload(
        name: _nameController.text.trim(),
        color: _color.hex,
      ),
    );
    if (!context.mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      CoreUtils.showNotification(
        message: 'subject updated',
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
      appBar: const MainAppBar(title: 'edit subject'),
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
            submitting: _submitting,
            onSubmit: () => _submit(context),
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
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final SubjectColor color;
  final ValueChanged<SubjectColor> onColorChanged;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);

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
              label: 'name',
              placeholder: 'calculus 101',
              textInputAction: TextInputAction.next,
              required: true,
            ),
            const SizedBox(height: Spacing.lg),
            Text('color', style: theme.textTheme.labelMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              color.label,
              style: theme.textTheme.bodySmall?.copyWith(color: softInk),
            ),
            const SizedBox(height: Spacing.sm),
            SubjectColorPicker(selected: color, onChanged: onColorChanged),
            const SizedBox(height: Spacing.xl),
            DefaultButton(
              title: 'save changes',
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
