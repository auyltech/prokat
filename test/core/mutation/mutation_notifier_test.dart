import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/mutation/mutation_notifier.dart';

void main() {
  test('retry replaces an error action with submitting state', () {
    final notifier = _TestMutationNotifier();
    addTearDown(notifier.dispose);

    notifier.startAction('equipment:update:1');
    notifier.finishAction(
      'equipment:update:1',
      error: const AppError(
        type: ErrorType.unknown,
        code: 'failed',
        message: 'Update failed',
      ),
    );
    notifier.startAction('equipment:update:2');

    expect(notifier.getAction('equipment:update:1')?.isError, isTrue);

    notifier.startAction('equipment:update:1');

    final retriedAction = notifier.getAction('equipment:update:1');
    expect(notifier.activeActions, hasLength(2));
    expect(retriedAction?.status, MutationStatus.submitting);
    expect(retriedAction?.error, isNull);
    expect(
      notifier.getAction('equipment:update:2')?.status,
      MutationStatus.submitting,
    );
  });
}

class _TestMutationNotifier extends MutationNotifier<Set<Mutation>> {
  _TestMutationNotifier() : super(<Mutation>{});

  @override
  Set<Mutation> get activeActions => state;

  @override
  Set<Mutation> copyState({Set<Mutation>? activeActions}) {
    return activeActions ?? state;
  }
}
