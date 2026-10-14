import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/providers/open_chat_id_provider.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/chat_message_list.dart';
import 'package:prokat/features/chat/widgets/chat_thread_load_error.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
import 'package:prokat/features/chat/widgets/inquiry_context_card.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ClientChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends ConsumerState<ClientChatScreen> {
  PriceNegotiationQuery? _entryNegotiationQuery;
  OfferQuery? _entryOfferQuery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        try {
          ref.read(clientChatsProvider.notifier).markChatRead(widget.chatId);
          await Future.wait([
            ref.read(currentChatProvider(widget.chatId).notifier).refresh(),
            ref
                .read(chatMessagesProvider(widget.chatId).notifier)
                .refreshIfStale(),
          ]);
          ref
              .read(chatMessagesProvider(widget.chatId).notifier)
              .dismissDisplayedPush();
        } catch (error, stackTrace) {
          Logger.log('ClientChatScreen.initState: $error\n$stackTrace');
        }
      }());
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(openChatRegistrationProvider(widget.chatId));
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final flow = ProkatFlowPalette.of(context);

    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";

    final chatAsync = ref.watch(currentChatProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    final messages = messagesAsync.valueOrNull?.items ?? const [];
    final loadError = chatAsync.error ?? messagesAsync.error;

    final currentChat = chatAsync.valueOrNull;

    final booking = currentChat?.booking;
    final lastOffer = currentChat?.getActiveOffer();
    final requestId = (currentChat?.requestId ?? currentChat?.request?.id ?? '')
        .trim();
    final offerQuery = requestId.isEmpty
        ? null
        : OfferQuery(filter: OfferListFilter.active, requestId: requestId);
    if (offerQuery != null && offerQuery != _entryOfferQuery) {
      _entryOfferQuery = offerQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref.read(clientOffersProvider(offerQuery).notifier).refreshIfStale(),
        );
      });
    }

    final negotiationQuery = priceNegotiationQueryFor(
      bookingId: booking?.id,
      offerId: lastOffer?.id,
    );
    if (negotiationQuery != null &&
        negotiationQuery != _entryNegotiationQuery) {
      _entryNegotiationQuery = negotiationQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref
              .read(priceNegotiationsProvider(negotiationQuery).notifier)
              .refreshIfStale(),
        );
      });
    }
    final negotiations = negotiationQuery == null
        ? const []
        : ref
                  .watch(priceNegotiationsProvider(negotiationQuery))
                  .valueOrNull
                  ?.items ??
              const [];
    final pendingNegotiation = negotiations
        .where((item) => item.status == PriceNegotiationStatus.created)
        .firstOrNull;

    final pendingNegotiationId = (pendingNegotiation?.id ?? '').trim();

    final reviewSubmitted =
        (booking?.myReviewId?.isNotEmpty ?? false) ||
        ref.watch(reviewByBookingProvider(booking?.id ?? "")).hasSubmitted;

    final chatConfig = getChatConfig(
      chat: currentChat,
      hasNegotiation: pendingNegotiationId.isNotEmpty,
      pendingFromMe:
          pendingNegotiationId.isNotEmpty &&
          currentUserId.isNotEmpty &&
          (pendingNegotiation?.senderId ?? '').trim() != currentUserId,
      reviewSubmitted: reviewSubmitted,
      l10n: l10n,
      mode: AppMode.clientMode,
    );

    return ProkatFlowScope(
      palette: flow,
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: flow.filledPrimary,
            onPrimary: Colors.white,
            surface: flow.surface,
            onSurface: flow.title,
            outline: flow.border,
          ),
          bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
            backgroundColor: theme.colorScheme.surface,
          ),
        ),
        child: Scaffold(
          backgroundColor: flow.background,
          body: SafeArea(
            child: Column(
              children: [
                if (currentChat != null &&
                    (currentChat.inquiryEquipment != null ||
                        currentChat.booking?.equipment != null))
                  InquiryContextCard(
                    chat: currentChat,
                    onSetTerms:
                        currentChat.inquiryEquipment != null &&
                            currentChat.bookingId == null &&
                            currentChat.booking == null &&
                            currentChat.blockState?.isBlocked != true
                        ? () {
                            final equipment = currentChat.inquiryEquipment!;
                            ref
                                .read(bookingMutationProvider.notifier)
                                .startBooking(equipment);
                            unawaited(
                              context.push(
                                '${AppRoutes.equipment}/${equipment.id}/${AppRoutes.book}'
                                '?inquiryChatId=${Uri.encodeQueryComponent(widget.chatId)}',
                              ),
                            );
                          }
                        : null,
                  ),
                Expanded(
                  child:
                      (chatAsync.hasError || messagesAsync.hasError) &&
                          messages.isEmpty
                      ? ChatThreadLoadError(
                          error: loadError ?? '',
                          onRetry: () async {
                            await ref
                                .read(
                                  currentChatProvider(widget.chatId).notifier,
                                )
                                .refresh();
                            await ref
                                .read(
                                  chatMessagesProvider(widget.chatId).notifier,
                                )
                                .refresh();
                          },
                        )
                      : chatAsync.isLoading && currentChat == null
                      ? const Center(
                          child: CircularProgressIndicator.adaptive(),
                        )
                      : ChatMessageList(
                          chatId: widget.chatId,
                          currentUserId: currentUserId,
                          mode: AppMode.clientMode,
                          currentChat: currentChat,
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SendMessageForm(
            chatId: widget.chatId,
            chatStatus: chatConfig.status,
            mode: AppMode.clientMode,
            currentChat: currentChat,
            actionBarTitle: chatConfig.actionBartitle,
          ),
        ),
      ),
    );
  }
}
