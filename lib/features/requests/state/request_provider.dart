import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';
import 'package:prokat/features/requests/state/request_notifier.dart';
import 'package:prokat/features/requests/state/request_state.dart';

final requestServiceProvider = Provider<RequestService>((ref) {
  final dio = ref.watch(apiClientProvider);

  return RequestService(dio);
});

final requestProvider = StateNotifierProvider<RequestNotifier, RequestState>((
  ref,
) {
  final service = ref.read(requestServiceProvider);
  return RequestNotifier(service);
});
