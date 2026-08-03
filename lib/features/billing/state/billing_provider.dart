import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/billing/state/billing_notifier.dart';
import 'package:prokat/features/billing/state/billing_service.dart';
import 'package:prokat/features/billing/state/billing_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  final api = ref.watch(apiClientProvider);

  return BillingService(api);
});

final billingProvider = StateNotifierProvider<BillingNotifier, BillingState>((
  ref,
) {
  final service = ref.read(billingServiceProvider);
  return BillingNotifier(service);
});
