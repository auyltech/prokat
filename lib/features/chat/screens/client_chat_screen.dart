import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/chat_message_list.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
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
      ref.read(currentChatProvider(widget.chatId).notifier).refreshIfStale();
      ref.read(chatMessagesProvider(widget.chatId).notifier).refreshIfStale();
      ref
          .read(chatMessagesProvider(widget.chatId).notifier)
          .dismissDisplayedPush();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";

    final chatAsync = ref.watch(currentChatProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

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
        ref.read(clientOffersProvider(offerQuery).notifier).refreshIfStale();
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
        ref
            .read(priceNegotiationsProvider(negotiationQuery).notifier)
            .refreshIfStale();
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

    return Scaffold(
      body: SafeArea(
        child: chatAsync.when(
          data: (data) => ChatMessageList(
            chatId: widget.chatId,
            currentUserId: currentUserId,
            mode: AppMode.clientMode,
            currentChat: data,
          ),
          error: (_, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 160),
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                loadError.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(currentChatProvider(widget.chatId).notifier)
                        .refresh();
                    await ref
                        .read(chatMessagesProvider(widget.chatId).notifier)
                        .refresh();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ),
            ],
          ),
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
      bottomNavigationBar: SendMessageForm(
        chatId: widget.chatId,
        chatStatus: chatConfig.status,
        mode: AppMode.clientMode,
        currentChat: currentChat,
        actionBarTitle: chatConfig.actionBartitle,
      ),
    );
  }
}
