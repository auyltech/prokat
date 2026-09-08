import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/workflow/service/workflow_socket_service.dart';
import 'package:prokat/features/workflow/state/workflow_cache_coordinator.dart';

final workflowSocketServiceProvider = Provider<WorkflowSocketService>((ref) {
  final appSocket = ref.watch(appSocketProvider);
  final service = WorkflowSocketService(appSocket);
  ref.onDispose(service.dispose);
  return service;
});

final workflowCacheCoordinatorProvider = Provider<WorkflowCacheCoordinator>((
  ref,
) {
  return WorkflowCacheCoordinator(ref);
});
