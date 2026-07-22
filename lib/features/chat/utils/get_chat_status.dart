import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/l10n/app_localizations.dart';

ChatStatusDetail getChatStatus({
  ChatModel? chat,
  AppMode? mode,
  bool? hasNegotiation,
  bool? pendingFromMe,
  bool? reviewSubmitted,
}) {
  final requestStatus = chat?.request?.status;
  final bookingStatus = chat?.booking?.status;
  final workStatus = chat?.booking?.workStatus;
  final activeOffer = chat?.offers
      .where((offer) => offer.status == OfferStatus.created)
      .firstOrNull;

  final hasActiveOffer = activeOffer != null;
  final isOfferPendingFromMe =
      mode == AppMode.clientMode && activeOffer != null;

  // Request Created
  if (requestStatus == RequestStatus.responded) {
    if (hasActiveOffer == true) {
      // Request Offer cannot be pending from owner
      if (isOfferPendingFromMe == true) {
        return ChatStatusDetail.offerreceived;
      }

      return ChatStatusDetail.offercreated;
    } else if (hasNegotiation == true) {
      return pendingFromMe == true
          ? ChatStatusDetail.counterofferreceived
          : ChatStatusDetail.counteroffersent;
    }

    return ChatStatusDetail.requestcreated;
  }

  if (bookingStatus == BookingStatus.created) {
    if (hasNegotiation == true) {
      return pendingFromMe == true
          ? ChatStatusDetail.counterofferreceived
          : ChatStatusDetail.counteroffersent;
    }

    return ChatStatusDetail.bookingcreated;
  }

  if (bookingStatus == BookingStatus.confirmed) {
    if (workStatus == WorkStatus.completed) {
      return ChatStatusDetail.workcompleted;
    }

    return ChatStatusDetail.bookingconfirmed;
  }

  if (bookingStatus == BookingStatus.completed) {
    if (reviewSubmitted == true) {
      return ChatStatusDetail.bookingreviewed;
    }

    return ChatStatusDetail.leaveReview;
  }

  if (bookingStatus == BookingStatus.reviewed) {
    return ChatStatusDetail.bookingreviewed;
  }

  if (bookingStatus == BookingStatus.cancelled ||
      bookingStatus == BookingStatus.rejected ||
      bookingStatus == BookingStatus.failed) {
    return ChatStatusDetail.bookingcancelled;
  }

  if (requestStatus == RequestStatus.created ||
      requestStatus == RequestStatus.accepted) {
    return ChatStatusDetail.requestaccepted;
  }

  return ChatStatusDetail.unknown;
}

String getChatActionBarTitle(ChatStatusDetail status, AppLocalizations l10n) {
  switch (status) {
    case ChatStatusDetail.requestcreated:
      return l10n.requestPending;

    case ChatStatusDetail.offercreated:
      return l10n.offerCreated;

    case ChatStatusDetail.offerreceived:
      return l10n.offerReceived;

    case ChatStatusDetail.counteroffersent:
      return l10n.counterOfferSent;

    case ChatStatusDetail.counterofferreceived:
      return l10n.respondToCounterOffer;

    case ChatStatusDetail.bookingcreated:
      return l10n.newOrder;

    case ChatStatusDetail.bookingcancelled:
      return l10n.orderHasBeenCancelled;

    case ChatStatusDetail.bookingconfirmed:
      return l10n.updateWorkStatus;

    case ChatStatusDetail.waitingownerresponse:
      return l10n.waitingOwnerResponse;

    case ChatStatusDetail.workcompleted:
      return l10n.waitingClientConfirmation;

    case ChatStatusDetail.confirmcompleted:
      return l10n.confirmWorkCompleted;

    case ChatStatusDetail.bookingcompleted:
      return l10n.orderCompleted;

    case ChatStatusDetail.leaveReview:
      return l10n.submitReview;

    case ChatStatusDetail.bookingreviewed:
      return l10n.reviewSent;

    case ChatStatusDetail.requestaccepted:
      return l10n.requestAccepted;

    case ChatStatusDetail.unknown:
      return "";
  }
}

String getChatStatusLabel(ChatStatusDetail status, AppLocalizations l10n) {
  switch (status) {
    case ChatStatusDetail.requestcreated:
      return l10n.requestPending;

    case ChatStatusDetail.offercreated:
      return l10n.offerCreated;

    case ChatStatusDetail.offerreceived:
      return l10n.offerReceived;

    case ChatStatusDetail.counteroffersent:
      return l10n.counterOfferSent;

    case ChatStatusDetail.counterofferreceived:
      return l10n.respondToCounterOffer;

    case ChatStatusDetail.bookingcreated:
      return l10n.orderCreated;

    case ChatStatusDetail.bookingcancelled:
      return l10n.orderCancelled;

    case ChatStatusDetail.bookingconfirmed:
      return l10n.orderConfirmed;

    case ChatStatusDetail.waitingownerresponse:
      return l10n.waitingOwnerResponse;

    case ChatStatusDetail.workcompleted:
      return l10n.workCompleted;

    case ChatStatusDetail.confirmcompleted:
      return l10n.confirmWorkCompleted;

    case ChatStatusDetail.bookingcompleted:
      return l10n.orderCompleted;

    case ChatStatusDetail.leaveReview:
      return l10n.submitReview;

    case ChatStatusDetail.bookingreviewed:
      return l10n.reviewSent;

    case ChatStatusDetail.requestaccepted:
      return l10n.requestAccepted;

    case ChatStatusDetail.unknown:
      return "";
  }
}
