import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/api_provider.dart';
import 'package:prokat/core/services/app_socket_service.dart';

final appSocketProvider = Provider<AppSocketService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AppSocketService(apiClient, secureStorage);
});

