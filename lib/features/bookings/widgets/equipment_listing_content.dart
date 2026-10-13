import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/media/media_image_provider.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/bookings/widgets/booking_order_fields.dart';
import 'package:prokat/features/bookings/widgets/equipment_image_header.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Shared listing presentation for catalog entry and incoming public links.
/// Booking, authentication and navigation stay with the owning screen.
class EquipmentListingContent extends ConsumerWidget {
  final Equipment equipment;
  final PriceEntry? selectedPrice;
  final ValueChanged<PriceEntry> onPriceChanged;
  final VoidCallback onBack;
  final List<Widget> heroActions;
  final Widget? additionalDetails;

  const EquipmentListingContent({
    super.key,
    required this.equipment,
    required this.selectedPrice,
    required this.onPriceChanged,
    required this.onBack,
    this.heroActions = const [],
    this.additionalDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final prices = bookablePrices(equipment);
    final specs =
        (equipment.specs ?? [])
            .where((s) => s.visibleToClient != false)
            .where(
              (s) => s
                  .displayValue(languageCode: l10n.localeName, catalog: catalog)
                  .isNotEmpty,
            )
            .toList()
          ..sort((a, b) => (a.sortIndex ?? 0).compareTo(b.sortIndex ?? 0));
    final keySpecs = specs.where((s) => s.showInCard != false).take(3).toList();
    final description = equipment.ownerComment?.trim() ?? '';
    final conditions = equipment.rentCondition?.trim() ?? '';
    final topInset = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        EquipmentImageHeader(
          imageUrls: equipment.displayImageUrls,
          height: 290 + topInset,
          overlay: Stack(
            children: [
              // Keep the light system status icons readable on white photos.
              IgnorePointer(
                child: Container(
                  height: topInset + 65,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 0),
                  child: Row(
                    children: [
                      _HeroBackButton(onBack: onBack, label: l10n.back),
                      const Spacer(),
                      for (final action in heroActions) ...[
                        const SizedBox(width: 8),
                        action,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  equipment.name,
                  style: AppFonts.headingL(context).copyWith(color: p.title),
                ),
                if (equipment.model.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    equipment.model,
                    style: AppFonts.body14(context)
                        .copyWith(color: p.secondary),
                  ),
                ],
                const SizedBox(height: 20),
                _ListingOwner(equipment: equipment),
                if (keySpecs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < keySpecs.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: p.border),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  keySpecs[i].displayName(l10n.localeName),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.body14(
                                    context,
                                  ).copyWith(color: p.secondary, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  keySpecs[i].boolValue == null
                                      ? keySpecs[i].displayValue(
                                          languageCode: l10n.localeName,
                                          catalog: catalog,
                                        )
                                      : keySpecs[i].boolValue!
                                      ? l10n.yes
                                      : l10n.no,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.body16SemiBold(context)
                                      .copyWith(color: p.title),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (prices.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.tariffs,
                    style: AppFonts.headingS(context).copyWith(color: p.title),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final price in prices)
                        _TariffCard(
                          price: price,
                          selected:
                              price.id == selectedPrice?.id ||
                              prices.length == 1,
                          onTap: () => onPriceChanged(price),
                        ),
                    ],
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    description,
                    style: AppFonts.body14(context)
                        .copyWith(color: p.secondary, height: 1.6),
                  ),
                ],
                if (conditions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.rentCondition,
                    style: AppFonts.headingS(context).copyWith(color: p.title),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    conditions,
                    style: AppFonts.body14(context)
                        .copyWith(color: p.secondary, height: 1.6),
                  ),
                ],
                if (specs.length > keySpecs.length) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    title: Text(
                      l10n.listingSpecifications,
                      style: AppFonts.body16SemiBold(context)
                          .copyWith(color: p.title),
                    ),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    children: [
                      for (final spec in specs)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  spec.displayName(l10n.localeName),
                                  style: AppFonts.body14(context)
                                      .copyWith(color: p.secondary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  spec.boolValue == null
                                      ? spec.displayValue(
                                          languageCode: l10n.localeName,
                                          catalog: catalog,
                                        )
                                      : spec.boolValue!
                                      ? l10n.yes
                                      : l10n.no,
                                  textAlign: TextAlign.end,
                                  style: AppFonts.body14SemiBold(context)
                                      .copyWith(color: p.title),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                if (additionalDetails != null) ...[
                  const SizedBox(height: 16),
                  additionalDetails!,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBackButton extends StatelessWidget {
  final VoidCallback onBack;
  final String label;
  const _HeroBackButton({required this.onBack, required this.label});
  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: label,
    style: IconButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF142750),
      fixedSize: const Size(44, 44),
    ),
    onPressed: onBack,
    icon: const Icon(LucideIcons.chevronLeft, size: 24),
  );
}

class _ListingOwner extends ConsumerWidget {
  final Equipment equipment;
  const _ListingOwner({required this.equipment});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final owner = equipment.owner;
    final hasImage = owner?.imageUrl?.trim().isNotEmpty == true;
    final online = owner?.isAccountOnline == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: p.primarySoft,
            foregroundColor: p.primary,
            backgroundImage: hasImage
                ? mediaImageProvider(ref, owner!.imageUrl)
                : null,
            onBackgroundImageError: hasImage ? ignoreMediaImageLoadError : null,
            child: hasImage
                ? null
                : const Icon(LucideIcons.userRound, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner?.displayNameOr(l10n.owner) ?? l10n.owner,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body14SemiBold(context)
                      .copyWith(color: p.title),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFBA36),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        (owner?.rating ?? 0) > 0
                            ? '${owner!.rating!.toStringAsFixed(1)} · ${l10n.ordersCount(owner.orderCount ?? 0)}'
                            : l10n.listingNoReviews,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body14(context)
                            .copyWith(color: p.secondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: online
                  ? p.success.withValues(alpha: .12)
                  : p.border.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${online ? '● ' : ''}${online ? l10n.accountOnline : l10n.accountOffline}',
              style: AppFonts.caption(context).copyWith(
                color: online ? p.success : p.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TariffCard extends StatelessWidget {
  final PriceEntry price;
  final bool selected;
  final VoidCallback onTap;
  const _TariffCard({
    required this.price,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final p = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: selected ? p.primarySoft : p.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 155),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? p.primary : p.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                savedTariffTitle(price, l10n) ?? l10n.bookingTariffSingleTitle,
                style: AppFonts.body14(context)
                    .copyWith(color: p.secondary, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                '${price.isStartingFrom ? '${l10n.priceFromPrefix} ' : ''}${formatPrice(price.price)} ${getPriceRate(price.priceRate, l10n: l10n)}',
                style: AppFonts.body16SemiBold(context)
                    .copyWith(color: selected ? p.primary : p.title),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
