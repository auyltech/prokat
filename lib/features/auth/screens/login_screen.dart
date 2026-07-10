import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/error_box_tile.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/widgets/login_with_phone_form.dart';
import 'package:prokat/features/auth/widgets/logo_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  String? errorMessage;

  void setErrorMessage(String? msg) {
    setState(() => errorMessage = msg);
  }

  @override
  void initState() {
    super.initState();
    // Initialize recognizers to catch tap inputs safely
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(
        AppRoutes.termsConditions,
      ); // Match your router setup path
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () =>
          context.push(AppRoutes.privacyPolicy); // Match your router setup path
  }

  @override
  void dispose() {
    // Crucial step: dispose gestures to prevent memory leaks in production
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    final error = authState.error;

    return Scaffold(
      backgroundColor: theme.primaryColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => context.push(AppRoutes.main),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                ), // Outer screen margins
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Forces child to match the full height of the visible screen
                    minHeight: constraints.maxHeight,
                  ),
                  child: Align(
                    alignment: const Alignment(0.0, -0.3),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: theme.scaffoldBackgroundColor,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Wrap content tightly
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LogoTile(),

                          const SizedBox(height: 32),
                          Text(
                            l10n.getStarted,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            l10n.loginSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (error != null) ErrorBoxTile(errorMessage: error),

                          LoginWithPhoneForm(
                            key: const ValueKey('phone'),
                            onError: setErrorMessage,
                          ),

                          // Terms and conditions, Privacy notice and link
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 16.0,
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                // Non-clickable standard legal prompt prefix string
                                text: l10n.byContinuing,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                                children: [
                                  // Clickable Terms and Conditions string segment
                                  TextSpan(
                                    text: l10n.termsAndConditions,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: _termsRecognizer,
                                  ),
                                  // Non-clickable joining string segment
                                  TextSpan(text: l10n.andOur),
                                  // Clickable Privacy Policy string segment
                                  TextSpan(
                                    text: l10n.privacyPolicy,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: _privacyRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
