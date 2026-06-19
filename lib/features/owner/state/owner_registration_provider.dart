import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_notifier.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';
import 'package:prokat/features/owner/state/owner_registration_state.dart';

final ownerRegistrationServiceProvider = Provider<OwnerRegistrationService>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return OwnerRegistrationService(apiClient);
});

final ownerRegistrationProvider =
    StateNotifierProvider<OwnerRegistrationNotifier, OwnerRegistrationState>((
      ref,
    ) {
      final service = ref.read(ownerRegistrationServiceProvider);
      return OwnerRegistrationNotifier(service);
    });
