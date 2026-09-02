import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/utils/chat_resume_sync_observer.dart';
import 'package:prokat/features/workflow/models/workflow_update.dart';
import 'package:prokat/features/workflow/providers/workflow_providers.dart';

final workflowBootstrapProvider = Provider<void>((ref) {
  final socketService = ref.watch(workflowSocketServiceProvider);
  final appSocket = ref.watch(appSocketProvider);
  final coordinator = ref.watch(workflowCacheCoordinatorProvider);
  void Function()? removeListener;
  var started = false;
  var sawInitialConnect = false;
  Timer? resyncDebounce;
  final connectListenerKey = Object();

  void detach() {
    removeListener?.call();
    removeListener = null;
    started = false;
    sawInitialConnect = false;
    resyncDebounce?.cancel();
    resyncDebounce = null;
    appSocket.removeConnectListener(connectListenerKey);
  }

  void applyUpdate(WorkflowUpdate update) {
    coordinator.apply(update);
  }

  void scheduleReconnectResync() {
    resyncDebounce?.cancel();
    resyncDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(coordinator.resyncAfterReconnect());
    });
  }

  Future<void> startIfReady() async {
    final session = ref.read(authProvider).session;
    if (session == null) {
      detach();
      return;
    }

    if (started) return;

    started = true;
    removeListener = socketService.onUpdate(applyUpdate);
    appSocket.addConnectListener(connectListenerKey, () {
      if (!sawInitialConnect) {
        sawInitialConnect = true;
        return;
      }
      scheduleReconnectResync();
    });

    if (appSocket.isConnected) {
      sawInitialConnect = true;
    }

    try {
      await socketService.connect();
    } catch (error, stackTrace) {
      Logger.log('workflow socket connect failed: $error\n$stackTrace');
    }
  }

  final lifecycleObserver = ChatResumeSyncObserver(
    onResumeFromBackground: () {
      unawaited(startIfReady());
      // Socket is down while paused; events can be missed even if
      // reconnect is skipped (already connected). Always resync loaded lists.
      scheduleReconnectResync();
    },
  );

  try {
    WidgetsBinding.instance.addObserver(lifecycleObserver);
  } catch (_) {}

  ref.listen(authProvider, (previous, next) {
    if (previous?.session != null && next.session == null) {
      detach();
      return;
    }

    if (next.session != null) {
      unawaited(startIfReady());
    }
  });

  ref.onDispose(() {
    try {
      WidgetsBinding.instance.removeObserver(lifecycleObserver);
    } catch (_) {}
    detach();
  });

  unawaited(startIfReady());
});
