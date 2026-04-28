import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class GoRouterRefreshNotifier<T> extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref, ProviderListenable<T> provider) {
    _subscription = ref.listen<T>(
      provider,
      (_, __) => notifyListeners(),
      fireImmediately: true,
    );
  }

  late final ProviderSubscription<T> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
