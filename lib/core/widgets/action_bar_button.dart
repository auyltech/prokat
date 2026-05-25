import 'package:flutter/material.dart';

enum ActionBarButtonVariant { primary, secondary }

class ActionBarButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final ActionBarButtonVariant variant;

  const ActionBarButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.variant = ActionBarButtonVariant.primary,
  });

  // Quick factory constructor for secondary/outlined buttons
  factory ActionBarButton.secondary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
  }) {
    return ActionBarButton(
      key: key,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
      variant: ActionBarButtonVariant.secondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine if button can actually be clicked
    final bool isButtonActive = isEnabled && !isLoading && onPressed != null;
    final VoidCallback? nativeOnPressed = isButtonActive ? onPressed : null;

    if (variant == ActionBarButtonVariant.secondary) {
      return OutlinedButton(
        onPressed: nativeOnPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.primaryColor,
          side: BorderSide(
            color: isButtonActive 
                ? theme.dividerColor.withAlpha(180) 
                : theme.disabledColor.withAlpha(50),
            width: 1.5,
          ),
          minimumSize: const Size(0, 40),
          shape: const StadiumBorder(), // Gives the exact pill/capsule look
          elevation: 0,
        ),
        child: _buildChild(context, theme.primaryColor),
      );
    }

    // Default: Primary variant
    return ElevatedButton(
      onPressed: nativeOnPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 221, 221, 255), // Light background tint matching "Accept"
        foregroundColor: theme.primaryColor, // Deep contrast text/icon color
        elevation: 0,
        minimumSize: const Size(0, 44),
        shape: const StadiumBorder(),
      ),
      child: _buildChild(context, theme.primaryColor),
    );
  }

  Widget _buildChild(BuildContext context, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
