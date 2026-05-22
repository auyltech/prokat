import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CityPickerTrigger extends StatelessWidget {
  final String? selectedCity;
  final IconData icon;

  const CityPickerTrigger({
    super.key,
    this.selectedCity,
    this.icon = LucideIcons.mapPin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return TextButton.icon(
      icon: Icon(icon, color: theme.colorScheme.onPrimary, size: 24),
      label: Text(
        selectedCity ?? l10n.selectCity,
        style: TextStyle(color: theme.colorScheme.onPrimary),
      ),
      onPressed: () {
        CityPickerSheet.show(context: context);
      },
    );
  }
}
