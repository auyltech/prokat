import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/core/analytics/supply_analytics_rules.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';

import '../../helpers/recording_analytics_client.dart';

void main() {
  test('startable when no request', () {
    expect(ownerApplicationIsStartable(null), isTrue);
  });

  test('startable when rejected', () {
    expect(
      ownerApplicationIsStartable(RegistrationRequestModel(status: 'REJECTED')),
      isTrue,
    );
  });

  test('not startable when pending or approved', () {
    expect(
      ownerApplicationIsStartable(RegistrationRequestModel(status: 'PENDING')),
      isFalse,
    );
    expect(
      ownerApplicationIsStartable(RegistrationRequestModel(status: 'APPROVED')),
      isFalse,
    );
  });

  test('first equipment null when list not loaded', () {
    expect(isFirstEquipment(null), isNull);
  });

  test('first equipment true for empty list', () {
    expect(
      isFirstEquipment(const QueryState<Equipment>(itemsPerPage: 20, count: 0)),
      isTrue,
    );
  });

  test('block reason wire values', () async {
    expect(EquipmentSubmitBlockReason.photoMissing.wire, 'photo_missing');
    expect(
      EquipmentSubmitBlockReason.fieldsIncomplete.wire,
      'fields_incomplete',
    );

    final client = RecordingAnalyticsClient();
    final service = AnalyticsService(client);
    await service.logEquipmentSubmitBlocked(
      EquipmentSubmitBlockReason.photoMissing,
    );
    await service.logEquipmentSubmitBlocked(
      EquipmentSubmitBlockReason.fieldsIncomplete,
    );

    expect(client.events.map((e) => e.name), [
      'equipment_submit_blocked',
      'equipment_submit_blocked',
    ]);
    expect(client.events[0].params, {'reason': 'photo_missing'});
    expect(client.events[1].params, {'reason': 'fields_incomplete'});
  });
}
