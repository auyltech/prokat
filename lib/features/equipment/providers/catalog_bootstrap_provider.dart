import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/providers/open_chat_id_provider.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart';
import 'package:prokat/features/owner/models/owner_status.dart';

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

  void patchOpenChatOwnerStatus(Object? raw) {
    if (raw is! Map) return;

    final ownerId = raw['ownerId']?.toString().trim() ?? '';
    if (ownerId.isEmpty) return;

    final onlineStatus = parseOwnerStatus(raw['onlineStatus']);
    final openChatId = ref.read(openChatIdProvider);
    if (openChatId == null || openChatId.isEmpty) return;

    final chatProvider = currentChatProvider(openChatId);
    if (!ref.exists(chatProvider)) return;

    final chat = ref.read(chatProvider).valueOrNull;
    final owner = chat?.owner;
    if (chat == null || owner == null || owner.id != ownerId) return;

    ref
        .read(chatProvider.notifier)
        .setChat(
          chat.copyWith(owner: owner.copyWith(onlineStatus: onlineStatus)),
        );
  }

  void onCatalogVisibility(Object? raw) {
    refreshCatalog();
    patchOpenChatOwnerStatus(raw);
  }

  void attachListener() {
    appSocket.off(catalogVisibilityEvent);
    appSocket.on(catalogVisibilityEvent, onCatalogVisibility);
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
