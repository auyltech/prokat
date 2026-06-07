import 'package:flutter/material.dart';

enum ActionBarButtonVariant { primary, secondary, destructive, danger }

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

  factory ActionBarButton.destructive({
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
      variant: ActionBarButtonVariant.destructive,
    );
  }

  factory ActionBarButton.danger({
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
      variant: ActionBarButtonVariant.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isButtonActive = isEnabled && !isLoading && onPressed != null;
    final VoidCallback? nativeOnPressed = isButtonActive ? onPressed : null;

    // Explicitly clamp minimum sizes and compress padding metrics dynamically
    final buttonStyle = variant == ActionBarButtonVariant.secondary
        ? OutlinedButton.styleFrom(
            foregroundColor: theme.primaryColor,
            side: BorderSide(
              color: isButtonActive
                  ? theme.primaryColor
                  : theme.disabledColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            minimumSize: const Size(
              0,
              44,
            ), // Standard height matching primary view
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ), // Compressed padding
            shape: const StadiumBorder(),
            elevation: 0,
          )
        : variant == ActionBarButtonVariant.destructive
        ? OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: isButtonActive
                  ? theme.colorScheme.error
                  : theme.disabledColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            minimumSize: const Size(
              0,
              44,
            ), // Standard height matching primary view
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ), // Compressed padding
            shape: const StadiumBorder(),
            elevation: 0,
          )
        : variant == ActionBarButtonVariant.danger
        ? ElevatedButton.styleFrom(
            backgroundColor:
                theme.colorScheme.error, // Uniform matching color tint
            foregroundColor: theme.colorScheme.onError,
            elevation: 0,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 0,
            ), // Compressed padding
            shape: const StadiumBorder(),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor, // Uniform matching color tint
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 0,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ), // Compressed padding
            shape: const StadiumBorder(),
          );

    return variant == ActionBarButtonVariant.secondary
        ? OutlinedButton(
            onPressed: nativeOnPressed,
            style: buttonStyle,
            child: _buildChild(context, theme.primaryColor),
          )
        : ElevatedButton(
            onPressed: nativeOnPressed,
            style: buttonStyle,
            child: _buildChild(context, theme.primaryColor),
          );
  }

  Widget _buildChild(BuildContext context, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize:
          MainAxisSize.min, // Constrain to prevent overflow boundaries
      children: [
        if (isLoading) ...[
          SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 4),
        ] else if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow
                .ellipsis, // Drop safely into ellipsis if text pushes boundaries
            style: const TextStyle(
              fontSize:
                  16, // Downsized slightly from 15 to give breathing room in triplets
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
