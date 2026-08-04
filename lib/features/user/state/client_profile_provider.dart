import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_mutation_notifier.dart';
import 'package:prokat/features/user/state/client_profile_notifier.dart';
import 'package:prokat/features/user/state/client_profile_service.dart';
import 'package:prokat/features/user/state/client_profile_state.dart';

final clientProfileServiceProvider = Provider<ClientProfileService>((ref) {
  return ClientProfileService(ref.watch(apiClientProvider));
});

final clientProfileProvider =
    AsyncNotifierProvider<ClientProfileNotifier, UserProfileModel?>(
      ClientProfileNotifier.new,
    );

final clientProfileMutationProvider =
    StateNotifierProvider<ClientProfileMutationNotifier, ClientProfileState>((
      ref,
    ) {
      return ClientProfileMutationNotifier(
        ref,
        ref.read(clientProfileServiceProvider),
      );
    });

extension ClientProfileAsyncValue on AsyncValue<UserProfileModel?> {
  UserProfileModel? get userProfile => valueOrNull;
}
