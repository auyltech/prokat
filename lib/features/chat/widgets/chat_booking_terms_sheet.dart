import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/owner/owner_offline_guard.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_proposal_card.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_proposal_sheet.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_summary.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ChatBookingTermsSheet extends ConsumerWidget {
  final ChatModel chat;
  final AppMode mode;
  const ChatBookingTermsSheet({
    super.key,
    required this.chat,
    required this.mode,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required ChatModel chat,
    required AppMode mode,
  }) async {
    final palette = ProkatFlowPalette.of(context);
    final edit = await AppBottomSheet.show<bool>(
      context,
      title: AppLocalizations.of(context)!.agreedTermsTitle,
      contentBuilder: (_) => ProkatFlowScope(
        palette: palette,
        child: ChatBookingTermsSheet(chat: chat, mode: mode),
      ),
    );
    if (edit != true || !context.mounted) return;
    final current = ref.read(currentChatProvider(chat.id)).valueOrNull ?? chat;
    final booking = current.booking;
    if (booking == null || current.blockState?.isBlocked == true) return;
    await BookingTermsProposalSheet.show(
      context,
      booking: booking,
      mode: mode,
      chatId: chat.id,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentChatProvider(chat.id)).valueOrNull ?? chat;
    final booking = current.booking;
    if (booking == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final query = priceNegotiationQueryFor(bookingId: booking.id)!;
    final proposals = ref.watch(priceNegotiationsProvider(query));
    final pending = proposals.valueOrNull?.items
        .where((p) => p.isPending)
        .firstOrNull;
    final canEdit =
        BookingTermsProposalSheet.canPropose(booking) &&
        current.status == ChatStatus.active &&
        current.blockState?.isBlocked != true &&
        proposals.hasValue &&
        pending == null;
    final userId = ref.watch(authProvider).session?.user?.id;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingTermsSummary(
          title: l10n.currentOrderTerms,
          price: booking.price,
          priceRate: booking.priceRate,
          bookedOn: booking.bookedOn,
          bookedAt: booking.bookedAt,
          location: booking.location,
        ),
        if (booking.comment?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(booking.comment!),
        ],
        if (proposals.isLoading) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(semanticsLabel: l10n.loading),
        ],
        if (proposals.hasError) ...[
          const SizedBox(height: 16),
          Text(l10n.somethingWentWrongTryAgain),
          TextButton(
            onPressed: () => ref.invalidate(priceNegotiationsProvider(query)),
            child: Text(l10n.retry),
          ),
        ],
        if (pending?.requiresTermsAcknowledgement == true) ...[
          const SizedBox(height: 16),
          BookingTermsProposalCard(
            proposal: pending!,
            isMe: pending.senderId == userId,
            chatId: chat.id,
            mode: mode,
          ),
        ],
        if (canEdit) ...[
          const SizedBox(height: 16),
          ProkatFlowPrimaryButton(
            title: l10n.proposeOrderTerms,
            onPressed: () async {
              if (mode == AppMode.ownerMode) {
                final online = await ensureOwnerOnline(
                  context,
                  ref,
                  message: l10n.ownerOfflineMustBeOnlineToBargain,
                );
                if (!online || !context.mounted) return;
              }
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ],
    );
  }
}
