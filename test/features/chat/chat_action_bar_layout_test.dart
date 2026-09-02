import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/widgets/booking_actions/chat_action_bar.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('leave-review bar stays compact so the thread keeps its height', (
    tester,
  ) async {
    const messagesKey = Key('messages');

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ColoredBox(
              key: messagesKey,
              color: Colors.black,
              child: SizedBox.expand(),
            ),
            bottomNavigationBar: ChatActionBar(
              currentChat: ChatModel(id: 'chat-1', status: ChatStatus.closed),
              chatStatus: ChatStatusDetail.leaveReview,
              mode: AppMode.ownerMode,
              actionBarTitle: 'Submit Review',
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final barSize = tester.getSize(find.byType(ChatActionBar));
    final bodySize = tester.getSize(find.byKey(messagesKey));

    expect(barSize.height, lessThan(160));
    expect(bodySize.height, greaterThan(400));
    expect(find.text('Submit Review'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });
}
