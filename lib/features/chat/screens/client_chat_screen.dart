import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
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

    final pendingNegotiation = ref
        .watch(priceNegotiationProvider.notifier)
        .getPendingNegotiation(
          bookingId: booking?.id,
          offerId: lastOffer?.id ?? "",
          currentUserId: currentUserId,
          mode: "client",
        );

    final pendingNegotiationId = (pendingNegotiation?.id ?? '').trim();

    final reviewSubmitted =
        (booking?.myReviewId?.isNotEmpty ?? false) ||
        ref.watch(reviewByBookingProvider(booking?.id ?? "")).hasSubmitted;

    final chatConfig = getChatConfig(
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
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(currentChatProvider(widget.chatId).notifier)
                .refresh();
            await ref
                .read(chatMessagesProvider(widget.chatId).notifier)
                .refresh();
          },
          child: chatAsync.when(
            data: (data) => Column(
              children: [
                // 1. Wrap the message state view in Expanded so it occupies available space
                Expanded(
                  child: messagesAsync.when(
                    data: (messagesData) {
                      // Optional: handle empty chat gracefully
                      if (messagesData.items.isEmpty) {
                        return const Center(child: EmptyStateTile());
                      }

                      return ListView.separated(
                        // 2. Set reverse to true so it stays anchored to the bottom like real chat apps
                        reverse: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 12.0,
                        ),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 4),
                        itemCount: messagesData.items.length,
                        itemBuilder: (context, index) {
                          // 3. Since reverse: true handles bottom-up rendering, use direct index access
                          final invertedIndex =
                              messagesData.items.length - 1 - index;
                          final message = messagesData.items[invertedIndex];

                          final isMe =
                              message.senderId == currentUserId ||
                              message.senderId == 'me';

                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            mode: AppMode.clientMode,
                            currentChat: data,
                          );
                        },
                      );
                    },
                    error: (error, stackTrace) =>
                        const Center(child: EmptyStateTile()),
                    loading: () => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                ),

                // 4. Render Action Bar right above the keyboard text field layout
                if (currentChat != null)
                  ChatActionBar(
                    currentChat: currentChat,
                    chatStatus: chatConfig.status,
                    mode: AppMode.clientMode,
                    actionBarTitle: chatConfig.actionBartitle,
                  ),
              ],
            ),
            error: (_, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 160),
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
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
      ),
      bottomNavigationBar: SendMessageForm(
        chatId: widget.chatId,
        chatStatus: chatConfig.status,
        mode: AppMode.clientMode,
      ),
    );
  }
}
