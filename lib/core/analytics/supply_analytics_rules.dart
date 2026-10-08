import 'package:prokat/core/analytics/analytics_events.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';

bool ownerApplicationIsStartable(RegistrationRequestModel? r) =>
    r == null || r.isRejected;

bool? isFirstEquipment(QueryState<Equipment>? s) => s?.items.isEmpty;

enum EquipmentSubmitBlockReason {
  photoMissing,
  fieldsIncomplete;

  String get wire => switch (this) {
    EquipmentSubmitBlockReason.photoMissing =>
      AnalyticsValues.reasonPhotoMissing,
    EquipmentSubmitBlockReason.fieldsIncomplete =>
      AnalyticsValues.reasonFieldsIncomplete,
  };
}
