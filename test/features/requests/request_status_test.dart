import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/requests/models/request_status.dart';

void main() {
  test('accepted requests stay active but do not occupy the create slot', () {
    expect(isActiveRequestStatus(RequestStatus.accepted), isTrue);
    expect(occupiesCreateRequestSlot(RequestStatus.accepted), isFalse);
    expect(occupiesCreateRequestSlot(RequestStatus.created), isTrue);
    expect(occupiesCreateRequestSlot(RequestStatus.responded), isTrue);
  });
}
