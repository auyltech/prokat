import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'api_client.dart';

final secureStorageProvider = Provider<AuthSecureStorage>((ref) {
  return AuthSecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiClient(storage);
});
