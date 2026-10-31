import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/offers/offer_price_selection.dart';
import 'package:prokat/features/requests/widgets.dart/client_request_tile.dart';
import 'package:prokat/features/requests/widgets.dart/request_offers_expandable.dart';
import 'package:prokat/features/requests/widgets.dart/request_offers_header.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RequestWithOffers extends StatefulWidget {
  final dynamic request;
  final List<dynamic> offers;
  final VoidCallback onCancel;
  final bool offersLoaded;
  final bool offersComplete;
  final bool offersLoading;
  final VoidCallback? onLoadAllOffers;

  const RequestWithOffers({
    super.key,
    required this.request,
    required this.offers,
    required this.onCancel,
    this.offersLoaded = true,
    this.offersComplete = true,
    this.offersLoading = false,
    this.onLoadAllOffers,
  });

  @override
  State<RequestWithOffers> createState() => _RequestWithOffersState();
}

class _RequestWithOffersState extends State<RequestWithOffers>
    with SingleTickerProviderStateMixin {
  static const _expandDuration = Duration(milliseconds: 360);

  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _flowInitialized = false;
  String? _selectedUnit;
  OfferPriceOrder _priceOrder = OfferPriceOrder.original;
  bool _bestOnly = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _expandDuration,
      value: 0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_flowInitialized && ProkatFlowScope.maybeOf(context) != null) {
      _controller.value = 1;
      _flowInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    switch (_controller.status) {
      case AnimationStatus.completed:
      case AnimationStatus.forward:
        unawaited(_controller.reverse());
      case AnimationStatus.dismissed:
      case AnimationStatus.reverse:
        unawaited(_controller.forward());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasOffers = widget.offers.isNotEmpty;

    final pendingOffers = widget.offers
        .whereType<OfferModel>()
        .where(
          (item) =>
              item.status == OfferStatus.created ||
              item.status == OfferStatus.viewed,
        )
        .toList();

    final flow = ProkatFlowScope.maybeOf(context);
    if (flow != null) {
      final selection = OfferPriceSelection(
        pendingOffers,
        selectedUnit: _selectedUnit,
      );
      final visible = selection.visible(
        order: widget.offersComplete ? _priceOrder : OfferPriceOrder.original,
        bestOnly: widget.offersComplete && _bestOnly,
        selectedUnit: _selectedUnit,
      );
      final canCompare = widget.offersComplete && selection.canCompare;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientRequestTile(
            request: widget.request,
            offerCount: widget.offersLoaded ? pendingOffers.length : null,
          ),
          if (pendingOffers.isNotEmpty) ...[
            const SizedBox(height: 12),
            RequestOffersHeader(
              title: l10n.requestOwnerOffers,
              animation: _expandAnimation,
              onTap: _toggle,
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selection.units.length > 1 ||
                        _selectedUnit != null) ...[
                      Text(
                        l10n.offerCompareUnit,
                        style: TextStyle(color: flow.secondary, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.offerCompareAllUnits),
                            backgroundColor: flow.surface,
                            selectedColor: flow.primarySoft,
                            checkmarkColor: flow.primary,
                            side: BorderSide(color: flow.border),
                            labelStyle: TextStyle(
                              color: flow.title,
                              fontSize: 13,
                            ),
                            selected:
                                _selectedUnit == null ||
                                !selection.units.any(
                                  (unit) => unit.value == _selectedUnit,
                                ),
                            onSelected: (_) => setState(() {
                              _selectedUnit = null;
                              _bestOnly = false;
                              _priceOrder = OfferPriceOrder.original;
                            }),
                          ),
                          for (final unit in selection.units)
                            ChoiceChip(
                              label: Text(getPriceRateLabel(unit, l10n)),
                              backgroundColor: flow.surface,
                              selectedColor: flow.primarySoft,
                              checkmarkColor: flow.primary,
                              side: BorderSide(color: flow.border),
                              labelStyle: TextStyle(
                                color: flow.title,
                                fontSize: 13,
                              ),
                              selected: _selectedUnit == unit.value,
                              onSelected: (_) => setState(() {
                                _selectedUnit = unit.value;
                                _bestOnly = false;
                              }),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final sort = DropdownButtonFormField<OfferPriceOrder>(
                          key: ValueKey(
                            '${selection.effectiveUnit}-${_priceOrder.name}-$canCompare',
                          ),
                          initialValue: canCompare
                              ? _priceOrder
                              : OfferPriceOrder.original,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: flow.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: flow.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: flow.border),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: flow.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: flow.primary),
                            ),
                          ),
                          style: TextStyle(color: flow.title, fontSize: 13),
                          items: [
                            DropdownMenuItem(
                              value: OfferPriceOrder.original,
                              child: Text(
                                l10n.offerPriceSortDefault,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: OfferPriceOrder.lowestFirst,
                              child: Text(
                                l10n.offerPriceSortLow,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: OfferPriceOrder.highestFirst,
                              child: Text(
                                l10n.offerPriceSortHigh,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: canCompare
                              ? (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _priceOrder = value;
                                    _bestOnly = false;
                                  });
                                }
                              : null,
                        );
                        final best = FilterChip(
                          label: Text(l10n.offerBestPrice),
                          selected: canCompare && _bestOnly,
                          selectedColor: flow.primarySoft,
                          backgroundColor: flow.surface,
                          checkmarkColor: flow.primary,
                          side: BorderSide(color: flow.border),
                          labelStyle: TextStyle(
                            color: flow.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: canCompare
                              ? (selected) {
                                  setState(() => _bestOnly = selected);
                                }
                              : null,
                        );
                        if (constraints.maxWidth < 340 ||
                            MediaQuery.textScalerOf(context).scale(13) > 17) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [sort, const SizedBox(height: 4), best],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: sort),
                            const SizedBox(width: 8),
                            best,
                          ],
                        );
                      },
                    ),
                    if (selection.units.length > 1 &&
                        !selection.canCompare) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.offerCompareUnitHint,
                        style: TextStyle(color: flow.secondary, fontSize: 12),
                      ),
                    ],
                    if (!widget.offersComplete) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.offerPricesPartialHint,
                        style: TextStyle(color: flow.secondary, fontSize: 12),
                      ),
                      if (widget.onLoadAllOffers != null)
                        TextButton.icon(
                          onPressed: widget.offersLoading
                              ? null
                              : widget.onLoadAllOffers,
                          icon: widget.offersLoading
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 18),
                          label: Text(l10n.offerLoadAll),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            RequestOffersExpandable(
              animation: _expandAnimation,
              offers: visible,
              bestOfferIds: widget.offersComplete
                  ? selection.bestIds
                  : const {},
            ),
          ],
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientRequestTile(request: widget.request),
          if (hasOffers) ...[
            Divider(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              height: 1,
              thickness: 1,
            ),
            RequestOffersHeader(
              title: l10n.offersReceivedCount(widget.offers.length),
              animation: _expandAnimation,
              onTap: _toggle,
            ),
            if (pendingOffers.isNotEmpty)
              RequestOffersExpandable(
                animation: _expandAnimation,
                offers: pendingOffers,
              ),
          ],
        ],
      ),
    );
  }
}
