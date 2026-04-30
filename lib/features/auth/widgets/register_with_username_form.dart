import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/models/auth_credentials.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/widgets/auth_button.dart';
import 'package:prokat/features/auth/widgets/auth_text_field.dart';
import 'package:go_router/go_router.dart';

class RegisterWithUsernameForm extends ConsumerStatefulWidget {
  final Function(String?) onError;

  const RegisterWithUsernameForm({super.key, required this.onError});

  @override
  ConsumerState<RegisterWithUsernameForm> createState() =>
      _RegisterWithUsernameFormState();
}

class _RegisterWithUsernameFormState
    extends ConsumerState<RegisterWithUsernameForm> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    Future<void> register() async {
      final fullName = nameController.text.trim();
      final username = usernameController.text.trim();
      final password = passwordController.text;

      // 1. Frontend Validation: Prevent submission if empty
      if (fullName.isEmpty || username.isEmpty || password.isEmpty) {
        widget.onError("Please fill in all registration fields");
        return;
      }

      // Clear previous errors
      widget.onError(null);

      try {
        List<String> nameParts = fullName.split(" ");
        String firstName = nameParts[0];
        String lastName = nameParts.length > 1
            ? nameParts.sublist(1).join(" ")
            : "";

        final credentials = RegisterCredentials(
          firstName: firstName,
          lastName: lastName,
          username: username,
          password: password,
        );

        final res = await ref
            .read(authProvider.notifier)
            .registerCredentials(credentials);

        if (res == true) context.push("/dashboard");
      } catch (e) {
        widget.onError("Something went wrong!");
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),

          AuthTextField(
            label: "Full Name",
            icon: Icons.person_outline,
            controller: nameController,
          ),

          const SizedBox(height: 16),

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
            text: "CREATE ACCOUNT",
            loadingText: "CREATING...",
            onPressed: register,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
