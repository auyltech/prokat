import 'dart:async';

class DebouncedAction {
  Timer? _timer;

  void run(
    Future<void> Function() action, {
    Duration delay = const Duration(milliseconds: 800),
  }) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      unawaited(action());
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
