import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/max_int_input_formatter.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
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

  bool _serviceTypeError = false;
  bool _customNameError = false;
  bool _priceError = false;
  bool _billingUnitError = false;

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
    if (next.isSavable) {
      widget.onCommit?.call();
    }
  }

  void _validateServiceType() {
    _serviceTypeError = !widget.draft.isPreset && widget.draft.labelKey.isEmpty;
  }

  void _validateCustomName() {
    _customNameError =
        widget.draft.labelKey == vacuumTariffOther &&
        _customNameController.text.trim().isEmpty;
  }

  void _validatePrice() {
    final parsed = int.tryParse(_priceController.text.trim());
    _priceError = parsed == null || parsed <= 0;
  }

  void _validateBillingUnit() {
    _billingUnitError =
        !priceRateOptions.contains(widget.draft.priceRate) &&
        !priceRateOptions.any(
          (item) => item.value == widget.draft.priceRate.value,
        );
  }

  void _onPriceFocusChange() {
    if (_priceFocus.hasFocus || !widget.canEdit) return;
    setState(_validatePrice);
    if (_priceError || !widget.draft.isSavable) return;
    widget.onCommit?.call();
  }

  void _onCustomNameFocusChange() {
    if (_customNameFocus.hasFocus || !widget.canEdit) return;
    setState(_validateCustomName);
    if (_customNameError || !widget.draft.isSavable) return;
    widget.onCommit?.call();
  }

  void _onServiceTypeFocusLost() {
    if (!widget.canEdit) return;
    setState(_validateServiceType);
  }

  void _onBillingUnitFocusLost() {
    if (!widget.canEdit) return;
    setState(_validateBillingUnit);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;
    final isLocalDraft = draft.isLocalDraft;
    final showDelete = widget.onDelete != null && widget.canEdit;
    const cardRadius = BorderRadius.all(Radius.circular(AppDimens.r16$xl));
    const headerExpandedRadius = BorderRadius.vertical(
      top: Radius.circular(AppDimens.r16$xl),
    );
    final headerRadius = draft.expanded ? headerExpandedRadius : cardRadius;
    final emptyError = l10n.cannotBeEmpty;
    final titleStyle = AppFonts.headingS(context);

    final card = Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: isLocalDraft
            ? BorderSide.none
            : BorderSide(
                color: colors.borders.main,
                width: AppDimens.inputBorderWidth,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: widget.canEdit
                ? () => _emit(draft.copyWith(expanded: !draft.expanded))
                : null,
            borderRadius: headerRadius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.s16$base,
                AppDimens.s12$md,
                AppDimens.s12$md,
                AppDimens.s12$md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppDimens.s04$xs,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: titleStyle,
                            children: [
                              if (isLocalDraft)
                                TextSpan(text: '${l10n.tariffDraftPrefix} '),
                              TextSpan(text: draft.title(l10n)),
                            ],
                          ),
                        ),
                        Text(
                          draft.collapsedSubtitle(l10n),
                          style: AppFonts.body16(context).copyWith(
                            color: draft.hasPrice
                                ? colors.text.main
                                : colors.text.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppDimens.s12$md,
                    children: [
                      if (showDelete)
                        AppIconButton(
                          icon: Icons.delete_outline,
                          onTap: widget.onDelete,
                          tooltip: l10n.deletePriceEntry,
                          tone: AppIconButtonTone.destructive,
                        ),
                      Icon(
                        draft.expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: colors.text.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (draft.expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.s16$base,
                0,
                AppDimens.s16$base,
                AppDimens.s16$base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppDimens.s16$base,
                children: [
                  if (!draft.isPreset) ...[
                    AppDropdownField<String>(
                      title: l10n.serviceType,
                      isRequired: true,
                      value: draft.labelKey.isEmpty ? null : draft.labelKey,
                      hint: l10n.serviceType,
                      enabled: widget.canEdit,
                      readOnly: !widget.canEdit,
                      sheetTitle: l10n.serviceType,
                      errorText: _serviceTypeError ? emptyError : null,
                      onFocusLost: _onServiceTypeFocusLost,
                      options: vacuumServiceTypeKeys
                          .map(
                            (key) => DropdownOption(
                              value: key,
                              label: tariffServiceOptionLabel(key, l10n),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _serviceTypeError = false;
                          if (value != vacuumTariffOther) {
                            _customNameError = false;
                          }
                        });
                        _emitAndCommit(draft.copyWith(labelKey: value));
                      },
                    ),
                    if (draft.labelKey == vacuumTariffOther)
                      AppTextField(
                        title: l10n.customServiceName,
                        isRequired: true,
                        controller: _customNameController,
                        focusNode: _customNameFocus,
                        enabled: widget.canEdit,
                        readOnly: !widget.canEdit,
                        maxLength: 40,
                        errorText: _customNameError ? emptyError : null,
                        onChanged: (value) {
                          if (_customNameError && value.trim().isNotEmpty) {
                            setState(() => _customNameError = false);
                          }
                          _emit(draft.copyWith(customName: value));
                        },
                        hint: l10n.customServiceNameHint,
                      ),
                  ],
                  AppTextField(
                    title: l10n.priceFieldLabel,
                    isRequired: true,
                    controller: _priceController,
                    focusNode: _priceFocus,
                    enabled: widget.canEdit,
                    readOnly: !widget.canEdit,
                    keyboardType: TextInputType.number,
                    errorText: _priceError ? emptyError : null,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      const MaxIntInputFormatter(ownerEquipmentPriceMax),
                    ],
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (_priceError && parsed != null && parsed > 0) {
                        setState(() => _priceError = false);
                      }
                      _emit(
                        draft.copyWith(
                          price: parsed,
                          clearPrice: parsed == null || parsed <= 0,
                        ),
                      );
                    },
                    hint: '0',
                    prefix: Text(
                      '₸',
                      style: AppFonts.body16SemiBold(context)
                          .copyWith(color: colors.text.secondary),
                    ),
                  ),
                  AppDropdownField<PriceRateOption>(
                    title: l10n.billingUnit,
                    isRequired: true,
                    value: priceRateOptions.contains(draft.priceRate)
                        ? draft.priceRate
                        : priceRateOptions.firstWhere(
                            (item) => item.value == draft.priceRate.value,
                            orElse: () => priceRateOptions.first,
                          ),
                    hint: l10n.billingUnit,
                    enabled: widget.canEdit,
                    readOnly: !widget.canEdit,
                    sheetTitle: l10n.billingUnit,
                    errorText: _billingUnitError ? emptyError : null,
                    onFocusLost: _onBillingUnitFocusLost,
                    options: priceRateOptions
                        .map(
                          (rate) => DropdownOption(
                            value: rate,
                            label: getPriceRateLabel(rate, l10n),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _billingUnitError = false);
                      _emitAndCommit(draft.copyWith(priceRate: value));
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppDimens.inputLabelGap,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: l10n.howToShowPrice,
                          style: AppFonts.headingS(context),
                          children: [
                            if (widget.canEdit)
                              TextSpan(
                                text: ' *',
                                style: AppFonts.headingS(context)
                                    .copyWith(color: colors.text.error),
                              ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: AppDimens.s08$sm,
                        runSpacing: AppDimens.s08$sm,
                        children: [
                          AppLabelButton(
                            title: l10n.priceFrom,
                            onTap: widget.canEdit
                                ? () => _emitAndCommit(
                                    draft.copyWith(isStartingFrom: true),
                                  )
                                : null,
                            variant: draft.isStartingFrom
                                ? AppLabelButtonVariant.filled
                                : AppLabelButtonVariant.outlined,
                            tone: AppLabelButtonTone.primary,
                          ),
                          AppLabelButton(
                            title: l10n.priceFixed,
                            onTap: widget.canEdit
                                ? () => _emitAndCommit(
                                    draft.copyWith(isStartingFrom: false),
                                  )
                                : null,
                            variant: !draft.isStartingFrom
                                ? AppLabelButtonVariant.filled
                                : AppLabelButtonVariant.outlined,
                            tone: AppLabelButtonTone.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    if (!isLocalDraft) return card;

    return CustomPaint(
      painter: _DashedRRectPainter(
        color: colors.borders.main,
        radius: const Radius.circular(AppDimens.r16$xl),
        strokeWidth: AppDimens.inputBorderWidth,
      ),
      child: card,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final Radius radius;
  final double strokeWidth;

  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          radius,
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(_dashPath(path), paint);
  }

  Path _dashPath(Path source) {
    const dash = 6.0;
    const gap = 4.0;
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final next = (distance + (draw ? dash : gap)).clamp(0.0, metric.length);
        if (draw) {
          dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        }
        distance = next;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
