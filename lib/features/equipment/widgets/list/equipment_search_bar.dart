import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';

class EquipmentSearchBar extends StatelessWidget {
  final String? initialValue;

  const EquipmentSearchBar({super.key, this.initialValue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: TextEditingController(text: initialValue),
      decoration: InputDecoration(
        hintText: l10n.searchEquipment,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onSubmitted: (value) {
        // later: trigger provider filter
      },
    );
  }
}
