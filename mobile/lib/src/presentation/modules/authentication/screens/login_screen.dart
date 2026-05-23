import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final emailErr = CoreUtils.validateEmail(_emailController.text);
    final passErr = CoreUtils.validateRequired(_passwordController.text, field: 'Password');
    final firstError = emailErr ?? passErr;
    if (firstError != null) {
      CoreUtils.showNotification(message: firstError, success: false, context: context);
      return;
    }
    context.read<AuthenticationCubit>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthenticationSuccess) {
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Spacing.lg),
                Text('welcome back', style: theme.textTheme.displaySmall),
                const SizedBox(height: Spacing.xs),
                Text(
                  'where were we?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: InkOpacity.soft,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xxl),
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
                  placeholder: 'enter your password',
                  obscureText: true,
                  showPasswordToggle: true,
                  textInputAction: TextInputAction.done,
                  required: true,
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: Spacing.lg),
                BlocBuilder<AuthenticationCubit, AuthenticationState>(
                  builder: (context, state) {
                    return DefaultButton(
                      title: 'sign in',
                      fullWidth: true,
                      size: ButtonSize.large,
                      isLoading: state is AuthenticationLoading,
                      onPressed: _handleLogin,
                    );
                  },
                ),
                const SizedBox(height: Spacing.sm),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('new here? create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
