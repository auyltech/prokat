import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/requests/models/request_status.dart';

ChatStatus getChatStatus({
  RequestStatus? requestStatus,
  BookingStatus? bookingStatus,
  WorkStatus? workStatus,
  bool? hasNegotiation,
  bool? pendingFromMe,
  bool? reviewSubmitted,
  bool? hasActiveOffer,
  bool? isOfferPendingFromMe,
}) {
  // Request Created

  if (requestStatus == RequestStatus.responded) {
    if (hasActiveOffer == true) {
      // Request Offer cannot be pending from owner
      if (isOfferPendingFromMe == true) {
        return ChatStatus.offerreceived;
      }

      return ChatStatus.offercreated;
    } else if (hasNegotiation == true) {
      return pendingFromMe == true
          ? ChatStatus.counterofferreceived
          : ChatStatus.counteroffersent;
    }

    return ChatStatus.requestcreated;
  }

  if (bookingStatus == BookingStatus.created) {
    if (hasNegotiation == true) {
      return pendingFromMe == true
          ? ChatStatus.counterofferreceived
          : ChatStatus.counteroffersent;
    }

    return ChatStatus.bookingcreated;
  }

  if (bookingStatus == BookingStatus.confirmed) {
    if (workStatus == WorkStatus.completed) {
      return ChatStatus.workcompleted;
    }

    return ChatStatus.bookingconfirmed;
  }

  if (bookingStatus == BookingStatus.completed) {
    if (reviewSubmitted == true) {
      return ChatStatus.bookingreviewed;
    }

    return ChatStatus.leaveReview;
  }

  if (bookingStatus == BookingStatus.reviewed) {
    return ChatStatus.bookingreviewed;
  }

  if (bookingStatus == BookingStatus.cancelled ||
      bookingStatus == BookingStatus.rejected ||
      bookingStatus == BookingStatus.failed) {
    return ChatStatus.bookingcancelled;
  }

  // TODO: EDGE CASE REMOVE
  if (requestStatus == RequestStatus.created ||
      requestStatus == RequestStatus.accepted) {
    return ChatStatus.requestaccepted;
  }

  return ChatStatus.unknown;
}

String getChatActionBarTitle(ChatStatus status) {
  switch (status) {
    case ChatStatus.requestcreated:
      return "Request Pending";

    case ChatStatus.offercreated:
      return "Offer Created";

    case ChatStatus.offerreceived:
      return "Offer Received";

    case ChatStatus.counteroffersent:
      return "Counter Offer Sent";

    case ChatStatus.counterofferreceived:
      return "Respond to Counter Offer";

    case ChatStatus.bookingcreated:
      return "New Order";

    case ChatStatus.bookingcancelled:
      return "Order has been cancelled";

    case ChatStatus.bookingconfirmed:
      return "Update Work Status";

    case ChatStatus.waitingownerresponse:
      return "Waiting Owner Response";

    case ChatStatus.workcompleted:
      return "Waiting Client Confirmation";

    case ChatStatus.confirmcompleted:
      return "Confirm Work Completed";

    case ChatStatus.bookingcompleted:
      return "Order Completed";

    case ChatStatus.leaveReview:
      return "Submit Review";

    case ChatStatus.bookingreviewed:
      return "Review Sent";

    case ChatStatus.requestaccepted:
      return "Request Accepted";

    case ChatStatus.unknown:
      return "";
  }
}

String getChatStatusLabel(ChatStatus status) {
  switch (status) {
    case ChatStatus.requestcreated:
      return "Request Pending";

    case ChatStatus.offercreated:
      return "Offer Created";

    case ChatStatus.offerreceived:
      return "Offer Received";

    case ChatStatus.counteroffersent:
      return "Counter Offer Sent";

    case ChatStatus.counterofferreceived:
      return "Respond to Counter Offer";

    case ChatStatus.bookingcreated:
      return "Order Created";

    case ChatStatus.bookingcancelled:
      return "Order Cancelled";

    case ChatStatus.bookingconfirmed:
      return "Order Confirmed";

    case ChatStatus.waitingownerresponse:
      return "Waiting Owner Response";

    case ChatStatus.workcompleted:
      return "Work Completed";

    case ChatStatus.confirmcompleted:
      return "Confirm Work Completed";

    case ChatStatus.bookingcompleted:
      return "Order Completed";

    case ChatStatus.leaveReview:
      return "Submit Review";

    case ChatStatus.bookingreviewed:
      return "Review Sent";

    case ChatStatus.requestaccepted:
      return "Request Accepted";

    case ChatStatus.unknown:
      return "";
  }
}
