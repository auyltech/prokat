import 'package:flutter/material.dart';

void showLanguageSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final theme = Theme.of(context);

      return Padding(
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Sheet takes only needed height
          children: [
            // Handle for visual cue
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Select Language",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _LanguageTile(title: "Қазақша", code: "KZ", isSelected: false),
            _LanguageTile(title: "Русский", code: "RU", isSelected: false),
            _LanguageTile(title: "English", code: "EN", isSelected: true),
          ],
        ),
      );
    },
  );
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String code;
  final bool isSelected;

  const _LanguageTile({
    required this.title,
    required this.code,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceBright,
        child: Text(
          code,
          style: TextStyle(
            fontSize: 10,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        // 1. Update your locale state here (e.g., ref.read(localeProvider.notifier).update(...))
        // 2. Close the sheet
        Navigator.pop(context);
      },
    );
  }
}
