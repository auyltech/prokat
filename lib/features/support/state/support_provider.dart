import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/support/state/support_notifier.dart';
import 'package:prokat/features/support/state/support_service.dart';
import 'package:prokat/features/support/state/support_state.dart';

final supportApiProvider = Provider<SupportService>((ref) {
  final api = ref.read(apiClientProvider);

  return SupportService(api);
});

final supportProvider = StateNotifierProvider<SupportNotifier, SupportState>((
  ref,
) {
  final service = ref.read(supportApiProvider);

  return SupportNotifier(service: service, ref: ref);
});
