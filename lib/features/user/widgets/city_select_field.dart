import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/core/widgets/shake_on_tick.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CitySelectField extends ConsumerWidget {
  final String? city;
  final bool isRequired;
  final bool showIcon;
  final bool enabled;
  final CitySelectorService? service;
  final ValueChanged<String> onChanged;
  final String? requiredHintText;
  final bool requiredHintMuted;
  final bool showFieldErrors;
  final int shakeTick;
  final bool boxed;

  const CitySelectField({
    super.key,
    required this.city,
    required this.onChanged,
    this.isRequired = false,
    this.showIcon = true,
    this.enabled = true,
    this.service,
    this.requiredHintText,
    this.requiredHintMuted = false,
    this.showFieldErrors = true,
    this.shakeTick = 0,
    this.boxed = false,
  });

  Future<void> _pickCity(
    BuildContext context,
    WidgetRef ref,
    FormFieldState<String> state,
  ) async {
    final selected = await CityPickerSheet.show(
      context: context,
      service: service,
      highlightedCity: city,
    );
    if (selected == null || selected.isEmpty) return;

    final catalog = ref.read(catalogProvider).valueOrNull;
    final next = canonicalCity(selected, catalogCityKeys(catalog)) ?? selected;
    onChanged(next);
    state.didChange(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final hasCity = (city ?? '').trim().isNotEmpty;
    final hint = l10n.cityInputHint;
    final label = hasCity
        ? catalogCityLabel(
            city: city,
            languageCode: locale,
            catalog: catalog,
            fallback: (value) => localizedCityName(value, l10n),
          )
        : hint;

    return FormField<String>(
      validator: (_) {
        if (!showFieldErrors) return null;
        if (isRequired && (city ?? '').trim().isEmpty) {
          return l10n.cityRequired;
        }
        return null;
      },
      builder: (state) {
        final showRequiredHint = isRequired && !hasCity;
        final requiredHintStyle = requiredHintMuted
            ? theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.45),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
              )
            : theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              );
        final valueStyle = !enabled
            ? theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              )
            : hasCity
            ? theme.textTheme.bodyMedium
            : theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w400,
              );

        Widget valueRow = Row(
          children: [
            Expanded(
              child: Text(label, style: valueStyle),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: colorScheme.onSurface.withValues(
                alpha: enabled ? 0.6 : 0.35,
              ),
            ),
          ],
        );

        if (boxed) {
          valueRow = Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.45),
              ),
            ),
            child: valueRow,
          );
        } else {
          valueRow = Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: valueRow,
          );
        }

        return InkWell(
          onTap: enabled ? () => _pickCity(context, ref, state) : null,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: boxed
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (showIcon) ...[
                const SizedBox(
                  width: 45,
                  height: 50,
                  child: Icon(Icons.location_city_outlined, size: 25),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShakeOnTick(
                      tick: shakeTick,
                      child: Text.rich(
                        TextSpan(
                          text: l10n.city,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            if (showRequiredHint &&
                                requiredHintText != null &&
                                requiredHintText!.isNotEmpty)
                              TextSpan(
                                text: ' $requiredHintText',
                                style: requiredHintStyle,
                              )
                            else if (showRequiredHint)
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: colorScheme.error),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (boxed) const SizedBox(height: 6),
                    valueRow,
                    if (state.errorText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        state.errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
