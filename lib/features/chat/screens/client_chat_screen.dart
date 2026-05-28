import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/client_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/booking_message_bubble.dart';
import 'package:prokat/features/chat/widgets/request_header_bubble.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
import 'package:prokat/features/chat/widgets/user_avatar.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/providers/offers_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ClientChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends ConsumerState<ClientChatScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider.notifier).openChatById(widget.chatId);
      // ref.read(offersProvider.notifier).getUserOffers();
    });
  }

  @override
  void didUpdateWidget(covariant ClientChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      Future.microtask(() {
        ref.read(chatProvider.notifier).reloadChat(widget.chatId);
        // ref.read(offersProvider.notifier).getUserOffers();
      });
    }
  }

  @override
  void dispose() {
    ref.read(chatProvider.notifier).leaveCurrentChat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Get current User
    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";

    final chatState = ref.watch(chatProvider);
    final currentChat = chatState.currentChat;
    final messages = chatState.messages;

    final title = currentChat?.displayTitle(currentUserId) ?? 'Chat';
    final avatarUrl = currentChat?.displayImageUrl(
      currentUserId: currentUserId,
    );

    final booking = currentChat?.booking;
    final request = currentChat?.request;

    final chatOwnerId = currentChat?.owner?.id;
    final chatClientId = currentChat?.client?.id;

    final offersState = ref.watch(offersProvider);

    final negotiation = ref.watch(
      priceNegotiationByBookingProvider(booking?.id ?? ""),
    );

    final reviewSubmitted =
        (booking?.myReviewId?.isNotEmpty ?? false) ||
        ref.watch(reviewByBookingProvider(booking?.id ?? "")).hasSubmitted;

    final pending = negotiation.latestPending;
    final pendingId = (pending?.id ?? '').trim();

    final userId = (currentUserId).trim();

    final ChatStatus chatStatus = getChatStatus(
      bookingStatus: booking?.status ?? BookingStatus.created.name,
      hasNegotiation: pendingId.isNotEmpty,
      pendingFromMe:
          pendingId.isNotEmpty &&
          userId.isNotEmpty &&
          (pending?.senderId ?? '').trim() != userId,
      workStatus: booking?.workStatus ?? WorkStatus.pending,
      reviewSubmitted: reviewSubmitted,
    );

    // Hold offer for this chat
    OfferModel? requestOffer;
    // Find the offer related to this chat, ie request
    if (request != null) {
      for (final offer in offersState.renterOffers) {
        if (offer.requestId == request.id) {
          requestOffer = offer;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () async {
            if (!context.mounted) return;
            context.pop();

            await ref.read(chatProvider.notifier).leaveCurrentChat();
          },
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            context.push('${AppRoutes.chat}/${widget.chatId}/info');
          },
          child: Row(
            children: [
              UserAvatar(radius: 22, avatarUrl: avatarUrl, fullName: title),
              // CircleAvatar(
              //   radius: 18,
              //   backgroundImage: (avatarUrl ?? '').isNotEmpty
              //       ? NetworkImage(avatarUrl!)
              //       : null,
              //   child: (avatarUrl ?? '').isEmpty
              //       ? Text(title.isNotEmpty ? title[0].toUpperCase() : 'C')
              //       : null,
              // ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    if (messages.lastOrNull != null)
                      Text(
                        formatDateTime(
                          messages.last.createdAt,
                          messages.last.createdAt,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(chatProvider.notifier).reloadChat(widget.chatId);
        },
        child: Column(
          children: [
            if (chatState.isLoadingMessages)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (chatState.error != null && messages.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          chatState.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(chatProvider.notifier)
                              .openChatById(widget.chatId),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  color: theme.colorScheme.surface,
                  child: ListView.separated(
                    reverse: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    separatorBuilder: (context, index) => SizedBox(height: 4),
                    itemCount: (booking != null || request != null)
                        ? messages.length + 1
                        : messages.length,
                    itemBuilder: (context, index) {
                      final hasBookingHeader =
                          booking != null || request != null;

                      if (hasBookingHeader) {
                        if (index == 0) {
                          if (booking != null) {
                            return BookingMessageBubble(booking: booking);
                          }
                          if (request != null) {
                            return RequestHeaderBubble(request: request);
                          }
                          return const SizedBox.shrink();
                        }
                      }

                      // 1. Shift index by 1 if header is present
                      final messageIndex = hasBookingHeader ? index - 1 : index;

                      // 2. Invert the index so oldest messages (index 0 in data) render at the top
                      final invertedIndex = messages.length - 1 - messageIndex;

                      final message = messages[invertedIndex];
                      final isMe =
                          message.senderId == currentUserId ||
                          message.senderId == 'me';

                      return MessageBubble(message: message, isMe: isMe);
                    },
                  ),
                ),
              ),

            if (booking != null)
              ClientChatActionBar(
                chatId: widget.chatId,
                booking: booking,
                chatOwnerId: chatOwnerId,
                chatClientId: chatClientId,
              ),

            if (booking == null && request != null && requestOffer != null)
              OfferChatActionBar(
                chatId: widget.chatId,
                offer: requestOffer,
                type: "CLIENT_COUNTER",
              ),

            // 2. Static input area perfectly pinned to the absolute viewport bottom
            if ((booking?.status ?? '').trim().toLowerCase() == 'reviewed')
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(color: theme.cardColor),
                child: SafeArea(
                  top: false,
                  child: Text(
                    'Chat locked',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    // top: BorderSide(
                    //   color: theme.dividerColor.withValues(alpha: 0.2),
                    //   width: 1.0,
                    // ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  bottom:
                      true, // Offsets input safely away from home system bar pill
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 0.0,
                      bottom: 12.0,
                    ), // Extra layout lift padding
                    child: SendMessageForm(chatStatus: chatStatus),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
