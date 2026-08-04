import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/mutation/mutation_notifier.dart';
import 'package:prokat/features/bookings/providers/client_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/client_history_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_history_bookings_provider.dart';
import 'package:prokat/features/chat/state/post_mutation_cache_coordinator.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/state/offers_service.dart';
import 'package:prokat/features/offers/state/offers_state.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/providers/client_active_requests_provider.dart';
import 'package:prokat/features/requests/providers/client_history_requests_provider.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';

class OfferMutationNotifier extends MutationNotifier<OffersState> {
  OfferMutationNotifier({required this.service, required this.ref})
    : super(OffersState());

  final OffersService service;
  final Ref ref;

  PostMutationCacheCoordinator get _cacheCoordinator =>
      ref.read(postMutationCacheCoordinatorProvider);

  @override
  Set<Mutation> get activeActions => state.activeActions;

  @override
  OffersState copyState({Set<Mutation>? activeActions}) =>
      state.copyWith(activeActions: activeActions);

  void selectRequest(RequestModel request) {
    state = state.copyWith(
      selectedRequest: request,
      selectedDate: request.requiredOn,
      selectedTime: request.requiredAt,
      price: request.offeredPrice,
    );
  }

  void selectEquipment(EquipmentSummaryModel value) =>
      state = state.copyWith(selectedEquipment: value);
  void setPrice(int value) => state = state.copyWith(price: value);
  void setPriceRate(PriceRateOption value) =>
      state = state.copyWith(priceRate: value);
  void setDate(DateTime value) => state = state.copyWith(selectedDate: value);
  void setTime(DateTime value) => state = state.copyWith(selectedTime: value);
  void setComment(String value) => state = state.copyWith(comment: value);

  Future<void> _refreshOfferQuery({
    required bool owner,
    required OfferQuery query,
  }) async {
    final provider = owner
        ? ownerOffersProvider(query)
        : clientOffersProvider(query);
    if (ref.exists(provider)) {
      await ref.read(provider.notifier).refresh();
    }
  }

  Future<void> _invalidateOfferHistory({required bool owner}) async {
    final provider = owner
        ? ownerOffersProvider(const OfferQuery.history())
        : clientOffersProvider(const OfferQuery.history());
    if (ref.exists(provider)) {
      await ref.read(provider.notifier).invalidate();
    }
  }

  Future<void> _refreshRequestSpecific({
    required bool owner,
    required String requestId,
  }) async {
    await Future.wait([
      _refreshOfferQuery(
        owner: owner,
        query: OfferQuery(requestId: requestId),
      ),
      _refreshOfferQuery(
        owner: owner,
        query: OfferQuery(
          filter: OfferListFilter.active,
          requestId: requestId,
        ),
      ),
    ]);
  }

  Future<void> _invalidateRequestHistory({
    required bool owner,
    required String requestId,
  }) async {
    final query = OfferQuery(
      filter: OfferListFilter.history,
      requestId: requestId,
    );
    final provider = owner
        ? ownerOffersProvider(query)
        : clientOffersProvider(query);
    if (ref.exists(provider)) {
      await ref.read(provider.notifier).invalidate();
    }
  }

  Future<void> _refreshRequestQuery(bool owner) async {
    if (owner && ref.exists(ownerActiveRequestsProvider)) {
      await ref.read(ownerActiveRequestsProvider.notifier).refresh();
    } else if (!owner && ref.exists(clientActiveRequestsProvider)) {
      await ref.read(clientActiveRequestsProvider.notifier).refresh();
    }
  }

  Future<void> _refreshBookingQueries() async {
    final updates = <Future<void>>[];
    if (ref.exists(clientActiveBookingsProvider)) {
      updates.add(ref.read(clientActiveBookingsProvider.notifier).refresh());
    }
    if (ref.exists(ownerActiveBookingsProvider)) {
      updates.add(ref.read(ownerActiveBookingsProvider.notifier).refresh());
    }
    if (ref.exists(clientHistoryBookingsProvider)) {
      updates.add(
        ref.read(clientHistoryBookingsProvider.notifier).invalidate(),
      );
    }
    if (ref.exists(ownerHistoryBookingsProvider)) {
      updates.add(ref.read(ownerHistoryBookingsProvider.notifier).invalidate());
    }
    if (ref.exists(clientHistoryRequestsProvider)) {
      updates.add(ref.read(clientHistoryRequestsProvider.notifier).invalidate());
    }
    if (ref.exists(ownerActiveRequestsProvider)) {
      updates.add(ref.read(ownerActiveRequestsProvider.notifier).refresh());
    }
    await Future.wait(updates);
  }

