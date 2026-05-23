import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _handleRegister() {
    final firstError = CoreUtils.validateRequired(_firstNameController.text, field: 'First name') ??
        CoreUtils.validateRequired(_lastNameController.text, field: 'Last name') ??
        CoreUtils.validateEmail(_emailController.text) ??
        _validatePassword(_passwordController.text) ??
        _validateConfirm(_confirmController.text);

    if (firstError != null) {
      CoreUtils.showNotification(message: firstError, success: false, context: context);
      return;
    }

    context.read<AuthenticationCubit>().register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthenticationSuccess) {
          CoreUtils.showNotification(
            message: 'Account created — welcome!',
            success: true,
            context: context,
          );
          context.go('/dashboard');
        } else if (state is AuthenticationFailure) {
          CoreUtils.showNotification(
            message: state.errorMessage,
            success: false,
            context: context,
          );
        }
      },
      child: Scaffold(
        appBar: const MainAppBar(title: 'create account'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('sign up', style: theme.textTheme.displaySmall),
                const SizedBox(height: Spacing.xs),
                Text(
                  'start tracking your study sessions.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: InkOpacity.soft,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: DefaultTextfield(
                        controller: _firstNameController,
                        label: 'first name',
                        placeholder: 'jane',
                        textInputAction: TextInputAction.next,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: DefaultTextfield(
                        controller: _lastNameController,
                        label: 'last name',
                        placeholder: 'doe',
                        textInputAction: TextInputAction.next,
                        required: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                DefaultTextfield(
                  controller: _emailController,
                  label: 'email',
                  placeholder: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  required: true,
                ),
                const SizedBox(height: Spacing.md),
                DefaultTextfield(
                  controller: _passwordController,
                  label: 'password',
                  placeholder: 'at least 8 characters',
                  obscureText: true,
                  showPasswordToggle: true,
                  textInputAction: TextInputAction.next,
                  required: true,
                ),
                const SizedBox(height: Spacing.md),
                DefaultTextfield(
                  controller: _confirmController,
                  label: 'confirm password',
                  placeholder: 're-enter your password',
                  obscureText: true,
                  showPasswordToggle: true,
                  textInputAction: TextInputAction.done,
                  required: true,
                  onSubmitted: (_) => _handleRegister(),
                ),
                const SizedBox(height: Spacing.lg),
                BlocBuilder<AuthenticationCubit, AuthenticationState>(
                  builder: (context, state) {
                    return DefaultButton(
                      title: 'create account',
                      fullWidth: true,
                      size: ButtonSize.large,
                      isLoading: state is AuthenticationLoading,
                      onPressed: _handleRegister,
                    );
                  },
                ),
                const SizedBox(height: Spacing.sm),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('already have an account? sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
