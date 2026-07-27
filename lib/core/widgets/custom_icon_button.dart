import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final bool? isLoading;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? iconColor;

  const CustomIconButton({
    super.key,
    this.isLoading,
    required this.onPressed,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading == true) {
      return SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    } else {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 25, color: iconColor),
      );
    }
  }
}
