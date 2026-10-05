import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/analytics/analytics_client.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';

import '../../helpers/recording_analytics_client.dart';

void main() {
  test('converts bool params to int', () async {
    final client = RecordingAnalyticsClient();
    final service = AnalyticsService(client);

    await service.logOwnerApplicationSubmitted(isResubmit: true);
    await service.logEquipmentDraftCreated(
      categoryId: 'cat-1',
      group: CatalogGroup.equipment,
      isFirstEquipment: false,
    );

    expect(client.events, hasLength(2));
    expect(client.events[0].name, 'owner_application_submitted');
    expect(client.events[0].params, {'is_resubmit': 1});
    expect(client.events[1].name, 'equipment_draft_created');
    expect(client.events[1].params, {
      'category_id': 'cat-1',
      'catalog_group': 'equipment',
      'is_first_equipment': 0,
    });
  });

  test('drops null params', () async {
    final client = RecordingAnalyticsClient();
    final service = AnalyticsService(client);

    await service.logEquipmentCreationStarted(isFirstEquipment: null);
    await service.logEquipmentSubmittedForReview(
      isResubmit: false,
      categoryId: null,
      group: null,
    );
    await service.logSignUp();

    expect(client.events.map((e) => e.name), [
      'equipment_creation_started',
      'equipment_submitted_for_review',
      'sign_up',
    ]);
    expect(client.events[0].params, isEmpty);
    expect(client.events[1].params, {'is_resubmit': 0});
    expect(client.events[2].params, {'method': 'phone_otp'});
  });

  test('swallows client exceptions', () async {
    final service = AnalyticsService(
      RecordingAnalyticsClient(throwOnCall: true),
    );

    await expectLater(service.logSignUp(shareId: 'share-1'), completes);
    await expectLater(service.logOwnerApplicationStarted(), completes);
    await expectLater(
      service.logOwnerApplicationSubmitted(isResubmit: false),
      completes,
    );
    await expectLater(service.logEquipmentCreationStarted(), completes);
    await expectLater(
      service.logEquipmentDraftCreated(
        categoryId: 'cat-1',
        group: CatalogGroup.machinery,
      ),
      completes,
    );
    await expectLater(
      service.logEquipmentSubmittedForReview(isResubmit: true),
      completes,
    );
    await expectLater(
      service.logShare(
        equipmentId: 'eq-1',
        shareId: 'share-1',
        method: 'whatsapp',
      ),
      completes,
    );
    await expectLater(service.logScreenView('home'), completes);
  });

  test('noop client records nothing', () async {
    const noop = NoopAnalyticsClient();
    final service = AnalyticsService(noop);

    await expectLater(noop.logEvent('sign_up', const {}), completes);
    await expectLater(noop.setUserId('user-1'), completes);
    await expectLater(noop.setUserProperty('user_role', 'owner'), completes);
    await expectLater(noop.logScreenView('home'), completes);
    await expectLater(noop.setCollectionEnabled(true), completes);
    await expectLater(service.logSignUp(shareId: 'share-1'), completes);
    await expectLater(service.logScreenView('home'), completes);
  });

  test('share event uses recommended params', () async {
    final client = RecordingAnalyticsClient();
    final service = AnalyticsService(client);

    await service.logShare(
      equipmentId: 'eq-1',
      shareId: 'abcdefghijklmnopqrstuv',
      method: 'whatsapp',
    );

    expect(client.events, hasLength(1));
    expect(client.events.single.name, 'share');
    expect(client.events.single.params, {
      'content_type': 'equipment',
      'item_id': 'eq-1',
      'share_id': 'abcdefghijklmnopqrstuv',
      'method': 'whatsapp',
    });
  });
}