  Future<MutationResponse> createOffer() async {
    const actionId = 'offer:create';
    if (state.selectedEquipment == null ||
        state.selectedRequest == null ||
        state.price == null ||
        state.priceRate == null ||
        state.selectedDate == null ||
        state.selectedTime == null) {
      return MutationResponse(
        success: false,
        message: 'Please provide required information',
      );
    }
    startAction(actionId);
    try {
      final result = await service.createOffer(
        requestId: state.selectedRequest!.id,
        equipmentId: state.selectedEquipment!.id ?? '',
        price: state.price!,
        priceRate: state.priceRate!.value,
        comment: state.comment,
      );
      finishAction(actionId, error: _error(result.success, result.message));
      if (result.success) {
        final requestId = state.selectedRequest!.id;
        await Future.wait([
          _refreshOfferQuery(owner: true, query: const OfferQuery.active()),
          _refreshRequestSpecific(owner: true, requestId: requestId),
          _refreshRequestQuery(true),
        ]);
        state = OffersState();
      }
      return MutationResponse(success: result.success, message: result.message);
    } catch (error) {
      finishAction(actionId, error: _error(false, error.toString()));
      return MutationResponse(
        success: false,
        message: 'Failed to create offer',
      );
    }
  }

  Future<MutationResponse> acceptOffer(
    String id, {
    String? chatId,
    String? requestId,
  }) => _mutateExisting(
    actionId: 'offer:accept:$id',
    call: () => service.acceptOffer(id: id),
    owner: false,
    requestId: requestId,
    chatId: chatId,
    successMessage: 'Offer accepted',
    onSuccess: _refreshBookingQueries,
  );

  Future<MutationResponse> rejectOffer(
    String id, {
    String? chatId,
    String? requestId,
  }) => _mutateExisting(
    actionId: 'offer:reject:$id',
    call: () => service.rejectOffer(id: id),
    owner: false,
    requestId: requestId,
    chatId: chatId,
    successMessage: 'Offer rejected',
  );

  Future<MutationResponse> cancelOffer(
    String id, {
    String? chatId,
    String? requestId,
  }) => _mutateExisting(
    actionId: 'offer:cancel:$id',
    call: () => service.cancelOffer(id: id),
    owner: true,
    requestId: requestId,
    chatId: chatId,
    successMessage: 'Offer cancelled',
  );

  Future<MutationResponse> _mutateExisting({
    required String actionId,
    required Future<dynamic> Function() call,
    required bool owner,
    required String successMessage,
    String? requestId,
    String? chatId,
    Future<void> Function()? onSuccess,
  }) async {
    startAction(actionId);
    try {
      final result = await call();
      final success = result.success == true;
      finishAction(actionId, error: _error(success, result.message.toString()));
      if (success) {
        final updates = <Future<void>>[
          _refreshOfferQuery(owner: owner, query: const OfferQuery.active()),
          _invalidateOfferHistory(owner: owner),
          _refreshRequestQuery(owner),
          _cacheCoordinator.refreshAffectedChats(chatId),
        ];
        if ((requestId ?? '').isNotEmpty) {
          updates.addAll([
            _refreshRequestSpecific(owner: owner, requestId: requestId!),
            _invalidateRequestHistory(owner: owner, requestId: requestId),
          ]);
        }
        if (onSuccess != null) updates.add(onSuccess());
        await Future.wait(updates);
      }
      return MutationResponse(
        success: success,
        message: success ? successMessage : result.message.toString(),
      );
    } catch (error) {
      finishAction(actionId, error: _error(false, error.toString()));
      return MutationResponse(success: false, message: error.toString());
    }
  }

  AppError? _error(bool success, String message) => success
      ? null
      : AppError(type: ErrorType.unknown, code: '', message: message);
}
