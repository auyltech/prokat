import 'package:flutter/material.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/l10n/app_localizations.dart';

class DemandSurveyCityField extends StatelessWidget {
  final String? city;
  final VoidCallback onTap;

  const DemandSurveyCityField({
    super.key,
    required this.city,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasCity = city != null && city!.isNotEmpty;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        isEmpty: !hasCity,
        decoration: InputDecoration(
          labelText: l10n.demandSurveyCityLabel,
          labelStyle: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          hasCity ? localizedCityName(city, l10n) : l10n.demandSurveySelectCity,
          style: hasCity
              ? theme.textTheme.bodyMedium
              : theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w400,
                ),
        ),
      ),
    );
  }
}
