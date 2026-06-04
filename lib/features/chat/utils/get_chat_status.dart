import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/requests/models/request_status.dart';

ChatStatus getChatStatus({
  RequestStatus? requestStatus,
  BookingStatus? bookingStatus,
  required WorkStatus workStatus,
  bool hasNegotiation = false,
  bool pendingFromMe = false,
  bool reviewSubmitted = false,
  bool? hasActiveOffer,
  bool? isOfferPendingFromMe,
}) {
  if (bookingStatus == BookingStatus.created) {
    if (hasNegotiation) {
      return pendingFromMe
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
    if (reviewSubmitted) {
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

  if (requestStatus == RequestStatus.responded) {
    if (hasActiveOffer == true) {
      if (isOfferPendingFromMe == true) {
        return ChatStatus.offerreceived;
      }

      return ChatStatus.offercreated;
    } else if (hasNegotiation) {
      return pendingFromMe
          ? ChatStatus.counterofferreceived
          : ChatStatus.counteroffersent;
    }

    return ChatStatus.requestcreated;
  }

  return ChatStatus.unknown;
}

String getChatStatusText(ChatStatus status) {
  switch (status) {
    case ChatStatus.counterofferreceived:
      return "Respond to Counter Offer";

    case ChatStatus.counteroffersent:
      return "Counter Offer Sent";

    case ChatStatus.bookingcreated:
      return "New Booking";

    case ChatStatus.bookingconfirmed:
      return "Update Work Status";

    case ChatStatus.workcompleted:
      return "Waiting Client Confirmation";

    case ChatStatus.leaveReview:
      return "Submit Review";

    case ChatStatus.bookingreviewed:
      return "Review Sent";

    case ChatStatus.bookingcompleted:
      return "Booking Completed";

    case ChatStatus.waitingownerresponse:
      return "Waiting Owner Response";

    case ChatStatus.confirmcompleted:
      return "Confirm Work Completed";

    default:
      return "";
  }
}
