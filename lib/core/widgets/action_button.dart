import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, ghost, destructive, danger }

class ActionButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final ButtonVariant? variant;

  const ActionButton({
    super.key,
    this.label,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.variant = ButtonVariant.primary,
  });

  factory ActionButton.ghost({
    Key? key,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
  }) {
    return ActionButton(
      key: key,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
      variant: ButtonVariant.ghost,
    );
  }

  factory ActionButton.secondary({
    Key? key,
    String? label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
  }) {
    return ActionButton(
      key: key,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
      variant: ButtonVariant.secondary,
    );
  }

  factory ActionButton.destructive({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
  }) {
    return ActionButton(
      key: key,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
      variant: ButtonVariant.destructive,
    );
  }

  factory ActionButton.danger({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
  }) {
    return ActionButton(
      key: key,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
      variant: ButtonVariant.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine context active color palette
    final bool isSecondary = variant == ButtonVariant.secondary;
    final Color variantColor = isSecondary
        ? theme.primaryColor
        : theme.colorScheme.error;

    if (variant == ButtonVariant.ghost) {
      return IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          Icons.chat_bubble_outline,
          color: theme.primaryColor,
          size: 30,
        ),
        onPressed: onPressed,
      );
    }

    // Outlined Buttons (Secondary & Destructive)
    if (variant == ButtonVariant.secondary ||
        variant == ButtonVariant.destructive) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          side: BorderSide(color: variantColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Renders Spinner if loading, or custom specified Icon
        icon: isLoading
            ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(variantColor),
                ),
              )
            : (icon == null ? null : Icon(icon, size: 18, color: variantColor)),
        label: Text(
          label ?? "",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: variantColor,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
      );
    }

    // Filled Buttons (Primary & Danger)
    final Color baseFillColor = variant == ButtonVariant.danger
        ? theme.colorScheme.error
        : theme.primaryColor;

    return ElevatedButton(
      onPressed: (isLoading || !isEnabled) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: baseFillColor,
        foregroundColor: theme.colorScheme.onPrimary,
        // DYNAMIC FIX: Adapts disabled background color matching the variant rule
        disabledBackgroundColor: baseFillColor.withValues(alpha: 0.6),
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
        children: [
          if (isLoading) ...[
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (icon != null) ...[
            Icon(icon, size: label == null ? 30 : 20),
            const SizedBox(width: 8),
          ],
          if (label != null)
            Text(
              label!,
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
