import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerTariffCard extends StatefulWidget {
  final TariffDraft draft;
  final bool canEdit;
  final ValueChanged<TariffDraft> onChanged;
  final VoidCallback? onDelete;

  const OwnerTariffCard({
    super.key,
    required this.draft,
    required this.canEdit,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<OwnerTariffCard> createState() => _OwnerTariffCardState();
}

class _OwnerTariffCardState extends State<OwnerTariffCard> {
  late TextEditingController _priceController;
  late TextEditingController _customNameController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.draft.hasPrice ? formatPriceNumber(widget.draft.price) : '',
    );
    _customNameController = TextEditingController(
      text: widget.draft.customName,
    );
  }

  @override
  void didUpdateWidget(covariant OwnerTariffCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.price != widget.draft.price) {
      final next = widget.draft.hasPrice
          ? formatPriceNumber(widget.draft.price)
          : '';
      if (_priceController.text != next) {
        _priceController.text = next;
      }
    }
    if (oldWidget.draft.customName != widget.draft.customName &&
        _customNameController.text != widget.draft.customName) {
      _customNameController.text = widget.draft.customName;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  void _emit(TariffDraft next) => widget.onChanged(next);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.canEdit
                ? () => _emit(draft.copyWith(expanded: !draft.expanded))
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.title(l10n),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          draft.collapsedSubtitle(l10n),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: draft.hasPrice
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.55),
                            fontWeight: draft.hasPrice
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    draft.expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (draft.expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!draft.isPreset) ...[
                    _FieldLabel(l10n.serviceType),
                    const SizedBox(height: 6),
                    _OutlineDropdown<String>(
                      value: draft.labelKey.isEmpty ? null : draft.labelKey,
                      hint: l10n.serviceType,
                      enabled: widget.canEdit,
                      items: vacuumServiceTypeKeys
                          .map(
                            (key) => DropdownMenuItem(
                              value: key,
                              child: Text(tariffServiceOptionLabel(key, l10n)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        _emit(draft.copyWith(labelKey: value));
                      },
                    ),
                    if (draft.labelKey == vacuumTariffOther) ...[
                      const SizedBox(height: 12),
                      _FieldLabel(l10n.customServiceName),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _customNameController,
                        enabled: widget.canEdit,
                        maxLength: 40,
                        onChanged: (value) =>
                            _emit(draft.copyWith(customName: value)),
                        style: theme.textTheme.bodyMedium,
                        decoration: _boxDecoration(context).copyWith(
                          hintText: l10n.customServiceNameHint,
                          counterText: '',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                  _FieldLabel(l10n.priceFieldLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _priceController,
                    enabled: widget.canEdit,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
                    ],
                    onChanged: (value) {
                      final parsed = parseGroupedInt(value);
                      final formatted = parsed == null
                          ? value
                          : formatPriceNumber(parsed);
                      if (formatted != value) {
                        _priceController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }
                      _emit(
                        draft.copyWith(
                          price: parsed,
                          clearPrice: parsed == null || parsed <= 0,
                        ),
                      );
                    },
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    decoration: _boxDecoration(context).copyWith(
                      hintText: '0',
                      suffixText: '₸',
                      suffixStyle: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel(l10n.billingUnit),
                  const SizedBox(height: 6),
                  _OutlineDropdown<PriceRateOption>(
                    value: priceRateOptions.contains(draft.priceRate)
                        ? draft.priceRate
                        : priceRateOptions.firstWhere(
                            (item) => item.value == draft.priceRate.value,
                            orElse: () => priceRateOptions.first,
                          ),
                    hint: l10n.billingUnit,
                    enabled: widget.canEdit,
                    items: priceRateOptions
                        .map(
                          (rate) => DropdownMenuItem(
                            value: rate,
                            child: Text(getPriceRateLabel(rate, l10n)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _emit(draft.copyWith(priceRate: value));
                    },
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel(l10n.howToShowPrice),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ModeChip(
                        label: l10n.priceFrom,
                        selected: draft.isStartingFrom,
                        enabled: widget.canEdit,
                        onTap: () =>
                            _emit(draft.copyWith(isStartingFrom: true)),
                      ),
                      const SizedBox(width: 8),
                      _ModeChip(
                        label: l10n.priceFixed,
                        selected: !draft.isStartingFrom,
                        enabled: widget.canEdit,
                        onTap: () =>
                            _emit(draft.copyWith(isStartingFrom: false)),
                      ),
                    ],
                  ),
                  if (widget.onDelete != null && widget.canEdit) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: widget.onDelete,
                        tooltip: l10n.deletePriceEntry,
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: enabled ? (_) => onTap() : null,
      selectedColor: colorScheme.primary.withValues(alpha: 0.16),
      side: BorderSide(
        color: selected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _OutlineDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final bool enabled;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _OutlineDropdown({
    required this.value,
    required this.hint,
    required this.enabled,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint),
          items: items,
          onChanged: enabled ? onChanged : null,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

InputDecoration _boxDecoration(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.45)),
  );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
    ),
  );
}
