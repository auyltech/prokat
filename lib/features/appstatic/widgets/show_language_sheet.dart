import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/providers/locale_provider.dart';

void showLanguageSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return Consumer(
        builder: (context, ref, _) {
          final currentLocale = ref.watch(localeProvider);
          final l10n = AppLocalizations.of(context)!;
          final theme = Theme.of(context);

          void selectLocale(String langCode) {
            ref.read(localeProvider.notifier).setLocale(Locale(langCode));
            Navigator.pop(context);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.selectLanguage,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _LanguageTile(
                  title: 'Қазақша',
                  code: 'KZ',
                  isSelected: currentLocale.languageCode == 'kk',
                  onTap: () => selectLocale('kk'),
                ),
                _LanguageTile(
                  title: 'Русский',
                  code: 'RU',
                  isSelected: currentLocale.languageCode == 'ru',
                  onTap: () => selectLocale('ru'),
                ),
                _LanguageTile(
                  title: 'English',
                  code: 'EN',
                  isSelected: currentLocale.languageCode == 'en',
                  onTap: () => selectLocale('en'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.code,
    required this.isSelected,
    required this.onTap,
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
      onTap: onTap,
    );
  }
}
