import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart';

const catalogVisibilityEvent = 'catalog:visibility';

final catalogBootstrapProvider = Provider<void>((ref) {
  final appSocket = ref.watch(appSocketProvider);
  final connectListenerKey = Object();
  var started = false;
  var sawInitialConnect = false;

  void refreshCatalog() {
    unawaited(ref.read(clientEquipmentProvider.notifier).refresh());
    if (ref.exists(guestEquipmentProvider)) {
      unawaited(ref.read(guestEquipmentProvider.notifier).refresh());
    }
  }

  void attachListener() {
    appSocket.off(catalogVisibilityEvent);
    appSocket.on(catalogVisibilityEvent, (_) => refreshCatalog());
  }

  void onConnected() {
    attachListener();
    if (!sawInitialConnect) {
      sawInitialConnect = true;
      return;
    }
    refreshCatalog();
  }

  void detach() {
    appSocket.removeConnectListener(connectListenerKey);
    appSocket.off(catalogVisibilityEvent);
    started = false;
    sawInitialConnect = false;
  }

  Future<void> startIfReady() async {
    if (ref.read(authProvider).session == null) {
      detach();
      return;
    }

    if (started) return;
    started = true;

    appSocket.addConnectListener(connectListenerKey, onConnected);
    if (appSocket.isConnected) {
      sawInitialConnect = true;
    }

    try {
      await appSocket.connect();
      attachListener();
    } catch (error, stackTrace) {
      Logger.log('catalog socket connect failed: $error\n$stackTrace');
    }
  }

  ref.listen(authProvider, (previous, next) {
    if (previous?.session != null && next.session == null) {
      detach();
      return;
    }

    if (next.session != null) {
      unawaited(startIfReady());
    }
  });

  ref.onDispose(detach);
  unawaited(startIfReady());
});
