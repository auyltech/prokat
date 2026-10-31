import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/offers/widgets/offer_tile.dart';
import 'package:prokat/features/price_negotiations/widgets/counter_offer_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OfferContextCard extends ConsumerWidget {
  const OfferContextCard({super.key, required this.chat, required this.mode});
  final ChatModel chat;
  final AppMode mode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = chat.getActiveOffer();
    if (offer == null || chat.bookingId != null) return const SizedBox.shrink();
    final p = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async => AppBottomSheet.show<void>(
            context,
            title: l10n.inquiryCreateOrder,
            contentBuilder: (sheetContext) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mode == AppMode.clientMode)
                  OfferTile(offer: offer, showChatAction: false)
                else
                  Text(
                    formatPrice(offer.price),
                    style: AppFonts.headingS(context),
                  ),
                const SizedBox(height: 12),
                AppOutlinedButton(
                  title: l10n.counter,
                  onTap:
                      offer.priceRate == null ||
                          chat.blockState?.isBlocked == true
                      ? null
                      : () async {
                          Navigator.of(sheetContext).pop();
                          await CounterOfferSheet.show(
                            context,
                            offerId: offer.id,
                            chatId: chat.id,
                            initialPrice: offer.price,
                            initialPriceRate: offer.priceRate,
                            mode: mode,
                          );
                        },
                ),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 54,
                    child: OptimizedNetworkImage(
                      imageUrl: offer.equipment?.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.equipment?.name ?? l10n.offer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.title,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${l10n.inquiryStatus} · ${l10n.inquiryCreateOrder}',
                        maxLines: 2,
                        style: TextStyle(color: p.secondary, fontSize: 12),
                      ),
                      Text(
                        formatPrice(offer.price),
                        style: TextStyle(
                          color: p.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: p.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
