import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';
import 'package:prokat/features/owner/state/owner_profile_notifier.dart';
import 'package:prokat/features/owner/state/owner_registration_notifier.dart';
import 'package:prokat/features/owner/state/owner_registration_request_notifier.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';
import 'package:prokat/features/owner/state/owner_registration_state.dart';

final ownerRegistrationServiceProvider = Provider<OwnerRegistrationService>((
  ref,
) {
  return OwnerRegistrationService(ref.watch(apiClientProvider));
});

final ownerProfileProvider =
    AsyncNotifierProvider<OwnerProfileNotifier, OwnerProfileModel?>(
      OwnerProfileNotifier.new,
    );

final ownerRegistrationRequestProvider =
    AsyncNotifierProvider<
      OwnerRegistrationRequestNotifier,
      RegistrationRequestModel?
    >(OwnerRegistrationRequestNotifier.new);

final ownerRegistrationMutationProvider =
    StateNotifierProvider<
      OwnerRegistrationMutationNotifier,
      OwnerRegistrationState
    >((ref) {
      ref.watch(authProvider.select((auth) => auth.currentUserId));
      return OwnerRegistrationMutationNotifier(
        ref,
        ref.read(ownerRegistrationServiceProvider),
      );
    });
