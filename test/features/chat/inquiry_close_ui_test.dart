import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_dependencies.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/chat/widgets/inquiry_context_card.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

import '../user_safety/user_safety_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  final equipment = Equipment.fromJson({
    'id': 'equipment-1',
    'name': 'Truck',
    'model': 'Test',
    'status': 'AVAILABLE',
    'isVisible': true,
    'prices': [],
  });
  ChatModel discussion({
    String? bookingId,
    ChatStatus status = ChatStatus.active,
  }) => ChatModel.fromJson({
    'id': 'chat-1',
    'inquiryEquipmentId': equipment.id,
    'inquiryEquipment': equipment.toJson(),
    'bookingId': bookingId,
    'status': status.name,
  });
  Future<void> showCard(
    WidgetTester tester,
    _Service service,
    ChatModel chat,
  ) async {
    await tester.pumpWidget(
      testApp(
        overrides: [chatServiceProvider.overrideWithValue(service)],
        home: ProkatFlowScope(
          palette: ProkatFlowPalette.light,
          child: Scaffold(
            body: InquiryContextCard(chat: chat, onSetTerms: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('declining the close confirmation never calls the server', (
    tester,
  ) async {
    final service = _Service();
    await showCard(tester, service, discussion());
    await tester.tap(find.byKey(const ValueKey('inquiry-close-button')));
    await tester.pumpAndSettle();
    expect(find.text('End this discussion without an order?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.calls, 0);
    expect(find.textContaining('Confirm terms'), findsOneWidget);
  });

  testWidgets(
    'pending booking and archived discussion cannot be closed as an inquiry',
    (tester) async {
      final service = _Service();
      await showCard(tester, service, discussion(bookingId: 'booking-1'));
      expect(find.byKey(const ValueKey('inquiry-close-button')), findsNothing);
      expect(find.textContaining('Confirm terms'), findsNothing);
      await showCard(tester, service, discussion(status: ChatStatus.closed));
      expect(find.byKey(const ValueKey('inquiry-close-button')), findsNothing);
      expect(find.text('Discussion ended'), findsOneWidget);
      expect(service.calls, 0);
    },
  );

  testWidgets(
    'leaving the chat during completion does not update a disposed widget',
    (tester) async {
      final service = _Service();
      service.pending = Completer<ApiResponse<bool>>();
      await showCard(tester, service, discussion());
      await tester.tap(find.byKey(const ValueKey('inquiry-close-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(service.calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      service.pending!.complete(ApiResponse.success(true));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

class _Service extends ChatService {
  _Service() : super(_Api());
  int calls = 0;
  Completer<ApiResponse<bool>>? pending;
  @override
  Future<ApiResponse<bool>> closeEquipmentInquiry(String chatId) {
    calls++;
    return pending?.future ?? Future.value(ApiResponse.success(true));
  }
}

class _Api implements ApiClient {
  @override
  Dio dio = Dio();
}
