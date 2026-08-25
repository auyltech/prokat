import 'package:flutter/material.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/requests/widgets.dart/client_request_tile.dart';
import 'package:prokat/features/requests/widgets.dart/request_offers_expandable.dart'
    hide Divider;
import 'package:prokat/features/requests/widgets.dart/request_offers_header.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RequestWithOffers extends StatefulWidget {
  final dynamic request;
  final List<dynamic> offers;
  final VoidCallback onCancel;

  const RequestWithOffers({
    super.key,
    required this.request,
    required this.offers,
    required this.onCancel,
  });

  @override
  State<RequestWithOffers> createState() => _RequestWithOffersState();
}

class _RequestWithOffersState extends State<RequestWithOffers>
    with SingleTickerProviderStateMixin {
  static const _expandDuration = Duration(milliseconds: 360);

  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    switch (_controller.status) {
      case AnimationStatus.completed:
      case AnimationStatus.forward:
        _controller.reverse();
      case AnimationStatus.dismissed:
      case AnimationStatus.reverse:
        _controller.forward();
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
