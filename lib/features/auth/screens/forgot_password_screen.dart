import 'package:flutter/material.dart';
import 'package:prokat/features/auth/widgets/auth_button.dart';
import 'package:prokat/features/auth/widgets/auth_text_field.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _isSent = false;
  String? errorMessage;
  final TextEditingController _emailController = TextEditingController();

  void setErrorMessage(String? msg) => setState(() => errorMessage = msg);

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF121417);
    const ghostGray = Color(0x4DFFFFFF);
    const accentColor = Color(0xFF4E73DF);
    const errorColor = Color(0xFFE53935);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_reset_rounded, size: 64, color: accentColor),
            const SizedBox(height: 32),
            Text(
              _isSent ? l10n.checkYourEmail : l10n.resetPassword,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isSent
                  ? l10n.recoverySentTo(_emailController.text)
                  : l10n.enterRegisteredEmail,
              style: const TextStyle(color: ghostGray, fontSize: 16),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: errorColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: errorColor, fontSize: 14),
                ),
              ),
            ],

            const SizedBox(height: 48),

            if (!_isSent) ...[
              AuthTextField(
                label: l10n.emailAddress,
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              AuthButton(
                loading: false,
                text: l10n.sendRecoveryLink,
                loadingText: l10n.sending,
                onPressed: () {
                  if (_emailController.text.isEmpty) {
                    setErrorMessage(l10n.pleaseEnterEmail);
                    return;
                  }
                  setErrorMessage(null);
                  setState(() => _isSent = true);
                },
              ),
            ] else ...[
              AuthButton(
                loading: false,
                text: l10n.backToLogin,
                loadingText: l10n.loading,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    setErrorMessage(null);
                  },
                  child: Text(
                    l10n.resendLink,
                    style: const TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
