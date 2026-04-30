import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import '../api/api_client.dart';

final secureStorageProvider = Provider<AuthSecureStorage>((ref) {
  return AuthSecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage);
});

final dioProvider = Provider((ref) {
  return ref.watch(apiClientProvider).dio;
});
