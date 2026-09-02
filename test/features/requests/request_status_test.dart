import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/requests/models/request_status.dart';

void main() {
  test('accepted requests leave the active list and free the create slot', () {
    expect(isActiveRequestStatus(RequestStatus.accepted), isFalse);
    expect(isArchivedRequestStatus(RequestStatus.accepted), isTrue);
    expect(occupiesCreateRequestSlot(RequestStatus.accepted), isFalse);
    expect(occupiesCreateRequestSlot(RequestStatus.created), isTrue);
    expect(occupiesCreateRequestSlot(RequestStatus.responded), isTrue);
  });
}
