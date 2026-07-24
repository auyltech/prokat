import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/user/state/client_profile_notifier.dart';
import 'package:prokat/features/user/state/client_profile_service.dart';
import 'package:prokat/features/user/state/client_profile_state.dart';

final clientProfileServiceProvider = Provider<ClientProfileService>((ref) {
  final dio = ref.watch(apiClientProvider);

  return ClientProfileService(dio);
});

final clientProfileProvider =
    StateNotifierProvider<ClientProfileNotifier, ClientProfileState>((ref) {
      return ClientProfileNotifier(ref, ref.read(clientProfileServiceProvider));
    });
