import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/booking_summary_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/workflow/utils/workflow_cache_patch.dart';
import 'package:prokat/l10n/app_localizations_en.dart';

BookingModel _booking({WorkStatus workStatus = WorkStatus.started}) {
  return BookingModel(
    id: 'booking-1',
    status: BookingStatus.confirmed,
    workStatus: workStatus,
    price: 2000,
    priceRate: parseRateOption('PER_TRIP'),
  );
}

ChatModel _chat({required BookingModel booking}) {
  return ChatModel(
    id: 'chat-1',
    booking: booking,
    bookingSummary: BookingSummaryModel(
      id: booking.id,
      status: 'CONFIRMED',
      workStatus: booking.workStatus,
    ),
  );
}

void main() {
  final l10n = AppLocalizationsEn();

  test('work-completed EVENT unlocks the client confirm CTA', () {
    final patched = applyWorkStatusEventToChat(
      chat: _chat(booking: _booking()),
      type: 'EVENT',
      meta: {
        'bookingId': 'booking-1',
        'bookingStatus': 'CONFIRMED',
        'workStatus': 'completed',
      },
    );

    expect(patched.booking?.workStatus, WorkStatus.completed);
    expect(patched.bookingSummary?.workStatus, WorkStatus.completed);

    final config = getChatConfig(
      chat: patched,
      l10n: l10n,
      mode: AppMode.clientMode,
    );
    expect(config.status, ChatStatusDetail.confirmcompleted);
  });

  test('stale started EVENT does not drop completed work', () {
    final patched = applyWorkStatusEventToChat(
      chat: _chat(booking: _booking(workStatus: WorkStatus.completed)),
      type: 'EVENT',
      meta: {
        'bookingId': 'booking-1',
        'bookingStatus': 'CONFIRMED',
        'workStatus': 'started',
      },
    );

    expect(patched.booking?.workStatus, WorkStatus.completed);
    expect(patched.bookingSummary?.workStatus, WorkStatus.completed);

    final config = getChatConfig(
      chat: patched,
      l10n: l10n,
      mode: AppMode.clientMode,
    );
    expect(config.status, ChatStatusDetail.confirmcompleted);
  });

  test('EVENT without bookingId does not change the booking', () {
    final chat = _chat(booking: _booking());
    final patched = applyWorkStatusEventToChat(
      chat: chat,
      type: 'EVENT',
      meta: {'bookingStatus': 'CONFIRMED', 'workStatus': 'completed'},
    );

    expect(patched.booking?.workStatus, WorkStatus.started);
  });

  test('EVENT for another bookingId does not change the booking', () {
    final patched = applyWorkStatusEventToChat(
      chat: _chat(booking: _booking()),
      type: 'EVENT',
      meta: {'bookingId': 'booking-other', 'workStatus': 'completed'},
    );

    expect(patched.booking?.workStatus, WorkStatus.started);
  });

  test('EVENT without workStatus does not change the booking', () {
    final patched = applyWorkStatusEventToChat(
      chat: _chat(booking: _booking()),
      type: 'EVENT',
      meta: {'bookingId': 'booking-1', 'bookingStatus': 'CONFIRMED'},
    );

    expect(patched.booking?.workStatus, WorkStatus.started);
  });
}
