import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/state/chat_status.dart';

ChatStatus getChatStatus({
  required String bookingStatus,
  required WorkStatus workStatus,
  bool hasNegotiation = false,
  bool pendingFromMe = false,
  bool reviewSubmitted = false,
}) {
  final normalizedStatus = bookingStatus.toUpperCase();

  if (normalizedStatus == "CREATED") {
    if (hasNegotiation) {
      return pendingFromMe
          ? ChatStatus.counterofferreceived
          : ChatStatus.counteroffersent;
    }

    return ChatStatus.bookingcreated;
  }

  if (normalizedStatus == "CONFIRMED") {
    if (workStatus == WorkStatus.completed) {
      return ChatStatus.workcompleted;
    }

    return ChatStatus.bookingconfirmed;
  }

  if (normalizedStatus == "COMPLETED") {
    if (reviewSubmitted) {
      return ChatStatus.bookingreviewed;
    }

    return ChatStatus.leaveReview;
  }

  if (normalizedStatus == "REVIEWED") {
    return ChatStatus.bookingreviewed;
  }

  if (normalizedStatus == "CANCELLED" ||
      normalizedStatus == "REJECTED" ||
      normalizedStatus == "FAILED") {
    return ChatStatus.bookingcancelled;
  }

  return ChatStatus.bookingcompleted;
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
