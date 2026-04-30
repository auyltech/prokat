import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/models/auth_credentials.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class LoginWithUsernameForm extends ConsumerStatefulWidget {
  final Function(String?) onError;

  const LoginWithUsernameForm({super.key, required this.onError});

  @override
  ConsumerState<LoginWithUsernameForm> createState() =>
      _LoginWithUsernameFormState();
}

class _LoginWithUsernameFormState extends ConsumerState<LoginWithUsernameForm> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    try {
      final username = usernameController.text.trim();
      final password = passwordController.text;

      if (username.isEmpty || password.isEmpty) {
        widget.onError("Please enter both username and password");
        return;
      }

      widget.onError(null);

      final credentials = LoginCredentials(
        username: username,
        password: password,
      );

      await ref.read(authProvider.notifier).loginCredentials(credentials);
    } catch (e) {
      widget.onError("Something went wrong!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Column(
      children: [
        const SizedBox(height: 20),

        AuthTextField(
          label: "Username",
          icon: Icons.alternate_email,
          controller: usernameController,
        ),

        const SizedBox(height: 16),

        AuthTextField(
          label: "Password",
          icon: Icons.lock_outline,
          controller: passwordController,
          isPassword: true,
        ),

        const SizedBox(height: 24),

        AuthButton(
          loading: authState.isLoading,
          text: "LOGIN",
          loadingText: "Signing in...",
          onPressed: _login,
        ),
      ],
    );
  }
}
