import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/features/appstatic/widgets/show_language_sheet.dart';

class LanguageSelectorTile extends ConsumerWidget {
  const LanguageSelectorTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final langDisplay = LocaleNotifier.displayCode(locale);

    return GestureDetector(
      onTap: () => showLanguageSheet(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.globe,
            size: 32,
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w200,
          ),
          const SizedBox(width: 6),
          Text(
            langDisplay,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
