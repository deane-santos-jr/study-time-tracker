import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/utils/context_extension.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
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
        appBar: const MainAppBar(title: 'Study Time Tracker'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sign in', style: context.theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Track your study sessions across devices.',
                  style: context.theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                DefaultTextfield(
                  controller: _emailController,
                  label: 'Email',
                  placeholder: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                ),
                const SizedBox(height: 16),
                DefaultTextfield(
                  controller: _passwordController,
                  label: 'Password',
                  placeholder: 'Enter your password',
                  obscureText: true,
                  showPasswordToggle: true,
                  required: true,
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthenticationCubit, AuthenticationState>(
                  builder: (context, state) {
                    return DefaultButton(
                      title: 'Sign in',
                      fullWidth: true,
                      size: ButtonSize.large,
                      isLoading: state is AuthenticationLoading,
                      onPressed: _handleLogin,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
