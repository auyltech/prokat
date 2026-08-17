import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';

final ownerRegistrationServiceProvider = Provider<OwnerRegistrationService>((
  ref,
) {
  return OwnerRegistrationService(ref.watch(apiClientProvider));
});
