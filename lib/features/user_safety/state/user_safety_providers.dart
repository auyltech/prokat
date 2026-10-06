import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/user_safety/models/blocked_user.dart';
import 'package:prokat/features/user_safety/state/blocked_users_notifier.dart';
import 'package:prokat/features/user_safety/state/user_safety_controller.dart';
import 'package:prokat/features/user_safety/state/user_safety_service.dart';

final userSafetyServiceProvider = Provider<UserSafetyApi>((ref) {
  return UserSafetyService(ref.watch(apiClientProvider));
});

final blockedUsersProvider =
    AsyncNotifierProvider<BlockedUsersNotifier, QueryState<BlockedUser>>(
      BlockedUsersNotifier.new,
    );

final userSafetyControllerProvider = Provider<UserSafetyController>((ref) {
  return UserSafetyController(ref);
});
