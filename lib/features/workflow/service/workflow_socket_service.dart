import 'package:prokat/core/services/app_socket_service.dart';
import 'package:prokat/features/workflow/models/workflow_update.dart';

class WorkflowSocketService {
  static const String updateEvent = 'workflow:update';

  final AppSocketService appSocket;

  final List<_WorkflowListenerRegistration> _listeners = [];
  bool _socketAttached = false;

  WorkflowSocketService(this.appSocket);

  Future<void> connect() async {
    await appSocket.connect();
  }

  void Function() onUpdate(void Function(WorkflowUpdate update) handler) {
    final token = Object();
    _listeners.add(
      _WorkflowListenerRegistration(token: token, handler: handler),
    );
    _attachActiveListener();

    return () {
      _listeners.removeWhere(
        (registration) => identical(registration.token, token),
      );
      _attachActiveListener();
    };
  }

  void _attachActiveListener() {
    if (_listeners.isEmpty) {
      if (_socketAttached) {
        appSocket.off(updateEvent);
        _socketAttached = false;
      }
      return;
    }

    if (_socketAttached) return;

    _socketAttached = true;
    appSocket.on(updateEvent, (payload) {
      final update = WorkflowUpdate.tryParse(payload);
      if (update == null) return;

      for (final registration in List<_WorkflowListenerRegistration>.from(
        _listeners,
      )) {
        registration.handler(update);
      }
    });
  }

  void dispose() {
    _listeners.clear();
    _socketAttached = false;
    appSocket.off(updateEvent);
  }
}

class _WorkflowListenerRegistration {
  final Object token;
  final void Function(WorkflowUpdate update) handler;

  const _WorkflowListenerRegistration({
    required this.token,
    required this.handler,
  });
}
