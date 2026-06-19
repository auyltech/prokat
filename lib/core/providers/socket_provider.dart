import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/services/app_socket_service.dart';

final appSocketProvider = Provider<AppSocketService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppSocketService(apiClient, ref);
});
