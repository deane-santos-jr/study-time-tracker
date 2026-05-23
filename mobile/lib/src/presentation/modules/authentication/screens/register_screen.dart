import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/utils/context_extension.dart';
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
        appBar: const MainAppBar(title: 'Create account'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sign up', style: context.theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Start tracking your study sessions.',
                  style: context.theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: DefaultTextfield(
                        controller: _firstNameController,
                        label: 'First name',
                        placeholder: 'Jane',
                        required: true,
                        validator: (v) =>
                            CoreUtils.validateRequired(v, field: 'First name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DefaultTextfield(
                        controller: _lastNameController,
                        label: 'Last name',
                        placeholder: 'Doe',
                        required: true,
                        validator: (v) =>
                            CoreUtils.validateRequired(v, field: 'Last name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DefaultTextfield(
                  controller: _emailController,
                  label: 'Email',
                  placeholder: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                  validator: CoreUtils.validateEmail,
                ),
                const SizedBox(height: 16),
                DefaultTextfield(
                  controller: _passwordController,
                  label: 'Password',
                  placeholder: 'At least 8 characters',
                  obscureText: true,
                  showPasswordToggle: true,
                  required: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                DefaultTextfield(
                  controller: _confirmController,
                  label: 'Confirm password',
                  placeholder: 'Re-enter your password',
                  obscureText: true,
                  showPasswordToggle: true,
                  required: true,
                  validator: _validateConfirm,
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthenticationCubit, AuthenticationState>(
                  builder: (context, state) {
                    return DefaultButton(
                      title: 'Create account',
                      fullWidth: true,
                      size: ButtonSize.large,
                      isLoading: state is AuthenticationLoading,
                      onPressed: _handleRegister,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
