import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Define theme constants locally or use your global ones
    const ghostGray = Color(0x4DFFFFFF); // White @ 30%
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.getStarted,
          style: const TextStyle(
            color: Colors.white, // Pop against bgColor
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4), // Tight industrial spacing
        Text(
          l10n.selectRegistrationMethod,
          style: const TextStyle(color: ghostGray, fontSize: 16),
        ),
      ],
    );
  }
}
