import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ThemeSelectionSheet extends StatelessWidget {
  final ThemeMode selectedMode;

  const ThemeSelectionSheet({super.key, required this.selectedMode});

  static Future<ThemeMode?> show(
    BuildContext context, {
    required ThemeMode selectedMode,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet.show<ThemeMode>(
      context,
      title: l10n.applicationTheme,
      subtitle: l10n.themeChooseHint,
      contentBuilder: (context) {
        return ThemeSelectionSheet(selectedMode: selectedMode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final l10n = AppLocalizations.of(context)!;

    final options = [
      _ThemeOption(
        mode: ThemeMode.system,
        icon: LucideIcons.smartphone,
        title: l10n.themeSystemDefault,
        subtitle: l10n.themeSystemDefaultSubtitle,
      ),
      _ThemeOption(
        mode: ThemeMode.light,
        icon: LucideIcons.sun,
        title: l10n.themeLight,
        subtitle: l10n.themeLightSubtitle,
      ),
      _ThemeOption(
        mode: ThemeMode.dark,
        icon: LucideIcons.moon,
        title: l10n.themeDark,
        subtitle: l10n.themeDarkSubtitle,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.sheetHorizontalPadding,
        0,
        AppDimens.sheetHorizontalPadding,
        MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: options.map((option) {
          final isSelected = option.mode == selectedMode;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.of(context).pop(option.mode);
            },
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(option.title),
            subtitle: Text(option.subtitle),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : null,
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeOption {
  final ThemeMode mode;
  final IconData icon;
  final String title;
  final String subtitle;

  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
