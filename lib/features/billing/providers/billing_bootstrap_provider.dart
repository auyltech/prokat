import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/billing/models/account_balance_model.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';

const billingUpdateEvent = 'billing:update';

final billingBootstrapProvider = Provider<void>((ref) {
  final appSocket = ref.watch(appSocketProvider);
  final connectListenerKey = Object();
  var started = false;

  void applyPayload(dynamic payload) {
    if (payload is! Map) return;
    try {
      final balance = AccountBalanceModel.fromJson(
        Map<String, dynamic>.from(payload),
      );
      ref.read(billingProvider.notifier).applySocketBalance(balance);
    } catch (error, stackTrace) {
      Logger.log('billing socket payload failed: $error\n$stackTrace');
    }
  }

  void attachListener() {
    appSocket.off(billingUpdateEvent);
    appSocket.on(billingUpdateEvent, applyPayload);
  }

  void detach() {
    appSocket.removeConnectListener(connectListenerKey);
    appSocket.off(billingUpdateEvent);
    started = false;
  }

  Future<void> startIfReady() async {
    if (ref.read(authProvider).session == null) {
      detach();
      return;
    }

    if (started) return;
    started = true;

    appSocket.addConnectListener(connectListenerKey, attachListener);

    try {
      await appSocket.connect();
      attachListener();
    } catch (error, stackTrace) {
      Logger.log('billing socket connect failed: $error\n$stackTrace');
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
