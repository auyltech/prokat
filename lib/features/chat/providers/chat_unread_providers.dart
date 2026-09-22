import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/layout/navigation_counts_provider.dart';

final clientChatUnreadCountProvider = Provider<int>(
  (ref) => ref.watch(navigationCountsProvider).valueOrNull?.clientUnread ?? 0,
);
final ownerChatUnreadCountProvider = Provider<int>(
  (ref) => ref.watch(navigationCountsProvider).valueOrNull?.ownerUnread ?? 0,
);
