import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/features/appstatic/widgets/show_language_sheet.dart';

class LanguageSelectorTile extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const LanguageSelectorTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => showLanguageSheet(context), // Trigger your dropdown here
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Prevents the container from stretching
          children: [
            Icon(
              LucideIcons.globe, // The globe icon
              size: 32,
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w200,
            ),
            const SizedBox(width: 6), // Space between icon and text
            Text(
              "EN",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
