import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/features/equipment/widgets/equipment_info_tile.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/widgets/offer_status_badge.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/tariff_unit_labels.dart';
import 'package:prokat/features/layout/reveal_client_orders_after_tender_accept.dart';
import 'package:prokat/core/media/media_image_provider.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/offers/widgets/offer_flow_card.dart';

class OfferTile extends ConsumerWidget {
  final OfferModel offer;
  final bool isBestPrice;
  final bool showChatAction;

  const OfferTile({
    super.key,
    required this.offer,
    this.isBestPrice = false,
    this.showChatAction = true,
  });

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (ref.read(offerMutationProvider).isSubmitting) {
      return;
    }

    final notifier = ref.read(offerMutationProvider.notifier);
    final navigation = TenderAcceptNavigation.capture(context);
    final refreshedFlow = ProkatFlowScope.maybeOf(context) != null;

    final result = await notifier.acceptOffer(
      offer.id,
      chatId: offer.chatId,
      requestId: offer.requestId,
    );

    AppToast.show(
      message: result.success ? l10n.offerUpdated : l10n.somethingWentWrong,
      type: result.success ? AppToastType.success : AppToastType.error,
    );

    if (result.success) {
      navigation.revealClientOrders(
        chatId: refreshedFlow ? offer.chatId : null,
      );
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (ref.read(offerMutationProvider).isSubmitting) {
      return;
    }

    final notifier = ref.read(offerMutationProvider.notifier);
    final result = await notifier.rejectOffer(
      offer.id,
      chatId: offer.chatId,
      requestId: offer.requestId,
    );

    if (!context.mounted) return;

    AppToast.show(
      message: result.success ? l10n.offerUpdated : l10n.somethingWentWrong,
      type: result.success ? AppToastType.success : AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final flow = ProkatFlowScope.maybeOf(context);
    if (flow != null) {
      final owner = offer.owner;
      final image = mediaImageProvider(ref, owner?.imageUrl);
      final name = owner?.displayName ?? '';
      final initials = name
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .take(2)
          .map((part) => part.characters.first)
          .join()
          .toUpperCase();
      return OfferFlowCard(
        tariffUnitLabel: tariffUnitLabelForUi(
          code: offer.priceRate?.value,
          languageCode: Localizations.localeOf(context).languageCode,
          catalog: ref.watch(catalogProvider).valueOrNull,
          l10n: l10n,
        ),
        offer: offer,
        isBestPrice: isBestPrice,
        submitting: ref.watch(offerMutationProvider).isSubmitting,
        unreadCount: offer.chatId.isEmpty
            ? 0
            : _unreadCountForChat(ref, offer.chatId),
        avatar: CircleAvatar(
          radius: 24,
          backgroundColor: flow.primarySoft,
          backgroundImage: image,
          onBackgroundImageError: image == null
              ? null
              : ignoreMediaImageLoadError,
          child: image != null
              ? null
              : initials.isEmpty
              ? Icon(Icons.person_outline_rounded, color: flow.primary)
              : Text(
                  initials,
                  style: TextStyle(
                    color: flow.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        onChat: !showChatAction || offer.chatId.isEmpty
            ? null
            : () => context.push(
                '${AppRoutes.clientChatList}/direct/${offer.chatId}',
              ),
        onAccept: () => _handleAccept(context, ref, l10n),
        onReject: () => _handleReject(context, ref, l10n),
      );
    }
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final languageCode = Localizations.localeOf(context).languageCode;
    final mutedText = colorScheme.onSurfaceVariant;
    final priceColor = AppTheme.brandTintFg(theme.brightness);

    final equipment = offer.equipment;
    final ownerComment = offer.comment?.trim();

    final isHandled =
        offer.status == OfferStatus.accepted ||
        offer.status == OfferStatus.rejected ||
        offer.status == OfferStatus.expired;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          /// OWNER HEADER
          Row(
            children: [
              Expanded(child: UserInfoTile(user: offer.owner)),

              OfferStatusBadge(status: offer.status),
            ],
          ),

          const SizedBox(height: 14),

          /// EQUIPMENT CARD
          if (equipment != null) EquipmentInfoTile(equipment: equipment),

          const SizedBox(height: 16),

          /// OWNER COMMENT
          if (ownerComment != null && ownerComment.isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ownerComment.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ownerComment,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],

          Row(
            children: [
              /// OFFER RATE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.offeredRate.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mutedText,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatEquipmentPriceLine(
                        price: offer.price,
                        code: offer.priceRate?.value,
                        languageCode: languageCode,
                        catalog: catalog,
                        l10n: l10n,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: priceColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              /// ACTIONS
              if (offer.chatId.isNotEmpty) ...[
                _OfferChatButton(
                  unreadCount: _unreadCountForChat(ref, offer.chatId),
                  onTap: () => context.push(
                    '${AppRoutes.clientChatList}/direct/${offer.chatId}',
                  ),
                ),

                const SizedBox(width: 8),
              ],

              if (!isHandled) ...[
                // Reject Offer
                AppIconButton(
                  onTap: () => ref.watch(offerMutationProvider).isSubmitting
                      ? null
                      : _handleReject(context, ref, l10n),
                  icon: LucideIcons.x,
                  tone: AppIconButtonTone.destructive,
                ),

                const SizedBox(width: 8),

                // Accept Offer
                AppIconButton(
                  onTap: () => ref.watch(offerMutationProvider).isSubmitting
                      ? null
                      : _handleAccept(context, ref, l10n),
                  icon: LucideIcons.check,
                  tone: AppIconButtonTone.success,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

int _unreadCountForChat(WidgetRef ref, String chatId) {
  final items =
      ref.watch(clientChatsProvider).valueOrNull?.items ?? const <ChatModel>[];
  for (final chat in items) {
    if (chat.id == chatId) return chat.newMessagesCount ?? 0;
  }
  return 0;
}

class _OfferChatButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _OfferChatButton({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showCount = unreadCount > 0;
    final label = unreadCount > 99 ? '99+' : '$unreadCount';

    return Badge(
      isLabelVisible: showCount,
      backgroundColor: theme.colorScheme.primary,
      textColor: Colors.white,
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: AppIconButton(
        onTap: onTap,
        icon: LucideIcons.messageCircle,
        tone: AppIconButtonTone.primary,
      ),
    );
  }
}
