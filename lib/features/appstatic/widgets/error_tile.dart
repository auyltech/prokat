import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ErrorTile extends StatelessWidget {
  final String message;
  const ErrorTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA), width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.failedToLoadMessage(message),
                style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
