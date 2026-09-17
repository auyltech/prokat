import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter/services.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/max_int_input_formatter.dart';
import 'package:prokat/features/equipment/utils/equipment_limits.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerTariffCard extends StatefulWidget {
  final TariffDraft draft;
  final bool canEdit;
  final ValueChanged<TariffDraft> onChanged;
  final VoidCallback? onCommit;
  final VoidCallback? onDelete;

  const OwnerTariffCard({
    super.key,
    required this.draft,
    required this.canEdit,
    required this.onChanged,
    this.onCommit,
    this.onDelete,
  });

  @override
  State<OwnerTariffCard> createState() => _OwnerTariffCardState();
}

class _OwnerTariffCardState extends State<OwnerTariffCard> {
  late TextEditingController _priceController;
  late TextEditingController _customNameController;
  late FocusNode _priceFocus;
  late FocusNode _customNameFocus;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.draft.hasPrice ? '${widget.draft.price}' : '',
    );
    _customNameController = TextEditingController(
      text: widget.draft.customName,
    );
    _priceFocus = FocusNode()..addListener(_onPriceFocusChange);
    _customNameFocus = FocusNode()..addListener(_onCustomNameFocusChange);
  }

  @override
  void didUpdateWidget(covariant OwnerTariffCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.price != widget.draft.price) {
      final next = widget.draft.hasPrice ? '${widget.draft.price}' : '';
      if (_priceController.text != next && !_priceFocus.hasFocus) {
        _priceController.text = next;
      }
    }
    if (oldWidget.draft.customName != widget.draft.customName &&
        _customNameController.text != widget.draft.customName &&
        !_customNameFocus.hasFocus) {
      _customNameController.text = widget.draft.customName;
    }
  }

  @override
  void dispose() {
    _priceFocus
      ..removeListener(_onPriceFocusChange)
      ..dispose();
    _customNameFocus
      ..removeListener(_onCustomNameFocusChange)
      ..dispose();
    _priceController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  void _emit(TariffDraft next) => widget.onChanged(next);

  void _emitAndCommit(TariffDraft next) {
    _emit(next);
    widget.onCommit?.call();
  }

  void _onPriceFocusChange() {
    if (!_priceFocus.hasFocus) widget.onCommit?.call();
  }

  void _onCustomNameFocusChange() {
    if (!_customNameFocus.hasFocus) widget.onCommit?.call();
  }

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
                    AppDropdownField<String>(
                      label: l10n.serviceType,
                      value: draft.labelKey.isEmpty ? null : draft.labelKey,
                      hint: l10n.serviceType,
                      enabled: widget.canEdit,
                      sheetTitle: l10n.serviceType,
                      options: vacuumServiceTypeKeys
                          .map(
                            (key) => DropdownOption(
                              value: key,
                              label: tariffServiceOptionLabel(key, l10n),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        _emitAndCommit(draft.copyWith(labelKey: value));
                      },
                    ),
                    if (draft.labelKey == vacuumTariffOther) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        label: l10n.customServiceName,
                        controller: _customNameController,
                        focusNode: _customNameFocus,
                        enabled: widget.canEdit,
                        maxLength: 40,
                        onChanged: (value) =>
                            _emit(draft.copyWith(customName: value)),
                        hint: l10n.customServiceNameHint,
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                  AppTextField(
                    label: l10n.priceFieldLabel,
                    controller: _priceController,
                    focusNode: _priceFocus,
                    enabled: widget.canEdit,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      const MaxIntInputFormatter(ownerEquipmentPriceMax),
                    ],
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      _emit(
                        draft.copyWith(
                          price: parsed,
                          clearPrice: parsed == null || parsed <= 0,
                        ),
                      );
                    },
                    hint: '0',
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        '₸',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppDropdownField<PriceRateOption>(
                    label: l10n.billingUnit,
                    value: priceRateOptions.contains(draft.priceRate)
                        ? draft.priceRate
                        : priceRateOptions.firstWhere(
                            (item) => item.value == draft.priceRate.value,
                            orElse: () => priceRateOptions.first,
                          ),
                    hint: l10n.billingUnit,
                    enabled: widget.canEdit,
                    sheetTitle: l10n.billingUnit,
                    options: priceRateOptions
                        .map(
                          (rate) => DropdownOption(
                            value: rate,
                            label: getPriceRateLabel(rate, l10n),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      _emitAndCommit(draft.copyWith(priceRate: value));
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
                        onTap: () => _emitAndCommit(
                          draft.copyWith(isStartingFrom: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ModeChip(
                        label: l10n.priceFixed,
                        selected: !draft.isStartingFrom,
                        enabled: widget.canEdit,
                        onTap: () => _emitAndCommit(
                          draft.copyWith(isStartingFrom: false),
                        ),
                      ),
                    ],
                  ),
                  if (widget.onDelete != null && widget.canEdit) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppIconButton(
                        onTap: widget.onDelete,
                        tooltip: l10n.deletePriceEntry,
                        icon: Icons.delete_outline,
                        tone: AppIconButtonTone.destructive,
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
