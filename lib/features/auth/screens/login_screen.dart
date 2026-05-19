import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/error_box_tile.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/widgets/login_with_phone_form.dart';
import 'package:prokat/features/auth/widgets/login_with_username_form.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/auth/widgets/logo_tile.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? errorMessage;
  bool usePassword = false;

  void setErrorMessage(String? msg) {
    setState(() => errorMessage = msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final authState = ref.watch(authProvider);
    final error = authState.error;

    return Scaffold(
      backgroundColor: theme.primaryColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            size: 24,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () => context.go(AppRoutes.main),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
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
                            "Get Started", // "Welcome Back"
                            style: theme.textTheme.headlineSmall?.copyWith(
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            "Pickup where you left off", // "Enter your phone number"
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (error != null) ErrorBoxTile(errorMessage: error),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: usePassword
                                ? LoginWithUsernameForm(
                                    key: const ValueKey('pw'),
                                    onError: setErrorMessage,
                                  )
                                : LoginWithPhoneForm(
                                    key: const ValueKey('phone'),
                                    onError: setErrorMessage,
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



                          // const SizedBox(height: 16),

                          // Center(
                          //   child: TextButton(
                          //     onPressed: () => setState(() {
                          //       usePassword = !usePassword;
                          //       errorMessage = null;
                          //     }),
                          //     child: Text(
                          //       usePassword
                          //           ? "Use Phone & OTP instead"
                          //           : "Sign in with password",
                          //       style: theme.textTheme.labelLarge?.copyWith(
                          //         color: theme.colorScheme.primary,
                          //         fontWeight: FontWeight.w600,
                          //       ),
                          //     ),
                          //   ),
                          // ),

    // 3. Bottom Link
    // Padding(
    //   padding: const EdgeInsets.symmetric(vertical: 20),
    //   child: GestureDetector(
    //     onTap: () => context.push('/register'),
    //     child: RichText(
    //       text: TextSpan(
    //         text: "New to Prokat? ",
    //         style: theme.textTheme.bodySmall?.copyWith(
    //           color: theme.colorScheme.onPrimary.withValues(
    //             alpha: 0.6,
    //           ),
    //         ),
    //         children: [
    //           TextSpan(
    //             text: "Create Account",
    //             style: theme.textTheme.bodySmall?.copyWith(
    //               color: theme.colorScheme.onPrimary,
    //               fontWeight: FontWeight.bold,
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // ),