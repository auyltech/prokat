import 'dart:async';

import 'package:prokat/features/notifications/services/notification_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/services/notification_api_service.dart';

class DelayedInbox extends NotificationApiService {
  DelayedInbox() : super(Dio());
  final response = Completer<List<AppNotification>>();
  @override
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
  }) => response.future;
  @override
  Future<int> getUnreadCount() async => 0;
}

void main() {
  test(
    'late inbox response cannot restore notifications after logout',
    () async {
      final api = DelayedInbox();
      final notifier = NotificationNotifier(api);
      final pending = notifier.loadInitial();
      notifier.clearOnLogout();
      api.response.complete([
        AppNotification.fromJson({
          'id': 'old',
          'type': 'SYSTEM_NOTICE',
          'category': 'SYSTEM',
          'title': 'old',
          'data': {'audience': 'CLIENT'},
        }),
      ]);
      await pending;
      expect(notifier.state.items, isEmpty);
      expect(notifier.state.unreadCount, 0);
      notifier.dispose();
    },
  );
  test('profile changes isolate client, owner and each company inbox', () {
    var scope = 'CLIENT';
    final api = NotificationApiService(Dio(), scope: () => scope);
    AppNotification notice(String audience, [String? companyId]) =>
        AppNotification.fromJson({
          'id': 'notice',
          'type': 'SYSTEM_NOTICE',
          'category': 'SYSTEM',
          'title': 'test',
          'data': {'audience': audience, 'companyId': ?companyId},
        });
    final client = notice('CLIENT');
    final owner = notice('OWNER');
    final company = notice('OWNER', 'company-a');
    expect(api.accepts(client), isTrue);
    expect(api.accepts(owner), isFalse);
    expect(api.accepts(company), isFalse);
    scope = 'OWNER';
    expect(api.scopeQuery, {'profile': 'OWNER'});
    expect(api.accepts(client), isFalse);
    expect(api.accepts(owner), isTrue);
    expect(api.accepts(company), isFalse);
    scope = 'company-a';
    expect(api.scopeQuery, {'profile': 'COMPANY', 'companyId': 'company-a'});
    expect(api.accepts(client), isFalse);
    expect(api.accepts(owner), isFalse);
    expect(api.accepts(company), isTrue);
    expect(api.accepts(notice('OWNER', 'company-b')), isFalse);
  });
}
