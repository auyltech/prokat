import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/providers/locale_provider.dart';

class LanguageSheet extends ConsumerStatefulWidget {
  const LanguageSheet({super.key});

  @override
  ConsumerState<LanguageSheet> createState() => LanguageSheetState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allows sheet to wrap its content height dynamically
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return const LanguageSheet();
      },
    );
  }
}

class LanguageSheetState extends ConsumerState<LanguageSheet> {
  void _selectLocale(String langCode) {
    ref.read(localeProvider.notifier).setLocale(Locale(langCode));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 12, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Constrains sheet to content size
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.selectLanguage,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _LanguageTile(
            title: 'Қазақша',
            code: 'KZ',
            isSelected: currentLocale.languageCode == 'kk',
            onTap: () => _selectLocale('kk'),
          ),
          _LanguageTile(
            title: 'Русский',
            code: 'RU',
            isSelected: currentLocale.languageCode == 'ru',
            onTap: () => _selectLocale('ru'),
          ),
          _LanguageTile(
            title: 'English',
            code: 'EN',
            isSelected: currentLocale.languageCode == 'en',
            onTap: () => _selectLocale('en'),
          ),
        ],
      ),
    );
  }
}

// 5. Mocking your private sub-tile widget structure so your code compiles out of the box
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
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainer,
        child: Text(
          code,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
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
    );
  }
}
