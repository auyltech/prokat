import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';

class CityPickerTrigger extends StatelessWidget {
  final String? selectedCity;
  final String label;
  final IconData icon;

  const CityPickerTrigger({
    super.key,
    this.selectedCity,
    this.label = 'Select city',
    this.icon = LucideIcons.mapPin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextButton.icon(
      icon: Icon(icon, color: theme.colorScheme.onPrimary,size: 24,),
      label: Text(selectedCity ?? label, style: TextStyle(color: theme.colorScheme.onPrimary),),
      onPressed: () {
        CityPickerSheet.show(context: context);
      },
    );
  }
}
