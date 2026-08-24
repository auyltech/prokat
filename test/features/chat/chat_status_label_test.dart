import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/bookings/models/booking_summary_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
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
}
