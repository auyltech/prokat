import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_label_button.dart';

class AuthSwitchLink extends StatelessWidget {
  final String message;
  final String actionText;
  final VoidCallback onTap;

  const AuthSwitchLink({
    super.key,
    required this.message,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const ghostGray = Color(0x4DFFFFFF); // White @ 30%

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(color: ghostGray, fontSize: 14)),
          AppLabelButton(
            title: actionText,
            onTap: onTap,
            variant: AppLabelButtonVariant.text,
          ),
        ],
      ),
    );
  }
}
