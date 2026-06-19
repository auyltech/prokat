import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/user/state/user_profile_notifier.dart';
import 'package:prokat/features/user/state/user_profile_service.dart';
import 'package:prokat/features/user/state/user_profile_state.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  final dio = ref.watch(apiClientProvider);

  return UserProfileService(dio);
});

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
      return UserProfileNotifier(ref, ref.read(userProfileServiceProvider));
    });
