import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/user_safety/screens/blocked_users_screen.dart';

import 'user_safety_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('lists blocked users and unblocks one in place', (tester) async {
    final api = FakeUserSafetyApi(
      blocked: [
        blockedUser('user-b', firstName: 'Bolat'),
        blockedUser('user-c', firstName: 'Saule'),
      ],
    );
    await tester.pumpWidget(
      testApp(
        overrides: userSafetyOverrides(api),
        home: const BlockedUsersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('blocked-user-user-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('blocked-user-user-c')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('unblock-user-b')));
    await tester.pumpAndSettle();

    expect(api.unblockCalls, ['user-b']);
    expect(find.byKey(const ValueKey('blocked-user-user-b')), findsNothing);
    expect(find.byKey(const ValueKey('blocked-user-user-c')), findsOneWidget);
  });

  testWidgets('empty list shows the empty state', (tester) async {
    await tester.pumpWidget(
      testApp(
        overrides: userSafetyOverrides(FakeUserSafetyApi()),
        home: const BlockedUsersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("You haven't blocked anyone"), findsOneWidget);
  });
}
