import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_service.dart';
import 'package:prokat/features/offers/state/offers_state.dart';
import 'package:prokat/features/requests/models/request_model.dart';

class OffersNotifier extends StateNotifier<OffersState> {
  final OffersService service;
  final Ref ref;

  OffersNotifier({required this.service, required this.ref})
    : super(OffersState());

  void selectRequest(RequestModel request) {
    state = state.copyWith(
      selectedRequest: request,
      selectedDate: request.requiredOn,
      selectedTime: request.requiredAt,
      price: request.offeredPrice,
    );
  }

  void selectEquipment(EquipmentSummaryModel equipment) {
    state = state.copyWith(selectedEquipment: equipment);
  }

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

  void invalidate({required AppMode mode}) {
    state = state.copyWith(fetchStatus: FetchStatus.stale);
  }

  List<OfferModel> getActiveOffers(String requestId, String? mode) {
    return (mode == "owner" ? state.ownerOffers : state.clientOffers)
        .where(
          (item) =>
              item.requestId == requestId &&
              [OfferStatus.created, OfferStatus.viewed].contains(item.status),
        )
        .toList();
  }

  OfferModel? getLastRequestOffer(String requestId, String? mode) {
    // 1. Filter the correct list based on the mode
    final filtered = (mode == "owner" ? state.ownerOffers : state.clientOffers)
        .where((item) => item.requestId == requestId)
        .toList(); // Creates a modifiable list

    // 2. Return null early if no matching items exist
    if (filtered.isEmpty) return null;

    // 3. Sort the list in-place (latest date first)
    filtered.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(1970);
      final bDate = b.createdAt ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    // 4. Return the ID of the first (most recent) item
    return filtered.first;
  }

  bool hasActiveOffer(String requestId, String? mode) {
    final activeOffers = getActiveOffers(requestId, mode);

    return activeOffers.isNotEmpty;
  }

  void setPrice(int price) {
    state = state.copyWith(price: price);
  }

  void setPriceRate(PriceRateOption priceRate) {
    state = state.copyWith(priceRate: priceRate);
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setTime(DateTime time) {
    state = state.copyWith(selectedTime: time);
  }

  void setComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  Future<void> getClientOffers() async {
    try {
      final hasData = state.clientOffers.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await service.getClientOffers();

      state = state.copyWith(
        clientOffers: result.data,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "OFFERS_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.clientOffers.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "OFFERS_FETCH_FAILED",
        ),
      );
    }
  }

  Future<MutationResponse> acceptOffer(String id, {String? chatId}) async {
    final actionId = "offer:accept:$id";

    try {
      _startAction(actionId);

      final result = await service.acceptOffer(id: id);

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

      if (result.success) {
        getClientOffers();
        // ref.read(chatProvider.notifier).getChatThreads(AppMode.clientMode);
      }

      return MutationResponse(
        success: result.success,
        message: result.success ? "Offer accepted" : result.message,
      );
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to accept offer",
          code: "",
        ),
      );

      return MutationResponse(
        success: false,
        message: "Failed to accept offer",
      );
    }
  }

  Future<MutationResponse> rejectOffer(String id, {String? chatId}) async {
    final actionId = "offer:reject:$id";

    try {
      _startAction(actionId);

      final result = await service.rejectOffer(id: id);

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

      if (result.success) {
        getClientOffers();
        // ref.read(chatProvider.notifier).getChatThreads(AppMode.clientMode);
      }

      return MutationResponse(
        success: result.success,
        message: result.success ? "Offer rejected" : result.message,
      );
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to reject offer",
          code: "",
        ),
      );

      return MutationResponse(
        success: false,
        message: "Failed to reject offer",
      );
    }
  }

  Future<void> getOwnerOffers() async {
    try {
      final hasData = state.ownerOffers.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await service.getOwnerOffers();

      state = state.copyWith(
        ownerOffers: result.data,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "OFFERS_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.ownerOffers.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "OFFERS_FETCH_FAILED",
        ),
      );
    }
  }

  Future<MutationResponse> createOffer() async {
    const actionId = "offer:create";

    try {
      if (state.selectedEquipment == null ||
          state.price == null ||
          state.priceRate == null ||
          state.selectedDate == null ||
          state.selectedTime == null) {
        return MutationResponse(
          success: false,
          message: "Please provide required information",
        );
      }

      _startAction(actionId);

      // TODO: SEND DATE AND TIME
      final result = await service.createOffer(
        price: state.price ?? 0,
        priceRate: state.priceRate.toString(),
        comment: state.comment,
        equipmentId: state.selectedEquipment?.id ?? "",
        requestId: state.selectedRequest?.id ?? "",
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

      if (result.success) {
        getOwnerOffers();
        // ref.read(chatProvider.notifier).getChatThreads(AppMode.ownerMode);
      }

      return MutationResponse(
        success: result.success,
        message: result.success ? "Offer created" : result.message,
      );
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to create offer",
          code: "",
        ),
      );

      return MutationResponse(
        success: false,
        message: "Failed to create offer",
      );
    }
  }

  Future<MutationResponse> cancelOffer(String id, {String? chatId}) async {
    final actionId = "offer:cancel:$id";

    try {
      _startAction(actionId);

      final result = await service.cancelOffer(id: id);

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

      if (result.success) {
        getOwnerOffers();
        // ref.read(chatProvider.notifier).getChatThreads(AppMode.ownerMode);
      }

      return MutationResponse(
        success: result.success,
        message: result.success ? "Offer cancelled" : result.message,
      );
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to cancel offer",
          code: "",
        ),
      );

      return MutationResponse(
        success: false,
        message: "Failed to cancel offer",
      );
    }
  }
}
