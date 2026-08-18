import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/chat/utils/chat_resume_sync_observer.dart';

void main() {
  test('refetches after paused then resumed', () {
    var calls = 0;
    final observer = ChatResumeSyncObserver(
      onResumeFromBackground: () => calls++,
    );

    observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
    observer.didChangeAppLifecycleState(AppLifecycleState.paused);
    observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(calls, 1);
  });

  test('does not refetch when only inactive then resumed', () {
    var calls = 0;
    final observer = ChatResumeSyncObserver(
      onResumeFromBackground: () => calls++,
    );

    observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(calls, 0);
  });

  test('refetches after hidden then resumed', () {
    var calls = 0;
    final observer = ChatResumeSyncObserver(
      onResumeFromBackground: () => calls++,
    );

    observer.didChangeAppLifecycleState(AppLifecycleState.hidden);
    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(calls, 1);
  });
}
