import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';

abstract class MutationNotifier<TState> extends StateNotifier<TState> {
  MutationNotifier(super.state);

  Set<Mutation> get activeActions;

  TState copyState({Set<Mutation>? activeActions});

  void startAction(String actionId) {
    state = copyState(
      activeActions: {
        ...activeActions,
        Mutation(id: actionId, status: MutationStatus.submitting),
      },
    );
  }

  void finishAction(String actionId, {AppError? error, String? message}) {
    final actions = {...activeActions};

    actions.removeWhere((item) => item.id == actionId);

    if (error != null) {
      actions.add(
        Mutation(
          id: actionId,
          status: MutationStatus.error,
          error: error,
          message: message,
        ),
      );
    }

    state = copyState(activeActions: actions);
  }

  void clearAction(String actionId) {
    final actions = {...activeActions};

    actions.removeWhere((item) => item.id == actionId);

    state = copyState(activeActions: actions);
  }

  bool isActionActive(String actionId) {
    return activeActions.any(
      (item) => item.id == actionId && item.status == MutationStatus.submitting,
    );
  }

  Mutation? getAction(String actionId) {
    return activeActions.where((item) => item.id == actionId).firstOrNull;
  }

  AppError? getActionError(String actionId) {
    return getAction(actionId)?.error;
  }

  String? getActionMessage(String actionId) {
    return getAction(actionId)?.message;
  }
}
