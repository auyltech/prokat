import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/map/services/map_pin_streets.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _pinFieldHeight = 48.0;

class MapPinAddressPanel extends ConsumerWidget {
  const MapPinAddressPanel({
    super.key,
    required this.loading,
    required this.address,
    required this.streetOptions,
    required this.houseController,
    required this.onStreetSelected,
    required this.confirmButton,
    this.houseFocusNode,
  });

  final bool loading;
  final LocationSearchResult? address;
  final List<LocalizedNames> streetOptions;
  final TextEditingController houseController;
  final FocusNode? houseFocusNode;
  final ValueChanged<LocalizedNames> onStreetSelected;
  final Widget confirmButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
          ),
          child: SafeArea(
            top: false,
            bottom: keyboardInset == 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                else if (address != null) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _StreetField(
                          label: address!.labelStreet(languageCode),
                          enabled: streetOptions.length > 1,
                          onTap: () async {
                            houseFocusNode?.unfocus();
                            await _openStreetSheet(
                              context: context,
                              languageCode: languageCode,
                              selected: address!.streetNames,
                              options: streetOptions,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: _HouseField(
                          controller: houseController,
                          focusNode: houseFocusNode,
                          hint: l10n.houseNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatCityCountry(
                        l10n: l10n,
                        city: locationCityLabel(
                          ref,
                          context,
                          city: address!.city,
                          names: address!.cityNames,
                        ),
                        country: address!.labelCountry(languageCode),
                      ),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                confirmButton,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStreetSheet({
    required BuildContext context,
    required String languageCode,
    required LocalizedNames selected,
    required List<LocalizedNames> options,
  }) async {
    if (options.length <= 1) return;

    final picked = await showModalBottomSheet<LocalizedNames>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(option.pickPreferRu(languageCode)),
                    trailing: streetsMatch(option, selected)
                        ? Icon(
                            Icons.check,
                            color: Theme.of(sheetContext).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(sheetContext, option),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) onStreetSelected(picked);
  }
}

InputDecoration _pinFieldDecoration(
  BuildContext context, {
  String? hint,
  Widget? suffixIcon,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
  );

  return InputDecoration(
    isDense: true,
    hintText: hint,
    filled: true,
    fillColor: colorScheme.surfaceBright,
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(
      minWidth: 40,
      minHeight: _pinFieldHeight,
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    constraints: const BoxConstraints.tightFor(height: _pinFieldHeight),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary),
    ),
  );
}

class _StreetField extends StatelessWidget {
  const _StreetField({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: _pinFieldHeight,
      child: Material(
        color: colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: InputDecorator(
            decoration: _pinFieldDecoration(
              context,
              suffixIcon: Icon(
                Icons.keyboard_arrow_down,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HouseField extends StatelessWidget {
  const _HouseField({
    required this.controller,
    required this.hint,
    this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: _pinFieldHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        maxLines: 1,

        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        decoration: _pinFieldDecoration(context, hint: hint),
      ),
    );
  }
}
