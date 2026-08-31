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

  test('hides actions when another owner won the tender', () {
    expect(
      chatHasVisibleActions(
        status: ChatStatusDetail.requestaccepted,
        mode: AppMode.clientMode,
      ),
      isFalse,
    );
    expect(
      chatHasVisibleActions(
        status: ChatStatusDetail.offernotselected,
        mode: AppMode.ownerMode,
      ),
      isFalse,
    );
    expect(
      chatHasVisibleActions(
        status: ChatStatusDetail.requestcancelled,
        mode: AppMode.clientMode,
      ),
      isFalse,
    );
  });

  test('locks composer for terminal request threads', () {
    expect(isChatInputLocked(ChatStatusDetail.bookingcancelled), isTrue);
    expect(isChatInputLocked(ChatStatusDetail.bookingreviewed), isTrue);
    expect(isChatInputLocked(ChatStatusDetail.workcompleted), isTrue);
    expect(isChatInputLocked(ChatStatusDetail.requestcancelled), isTrue);
    expect(isChatInputLocked(ChatStatusDetail.offernotselected), isTrue);
    expect(isChatInputLocked(ChatStatusDetail.requestcreated), isFalse);
    expect(isChatInputLocked(ChatStatusDetail.bookingconfirmed), isFalse);
  });
}
