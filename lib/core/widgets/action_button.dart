import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final String? variant;

  const ActionButton({
    super.key,
    this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (variant == "secondary") {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          side: BorderSide(color: theme.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label ?? "",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: variant == "danger"
            ? theme.colorScheme.error
            : theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        disabledBackgroundColor: theme.primaryColor.withValues(alpha: 0.8),
        disabledForegroundColor: theme.colorScheme.onPrimary.withValues(
          alpha: 0.8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        padding: EdgeInsets.symmetric(
          vertical: label == null ? 6 : 12,
          horizontal: 20,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isLoading) ...[
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (icon != null) ...[
            Icon(icon, size: label == null ? 32 : 20),
            const SizedBox(width: 8),
          ],
          if (label != null)
            Text(
              label ?? "",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
