import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/models/auth_credentials.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import 'package:go_router/go_router.dart';

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

      final credentials = UsernamePasswordCredentials(
        username: username,
        password: password,
      );

      final res = await ref.read(authProvider.notifier).login(credentials);

      if (res == true) {
        context.push("/login");
        // AuthNotifier.login() already reloads app startup state.
        // Router redirect will move the user off /login automatically.
      } else {
        // Handle case where res is false but no exception was thrown
        widget.onError("Invalid username or password");
      }
    } catch (e) {
      widget.onError(e.toString().replaceAll('Exception: ', ''));
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
          // fillColor: Colors.white.withOpacity(0.05)
          // textColor: Colors.white
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
          // Button should use accentColor (0xFF4E73DF)
        ),
      ],
    );
  }
}
