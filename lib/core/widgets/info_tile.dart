import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {
  final String? label;
  final String value;
  final IconData? icon;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const InfoTile({
    super.key,
    this.label,
    required this.value,
    this.icon,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 12,
        ), // Increased padding slightly for multi-line layout comfort
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.red.shade50
              : theme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted ? Colors.red.shade200 : theme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: label != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Switched to start for better multi-line text flow
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6, // Horizontal space between elements
                    runSpacing: 4, // Vertical space between lines if it wraps
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (icon != null)
                        Icon(icon, color: theme.primaryColor, size: 20),

                      Text(
                        "${label!}:", // Added a colon for readability when wrapping lines
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isHighlighted
                              ? Colors.red[700]
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (icon != null)
                    Icon(icon, color: theme.primaryColor, size: 20),

                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isHighlighted ? Colors.red[700] : Colors.black,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
