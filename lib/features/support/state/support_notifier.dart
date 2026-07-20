import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/support/state/support_service.dart';
import 'package:prokat/features/support/state/support_state.dart';

class SupportNotifier extends StateNotifier<SupportState> {
  final SupportService service;
  final Ref ref;

  SupportNotifier({required this.service, required this.ref})
    : super(SupportState());

  void _startAction(String actionId) {
    state = state.copyWith(
      activeActions: {
        ...state.activeActions,
        Mutation(id: actionId, status: MutationStatus.submitting),
      },
    );
  }

  void _finishAction(String actionId, {AppError? error}) {
    final actions = {...state.activeActions};

    if (error == null) {
      actions.remove(Mutation(id: actionId, status: MutationStatus.submitting));
    } else {
      actions.remove(Mutation(id: actionId, status: MutationStatus.submitting));

      final action = Mutation(
        id: actionId,
        status: MutationStatus.error,
        error: error,
      );

      actions.add(action);
    }

    state = state.copyWith(activeActions: actions);
  }

  Future<MutationResponse> submitInquiry({
    required String fullName,
    required String? email,
    required String? phoneNumber,
    required String topic,
    required String message,
  }) async {
    const actionId = "support:create";

    try {
      if (fullName.isEmpty ||
          (email == null && phoneNumber == null) ||
          topic.isEmpty ||
          message.isEmpty) {
        return MutationResponse(
          success: false,
          message: "Please provide required information",
        );
      }

      _startAction(actionId);

      final result = await service.submitInquiry(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        topic: topic,
        message: message,
      );

      _finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      return MutationResponse(
        success: result.success,
        message: result.success ? "Inquiry submitted" : result.message,
      );
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to submit inquiry",
          code: "",
        ),
      );

      return MutationResponse(
        success: false,
        message: "Failed to submit inquiry",
      );
    }
  }
}
