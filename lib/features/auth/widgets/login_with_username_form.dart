import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/models/auth_credentials.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
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
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

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
        widget.onError(_l10n.pleaseEnterBothFields);
        return;
      }

      widget.onError(null);

      final credentials = LoginCredentials(
        username: username,
        password: password,
      );

      final res = await ref
          .read(authProvider.notifier)
          .loginCredentials(credentials);

      if (res == true && mounted) {
        final role = ref.watch(userProfileProvider).userProfile?.role ?? "";

        context.go(
          role.toLowerCase() == "owner"
              ? AppRoutes.ownerDashboard
              : AppRoutes.searchList,
        );
      }
    } catch (e) {
      widget.onError(_l10n.somethingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Column(
      children: [
        const SizedBox(height: 20),

        AuthTextField(
          label: _l10n.username,
          icon: Icons.alternate_email,
          controller: usernameController,
        ),

        const SizedBox(height: 16),

        AuthTextField(
          label: _l10n.password,
          icon: Icons.lock_outline,
          controller: passwordController,
          isPassword: true,
        ),

        const SizedBox(height: 24),

        AuthButton(
          loading: authState.isLoading,
          text: _l10n.navLogin,
          loadingText: _l10n.signingIn,
          onPressed: _login,
        ),
      ],
    );
  }
}
