import 'package:flutter/material.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/widgets/offer_tile.dart';

class RequestOffersExpandable extends StatelessWidget {
  final Animation<double> animation;
  final List<OfferModel> offers;

  const RequestOffersExpandable({
    super.key,
    required this.animation,
    required this.offers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadowColor = theme.colorScheme.shadow.withValues(alpha: 0.18);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return IgnorePointer(ignoring: animation.value == 0, child: child);
      },
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: offers.length,
                    itemBuilder: (context, index) =>
                        OfferTile(offer: offers[index]),
                    separatorBuilder: (context, _) => Divider(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      thickness: 1,
                      endIndent: 16,
                      indent: 16,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const SizedBox(height: 1),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 14,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
