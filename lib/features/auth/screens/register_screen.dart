import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/error_box_tile.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/widgets/logo_tile.dart';
import 'package:prokat/features/auth/widgets/register_with_phone_form.dart';
import 'package:prokat/features/auth/widgets/register_with_username_form.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  String? errorMessage;
  bool useEmail = false;

  void setErrorMessage(String? msg) {
    setState(() => errorMessage = msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final accentColor = colorScheme.primary;

    final authState = ref.watch(authProvider);
    final error = authState.error;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 0, 72, 155),
              Color.fromARGB(255, 0, 36, 78),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(""),
                          const Spacer(),

                          Container(
                            margin: const EdgeInsets.all(0),
                            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(32),
                              ),
                              color: theme.scaffoldBackgroundColor,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const LogoTile(),

                                const SizedBox(height: 45),

                                Text(
                                  l10n.createAccount,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -1,
                                        color: colorScheme.onSurface,
                                      ),
                                ),
                                Text(
                                  l10n.joinCommunity,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                if (error != null)
                                  ErrorBoxTile(errorMessage: error),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: useEmail
                                      ? RegisterWithUsernameForm(
                                          key: const ValueKey('email'),
                                          onError: setErrorMessage,
                                        )
                                      : RegisterWithPhoneForm(
                                          key: const ValueKey('phone'),
                                          onError: setErrorMessage,
                                        ),
                                ),

                                const SizedBox(height: 16),

                                Center(
                                  child: TextButton(
                                    onPressed: () => setState(() {
                                      useEmail = !useEmail;
                                      errorMessage = null;
                                    }),
                                    child: Text(
                                      useEmail
                                          ? l10n.registerWithPhone
                                          : l10n.useEmailPassword,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: accentColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: GestureDetector(
                              onTap: () => context.go('/login'),
                              child: RichText(
                                text: TextSpan(
                                  text: "${l10n.alreadyRegistered} ",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.6),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: l10n.loginLink,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
