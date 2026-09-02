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
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('list chats with bookingSummary still get a status label', () {
    final chat = ChatModel(
      id: 'chat-1',
      bookingSummary: BookingSummaryModel(id: 'booking-1', status: 'CREATED'),
    );

    final config = getChatConfig(chat: chat, l10n: l10n);

    expect(config.statusLabel, l10n.orderCreated);
  });

  test('returns an empty label when there is no booking or request', () {
    const chat = ChatModel(id: 'chat-2');

    final config = getChatConfig(chat: chat, l10n: l10n);

    expect(config.statusLabel, isEmpty);
  });

  test('accepted request without a booking means another owner won', () {
    final chat = ChatModel(
      id: 'chat-loser',
      request: RequestModel(
        id: 'request-1',
        status: RequestStatus.accepted,
        capacity: '10',
        offeredPrice: 1000,
      ),
    );

    final config = getChatConfig(chat: chat, l10n: l10n);

    expect(config.status, ChatStatusDetail.offernotselected);
    expect(config.statusLabel, l10n.offerNotSelected);
  });

  test('accepted request with a booking still uses the booking status', () {
    final chat = ChatModel(
      id: 'chat-winner',
      bookingId: 'booking-1',
      booking: BookingModel(
        id: 'booking-1',
        status: BookingStatus.confirmed,
        price: 1000,
        priceRate: parseRateOption('PER_TRIP'),
      ),
      request: RequestModel(
        id: 'request-1',
        status: RequestStatus.accepted,
        capacity: '10',
        offeredPrice: 1000,
      ),
    );

    final config = getChatConfig(chat: chat, l10n: l10n);

    expect(config.status, ChatStatusDetail.bookingconfirmed);
  });

  test('owner list badge waits for the client to confirm completed work', () {
    final chat = ChatModel(
      id: 'chat-work-done',
      bookingSummary: BookingSummaryModel(
        id: 'booking-1',
        status: 'CONFIRMED',
        workStatus: WorkStatus.completed,
      ),
    );

    final owner = getChatConfig(
      chat: chat,
      l10n: l10n,
      mode: AppMode.ownerMode,
    );
    expect(owner.status, ChatStatusDetail.workcompleted);
    expect(owner.statusLabel, l10n.waitingForClientConfirm);

    final client = getChatConfig(
      chat: chat,
      l10n: l10n,
      mode: AppMode.clientMode,
    );
    expect(client.status, ChatStatusDetail.confirmcompleted);
    expect(client.statusLabel, l10n.confirmWorkCompleted);
  });
}
