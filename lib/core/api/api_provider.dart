import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/services/client_request_metadata_service.dart';
import 'package:prokat/core/services/installation_identity_service.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';

import 'api_client.dart';
import '../providers/unauthorized_signal_provider.dart';

final secureStorageProvider = Provider<AuthSecureStorage>((ref) {
  return AuthSecureStorage();
});

final installationIdentityProvider = Provider<InstallationIdentityService>((
  ref,
) {
  return InstallationIdentityService();
});

final clientRequestMetadataProvider = Provider<ClientRequestMetadataService>((
  ref,
) {
  return ClientRequestMetadataService(
    installationIdentity: ref.watch(installationIdentityProvider),
    loadAppCheckToken: Env.firebaseServicesEnabled ? null : () async => null,
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(
    secureStorage,
    requestMetadata: ref.watch(clientRequestMetadataProvider),
    onUnauthorized: () {
      ref.read(unauthorizedSignalProvider.notifier).state++;
    },
  );
});

final dioProvider = Provider((ref) {
  return ref.watch(apiClientProvider).dio;
});
