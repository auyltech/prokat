import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/owner_offline_guard.dart';

/// Offline composer/action lock for a direct booking awaiting owner confirm.
///
/// - Owner: uses local [ownerProfileProvider].
/// - Client: locks only when [chat.owner.onlineStatus] is explicitly offline.
///   `null` does not lock (pilot compatibility before/without detail DTO).
bool isDirectBookingOwnerOfflineLock({
  required Object ref,
  required AppMode mode,
  required ChatModel? chat,
}) {
  final booking = chat?.booking;
  if (booking == null || booking.status != BookingStatus.created) {
    return false;
  }

  if (mode == AppMode.ownerMode) {
    final status = ownerOnlineStatusOf(ref);
    return status != null && status != OwnerStatus.online;
  }

  return chat?.owner?.onlineStatus == OwnerStatus.offline;
}
