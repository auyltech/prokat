import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/owner_offline_guard.dart';

/// Offline composer/action lock for the owner of a new direct lead.
///
/// - Owner: uses local [ownerProfileProvider].
/// - Client may always write; the message is delivered when the owner returns.
bool isDirectBookingOwnerOfflineLock({
  required Object ref,
  required AppMode mode,
  required ChatModel? chat,
}) {
  if (mode != AppMode.ownerMode) return false;
  final booking = chat?.booking;
  final isOpenInquiry =
      chat?.inquiryEquipmentId?.isNotEmpty == true && booking == null;
  final isPendingDirectBooking =
      booking?.status == BookingStatus.created &&
      (chat?.requestId?.isNotEmpty != true);
  if (!isOpenInquiry && !isPendingDirectBooking) {
    return false;
  }
  final status = ownerOnlineStatusOf(ref);
  return status != null && status != OwnerStatus.online;
}
