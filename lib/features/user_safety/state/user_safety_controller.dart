import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/layout/navigation_counts_provider.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/user_safety/models/report_reason.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';
import 'package:prokat/features/user_safety/state/user_safety_providers.dart';

/// Block / unblock / report. Report never blocks; block never reports.
class UserSafetyController {
  UserSafetyController(this._ref);

  final Ref _ref;

  Future<MutationResponse> blockUser(String userId, {String? chatId}) async {
    final response = await _ref
        .read(userSafetyServiceProvider)
        .blockUser(userId);
    if (!response.success) return response;

    for (final group in CatalogGroup.values) {
      final equipment = clientEquipmentProvider(group);
      if (_ref.exists(equipment)) {
        _ref.read(equipment.notifier).removeOwnerLocally(userId);
      }
      final requests = ownerActiveRequestsProvider(group);
      if (_ref.exists(requests)) {
        _ref.read(requests.notifier).removeClientLocally(userId);
      }
    }
    refreshNavigationCounts(_ref);
    _ref.invalidate(blockedUsersProvider);
    _refreshChat(chatId);
    return response;
  }

  Future<MutationResponse> unblockUser(String userId, {String? chatId}) async {
    final response = await _ref
        .read(userSafetyServiceProvider)
        .unblockUser(userId);
    if (!response.success) return response;

    if (_ref.exists(blockedUsersProvider)) {
      _ref.read(blockedUsersProvider.notifier).removeLocally(userId);
    }
    for (final group in CatalogGroup.values) {
      final equipment = clientEquipmentProvider(group);
      if (_ref.exists(equipment)) {
        unawaited(_ref.read(equipment.notifier).refresh());
      }
      final requests = ownerActiveRequestsProvider(group);
      if (_ref.exists(requests)) {
        unawaited(_ref.read(requests.notifier).refresh());
      }
    }
    _refreshChat(chatId);
    return response;
  }

  Future<MutationResponse> report(
    ReportTarget target,
    ReportReason reason,
    String? comment,
  ) {
    return _ref
        .read(userSafetyServiceProvider)
        .createReport(target: target, reason: reason, comment: comment);
  }

  void _refreshChat(String? chatId) {
    if (chatId == null || chatId.isEmpty) return;
    final chat = currentChatProvider(chatId);
    if (_ref.exists(chat)) {
      unawaited(_ref.read(chat.notifier).refresh());
    }
  }
}
