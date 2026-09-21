import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/layout/navigation_counts_provider.dart';

final ownerPendingRequestsCountProvider = Provider<int>(
  (ref) =>
      ref.watch(navigationCountsProvider).valueOrNull?.pendingRequests ?? 0,
);
