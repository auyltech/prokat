import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/owner_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_bar.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const OwnerChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends ConsumerState<OwnerChatScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(chatSocketServiceProvider).joinChat(widget.chatId);

      await ref.read(chatProvider(widget.chatId).notifier).refresh();

      await ref
          .read(chatMessagesProvider(widget.chatId).notifier)
          .refreshIfStale();

      await ref.read(offersProvider.notifier).getOwnerOffers();
    });
  }

  @override
  void didUpdateWidget(covariant OwnerChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      Future.microtask(() async {
        await ref.read(chatSocketServiceProvider).joinChat(widget.chatId);

        await ref.read(chatProvider(widget.chatId).notifier).refresh();

        await ref.read(chatMessagesProvider(widget.chatId).notifier).refresh();

        // ref.read(offersProvider.notifier).getOwnerOffers();
        // ref.read(priceNegotiationProvider.notifier).getPriceNegotiations();
      });
    }
  }

  @override
  void dispose() {
    ref.read(chatSocketServiceProvider).leaveChat(widget.chatId);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";

    final chatAsync = ref.watch(chatProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final currentChat = chatAsync.valueOrNull;
    final messages = messagesAsync.valueOrNull?.items ?? const [];

    final booking = currentChat?.booking;
    final request = currentChat?.request;

    final chatOwnerId = currentChat?.owner?.id;
    final chatClientId = currentChat?.client?.id;

    final hasActiveOffer = ref
        .watch(offersProvider.notifier)
        .hasActiveOffer(request?.id ?? "", "owner");
    // Offer will always be created by owner and responded by client
    final isOfferPendingFromMe = false;

    final lastOffer = ref
        .read(offersProvider.notifier)
        .getLastRequestOffer(request?.id ?? "", "owner");

    final pendingNegotiation = ref
        .watch(priceNegotiationProvider.notifier)
        .getPendingNegotiation(
          bookingId: booking?.id,
          currentUserId: currentUserId,
          mode: "owner",
          offerId: lastOffer?.id ?? "",
        );
    final pendingNegotiationId = (pendingNegotiation?.id ?? '').trim();

    final reviewSubmitted =
        (booking?.myReviewId?.isNotEmpty ?? false) ||
        ref.watch(reviewByBookingProvider(booking?.id ?? "")).hasSubmitted;

    final ChatStatusDetail chatStatus = getChatStatus(
      bookingStatus: booking?.status,
      requestStatus: request?.status,
      hasActiveOffer: hasActiveOffer,
      isOfferPendingFromMe: isOfferPendingFromMe,
      hasNegotiation: pendingNegotiation != null,
      pendingFromMe:
          pendingNegotiationId.isNotEmpty &&
          currentUserId.isNotEmpty &&
          (pendingNegotiation?.senderId ?? '').trim() != currentUserId,
      workStatus: booking?.workStatus,
      reviewSubmitted: reviewSubmitted,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(chatProvider(widget.chatId).notifier).refresh();

          await ref
              .read(chatMessagesProvider(widget.chatId).notifier)
              .refresh();

          // ref.read(requestProvider.notifier).getOwnerRequests();
          // ref.read(offersProvider.notifier).getOwnerOffers();
          // ref.read(bookingProvider.notifier).getOwnerBookings();
          // ref.read(priceNegotiationProvider.notifier).getPriceNegotiations();
        },
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Loading Error Indicator
                if (chatAsync.hasError && messages.isEmpty)
                  Expanded(
                    child: Center(
                      // Centers the entire error block vertically
                      child: SingleChildScrollView(
                        // Prevents overflow on small screens
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh still works
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 48,
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                chatAsync.error.toString(),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await ref
                                      .read(
                                        chatProvider(widget.chatId).notifier,
                                      )
                                      .refresh();

                                  await ref
                                      .read(
                                        chatMessagesProvider(
                                          widget.chatId,
                                        ).notifier,
                                      )
                                      .refresh();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      color: theme.colorScheme.surface,
                      child: ListView.separated(
                        reverse:
                            false, // Newest messages at bottom, oldest + booking tiles at top
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 4),
                        // Increase item count by 2 if booking/request tiles exist
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          // Invert the index so oldest messages (index 0 in data) render at the top
                          final invertedIndex = messages.length - 1 - index;

                          final message = messages[invertedIndex];

                          final isMe =
                              message.senderId == currentUserId ||
                              message.senderId == 'me';
                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            mode: AppMode.ownerMode,
                          );
                        },
                      ),
                    ),
                  ),

                if (booking != null)
                  OwnerChatActionBar(
                    chatId: widget.chatId,
                    chatStatus: chatStatus,
                    booking: booking,
                    chatOwnerId: chatOwnerId,
                    chatClientId: chatClientId,
                  )
                else if (request != null)
                  OfferChatActionBar(
                    chatStatus: chatStatus,
                    chatId: widget.chatId,
                    requestId: request.id,
                    mode: "owner",
                  ),
              ],
            ),

            // Floating Loading Indicator Overlay
            if (messagesAsync.valueOrNull?.isRefreshing == true)
              Positioned(
                top: 16, // Adjust position (e.g., below the app bar)
                left: 0,
                right: 0,
                child: Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    color: theme.colorScheme.surface,
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SendMessageForm(
        chatId: widget.chatId,
        chatStatus: chatStatus,
        mode: AppMode.ownerMode,
      ),
    );
  }
}
