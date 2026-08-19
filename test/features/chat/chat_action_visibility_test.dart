import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';

void main() {
  test('hides the composer action bar when a new booking has no controls', () {
    expect(
      chatHasVisibleActions(
        status: ChatStatusDetail.bookingcreated,
        mode: AppMode.clientMode,
      ),
      isFalse,
    );
    expect(
      chatHasVisibleActions(
        status: ChatStatusDetail.bookingcreated,
        mode: AppMode.ownerMode,
      ),
      isFalse,
    );
  });

  test('shows owner booking controls and client completion confirm', () {
    expect(
      chatHasVisibleActions(
        status: ChatStatusDetail.bookingconfirmed,
        mode: AppMode.ownerMode,
      ),
      isTrue,
    );
    expect(
      chatHasVisibleActions(
        status: ChatStatusDetail.bookingconfirmed,
        mode: AppMode.clientMode,
      ),
      isFalse,
    );
    expect(
      chatHasVisibleActions(
        status: ChatStatusDetail.confirmcompleted,
        mode: AppMode.clientMode,
      ),
      isTrue,
    );
  });
}
