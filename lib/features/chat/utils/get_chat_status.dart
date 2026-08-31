import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/booking_summary_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ChatConfig {
  ChatStatusDetail status;
  String actionBartitle;
  String statusLabel;

  ChatConfig({
    required this.status,
    required this.actionBartitle,
    required this.statusLabel,
  });
}

bool chatHasVisibleActions({
  required ChatStatusDetail status,
  required AppMode mode,
}) {
  switch (status) {
    case ChatStatusDetail.requestcreated:
    case ChatStatusDetail.leaveReview:
      return true;
    case ChatStatusDetail.bookingconfirmed:
      return mode == AppMode.ownerMode;
    case ChatStatusDetail.confirmcompleted:
      return mode == AppMode.clientMode;
    default:
      return false;
  }
}

bool isChatInputLocked(ChatStatusDetail status) {
  switch (status) {
    case ChatStatusDetail.workcompleted:
    case ChatStatusDetail.bookingcancelled:
    case ChatStatusDetail.bookingreviewed:
    case ChatStatusDetail.requestcancelled:
    case ChatStatusDetail.offernotselected:
      return true;
    default:
      return false;
  }
}

ChatConfig getChatConfig({
  ChatModel? chat,
  AppMode? mode,
  bool? hasNegotiation,
  bool? pendingFromMe,
  bool? reviewSubmitted,
  required AppLocalizations l10n,
}) {
  final activeOffer = chat?.offers
      .where((offer) => offer.status == OfferStatus.created)
      .firstOrNull;

  final hasActiveOffer = activeOffer != null;
  final isOfferPendingFromMe =
      mode == AppMode.clientMode && activeOffer != null;

  final bookingStatus =
      chat?.booking?.status ?? _bookingStatusFromSummary(chat?.bookingSummary);
  final workStatus =
      chat?.booking?.workStatus ?? chat?.bookingSummary?.workStatus;

  switch (bookingStatus) {
    case BookingStatus.reviewed:
      {
        return ChatConfig(
          status: ChatStatusDetail.bookingreviewed,
          actionBartitle: l10n.orderCompleted,
          statusLabel: l10n.orderCompleted,
        );
      }

    case BookingStatus.completed:
      if (reviewSubmitted == true) {
        return ChatConfig(
          status: ChatStatusDetail.bookingreviewed,
          actionBartitle: l10n.reviewSent,
          statusLabel: l10n.reviewSent,
        );
      } else {
        return ChatConfig(
          status: ChatStatusDetail.leaveReview,
          actionBartitle: l10n.submitReview,
          statusLabel: l10n.submitReview,
        );
      }

    case BookingStatus.confirmed:
      if (workStatus == WorkStatus.completed) {
        return mode == AppMode.ownerMode
            ? ChatConfig(
                status: ChatStatusDetail.workcompleted,
                actionBartitle: l10n.waitingClientConfirmation,
                statusLabel: l10n.workCompleted,
              )
            : ChatConfig(
                status: ChatStatusDetail.confirmcompleted,
                actionBartitle: l10n.confirmWorkCompleted,
                statusLabel: l10n.confirmWorkCompleted,
              );
      } else {
        return ChatConfig(
          status: ChatStatusDetail.bookingconfirmed,
          actionBartitle: l10n.updateWorkStatus,
          statusLabel: l10n.orderConfirmed,
        );
      }

    case BookingStatus.created:
      if (hasNegotiation == true) {
        return pendingFromMe == true
            ? ChatConfig(
                status: ChatStatusDetail.counterofferreceived,
                actionBartitle: l10n.priceOfferReceived,
                statusLabel: l10n.priceOffer,
              )
            : ChatConfig(
                status: ChatStatusDetail.counteroffersent,
                actionBartitle: mode == AppMode.ownerMode
                    ? l10n.waitingClientResponse
                    : l10n.waitingOwnerResponse,
                statusLabel: l10n.waitingOwnerResponse,
              );
      }

      return ChatConfig(
        status: ChatStatusDetail.bookingcreated,
        actionBartitle: l10n.newOrder,
        statusLabel: l10n.orderCreated,
      );

    case BookingStatus.cancelled:
    case BookingStatus.rejected:
    case BookingStatus.failed:
      return ChatConfig(
        status: ChatStatusDetail.bookingcancelled,
        actionBartitle: l10n.orderHasBeenCancelled,
        statusLabel: l10n.orderCancelled,
      );

    case BookingStatus.draft:
      return ChatConfig(
        status: ChatStatusDetail.unknown,
        actionBartitle: "",
        statusLabel: "",
      );

    case null:
      break;
  }

  switch (chat?.request?.status) {
    case RequestStatus.created:
    case RequestStatus.viewed:
    case RequestStatus.responded:
      if (hasActiveOffer == true) {
        // Request Offer cannot be pending from owner
        if (isOfferPendingFromMe == true) {
          return ChatConfig(
            status: ChatStatusDetail.offerreceived,
            actionBartitle: l10n.offerReceived,
            statusLabel: l10n.offerReceived,
          );
        }

        return ChatConfig(
          status: ChatStatusDetail.offercreated,
          actionBartitle: l10n.offerCreated,
          statusLabel: l10n.offerCreated,
        );
      } else if (hasNegotiation == true) {
        return pendingFromMe == true
            ? ChatConfig(
                status: ChatStatusDetail.counterofferreceived,
                actionBartitle: l10n.respondToCounterOffer,
                statusLabel: l10n.respondToCounterOffer,
              )
            : ChatConfig(
                status: ChatStatusDetail.counteroffersent,
                actionBartitle: l10n.counterOfferSent,
                statusLabel: l10n.counterOfferSent,
              );
      }

      return ChatConfig(
        status: ChatStatusDetail.requestcreated,
        actionBartitle: l10n.requestPending,
        statusLabel: l10n.requestPending,
      );

    case RequestStatus.accepted:
      return ChatConfig(
        status: ChatStatusDetail.offernotselected,
        actionBartitle: l10n.offerNotSelected,
        statusLabel: l10n.offerNotSelected,
      );

    case RequestStatus.cancelled:
    case RequestStatus.expired:
      return ChatConfig(
        status: ChatStatusDetail.requestcancelled,
        actionBartitle: "",
        statusLabel: "",
      );

    case RequestStatus.draft:
    case null:
      break;
  }

  return ChatConfig(
    status: ChatStatusDetail.unknown,
    actionBartitle: "",
    statusLabel: "",
  );
}

BookingStatus? _bookingStatusFromSummary(BookingSummaryModel? summary) {
  final raw = summary?.status.trim() ?? '';
  if (raw.isEmpty) return null;
  return parseBookingStatus(raw);
}
