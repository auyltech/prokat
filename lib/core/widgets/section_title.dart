import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      // Safely spaces out elements when constraints are unbounded
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Flexible with fit: FlexFit.loose stops the crash in unbounded Rows
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        if (trailing != null && trailing!.isNotEmpty) ...[
          const SizedBox(width: 16),
          Text(
            trailing!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
