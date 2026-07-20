import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/requests/models/request_status.dart';

ChatStatusDetail getChatStatus({
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

String getChatActionBarTitle(ChatStatusDetail status) {
  switch (status) {
    case ChatStatusDetail.requestcreated:
      return "Request Pending";

    case ChatStatusDetail.offercreated:
      return "Offer Created";

    case ChatStatusDetail.offerreceived:
      return "Offer Received";

    case ChatStatusDetail.counteroffersent:
      return "Counter Offer Sent";

    case ChatStatusDetail.counterofferreceived:
      return "Respond to Counter Offer";

    case ChatStatusDetail.bookingcreated:
      return "New Order";

    case ChatStatusDetail.bookingcancelled:
      return "Order has been cancelled";

    case ChatStatusDetail.bookingconfirmed:
      return "Update Work Status";

    case ChatStatusDetail.waitingownerresponse:
      return "Waiting Owner Response";

    case ChatStatusDetail.workcompleted:
      return "Waiting Client Confirmation";

    case ChatStatusDetail.confirmcompleted:
      return "Confirm Work Completed";

    case ChatStatusDetail.bookingcompleted:
      return "Order Completed";

    case ChatStatusDetail.leaveReview:
      return "Submit Review";

    case ChatStatusDetail.bookingreviewed:
      return "Review Sent";

    case ChatStatusDetail.requestaccepted:
      return "Request Accepted";

    case ChatStatusDetail.unknown:
      return "";
  }
}

String getChatStatusLabel(ChatStatusDetail status) {
  switch (status) {
    case ChatStatusDetail.requestcreated:
      return "Request Pending";

    case ChatStatusDetail.offercreated:
      return "Offer Created";

    case ChatStatusDetail.offerreceived:
      return "Offer Received";

    case ChatStatusDetail.counteroffersent:
      return "Counter Offer Sent";

    case ChatStatusDetail.counterofferreceived:
      return "Respond to Counter Offer";

    case ChatStatusDetail.bookingcreated:
      return "Order Created";

    case ChatStatusDetail.bookingcancelled:
      return "Order Cancelled";

    case ChatStatusDetail.bookingconfirmed:
      return "Order Confirmed";

    case ChatStatusDetail.waitingownerresponse:
      return "Waiting Owner Response";

    case ChatStatusDetail.workcompleted:
      return "Work Completed";

    case ChatStatusDetail.confirmcompleted:
      return "Confirm Work Completed";

    case ChatStatusDetail.bookingcompleted:
      return "Order Completed";

    case ChatStatusDetail.leaveReview:
      return "Submit Review";

    case ChatStatusDetail.bookingreviewed:
      return "Review Sent";

    case ChatStatusDetail.requestaccepted:
      return "Request Accepted";

    case ChatStatusDetail.unknown:
      return "";
  }
}
