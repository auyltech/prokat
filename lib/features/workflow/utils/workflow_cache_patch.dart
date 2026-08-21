import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/booking_status_buckets.dart';
import 'package:prokat/features/bookings/models/booking_summary_model.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/models/chat_list_filter.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/workflow/models/workflow_update.dart';
import 'package:prokat/features/workflow/utils/workflow_updated_at.dart';

enum WorkflowChatApplyStatus { applied, removed, notFound, skipped }

class WorkflowChatApplyResult {
  const WorkflowChatApplyResult({
    required this.status,
    required this.items,
    required this.count,
  });

  final WorkflowChatApplyStatus status;
  final List<ChatModel> items;
  final int count;
}

bool isChatArchived(ChatModel chat) {
  if (chat.type == ChatType.support) return false;

  final bookingStatus = chat.booking?.status;
  if (bookingStatus != null && isHistoryBookingStatus(bookingStatus)) {
    return true;
  }

  final summaryStatus = chat.bookingSummary == null
      ? null
      : parseBookingStatus(chat.bookingSummary!.status);
  if (summaryStatus != null &&
      summaryStatus != BookingStatus.draft &&
      isHistoryBookingStatus(summaryStatus)) {
    return true;
  }

  final requestStatus = chat.request?.status;
  if (requestStatus != null && isArchivedRequestStatus(requestStatus)) {
    return true;
  }

  return false;
}

ChatModel applyWorkflowDeltaToChat(ChatModel chat, WorkflowUpdate update) {
  var next = chat;

  final bookingDelta = update.booking;
  if (bookingDelta != null) {
    if (!isIncomingWorkflowStale(
      chat.booking?.updatedAt,
      bookingDelta.updatedAt,
    )) {
      next = next.copyWith(
        booking: _patchBooking(chat.booking, bookingDelta),
        bookingSummary: _patchBookingSummary(chat.bookingSummary, bookingDelta),
        bookingId: bookingDelta.id,
      );
    }
  }

  final requestDelta = update.request;
  if (requestDelta != null) {
    if (!isIncomingWorkflowStale(
      next.request?.updatedAt,
      requestDelta.updatedAt,
    )) {
      final patchedRequest = next.request?.copyWith(
        status: requestDelta.status,
        updatedAt: requestDelta.updatedAt,
      );
      if (patchedRequest != null) {
        next = next.copyWith(request: patchedRequest);
      }
    }
  }

  final offerDeltas = update.offers;
  if (offerDeltas != null && offerDeltas.isNotEmpty && next.offers.isNotEmpty) {
    final byId = {for (final offer in offerDeltas) offer.id: offer};
    final offers = next.offers.map((offer) {
      final delta = byId[offer.id];
      if (delta == null) return offer;
      if (isIncomingWorkflowStale(offer.updatedAt, delta.updatedAt)) {
        return offer;
      }
      return offer.copyWith(status: delta.status, updatedAt: delta.updatedAt);
    }).toList();
    next = next.copyWith(offers: offers);
  }

  return next;
}

WorkflowChatApplyResult applyWorkflowUpdateToChatItems({
  required List<ChatModel> items,
  required int count,
  required ChatListFilter filter,
  required WorkflowUpdate update,
}) {
  final chatId = update.chatId?.trim() ?? '';
  if (chatId.isEmpty) {
    return WorkflowChatApplyResult(
      status: WorkflowChatApplyStatus.skipped,
      items: items,
      count: count,
    );
  }

  final index = items.indexWhere((chat) => chat.id == chatId);
  if (index < 0) {
    return WorkflowChatApplyResult(
      status: WorkflowChatApplyStatus.notFound,
      items: items,
      count: count,
    );
  }

  final patched = applyWorkflowDeltaToChat(items[index], update);
  final belongsInArchive = isChatArchived(patched);
  final shouldKeep = filter == ChatListFilter.archived
      ? belongsInArchive
      : !belongsInArchive;

  if (!shouldKeep) {
    final nextItems = [...items]..removeAt(index);
    return WorkflowChatApplyResult(
      status: WorkflowChatApplyStatus.removed,
      items: nextItems,
      count: count > 0 ? count - 1 : 0,
    );
  }

  final nextItems = [...items];
  nextItems[index] = patched;
  return WorkflowChatApplyResult(
    status: WorkflowChatApplyStatus.applied,
    items: nextItems,
    count: count,
  );
}

ChatModel mergeChatPreferringNewerWorkflow(
  ChatModel incoming,
  ChatModel previous,
) {
  var merged = incoming;

  final previousBooking = previous.booking;
  final incomingUpdatedAt =
      incoming.booking?.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  if (previousBooking != null &&
      isIncomingWorkflowStale(previousBooking.updatedAt, incomingUpdatedAt)) {
    merged = merged.copyWith(
      booking: previousBooking,
      bookingSummary: previous.bookingSummary ?? incoming.bookingSummary,
    );
  }

  final previousRequest = previous.request;
  final incomingRequestUpdatedAt =
      incoming.request?.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  if (previousRequest != null &&
      isIncomingWorkflowStale(
        previousRequest.updatedAt,
        incomingRequestUpdatedAt,
      )) {
    merged = merged.copyWith(request: previousRequest);
  }

  return merged;
}

BookingModel _patchBooking(BookingModel? current, WorkflowBookingDelta delta) {
  if (current == null) {
    return BookingModel(
      id: delta.id,
      status: delta.status,
      workStatus: delta.workStatus,
      price: delta.price,
      priceRate: delta.priceRate,
      updatedAt: delta.updatedAt,
    );
  }

  return current.copyWith(
    status: delta.status,
    workStatus: delta.workStatus,
    price: delta.price,
    priceRate: delta.priceRate,
    updatedAt: delta.updatedAt,
  );
}

BookingSummaryModel _patchBookingSummary(
  BookingSummaryModel? current,
  WorkflowBookingDelta delta,
) {
  return (current ??
          BookingSummaryModel(id: delta.id, status: delta.status.name))
      .copyWith(
        id: delta.id,
        status: delta.status.name.toUpperCase(),
        workStatus: delta.workStatus,
      );
}

enum BookingQueryPatchKind { active, history }

enum BookingQueryApplyStatus {
  patched,
  removed,
  notFound,
  skippedStale,
  skipped,
}

class BookingQueryApplyResult {
  const BookingQueryApplyResult({required this.status, this.state});

  final BookingQueryApplyStatus status;
  final QueryState<BookingModel>? state;
}

BookingQueryApplyResult applyBookingDeltaToQuery({
  required QueryState<BookingModel> current,
  required WorkflowBookingDelta delta,
  required BookingQueryPatchKind kind,
}) {
  final index = current.items.indexWhere((item) => item.id == delta.id);
  if (index < 0) {
    return const BookingQueryApplyResult(
      status: BookingQueryApplyStatus.notFound,
    );
  }

  final existing = current.items[index];
  if (isIncomingWorkflowStale(existing.updatedAt, delta.updatedAt)) {
    return const BookingQueryApplyResult(
      status: BookingQueryApplyStatus.skippedStale,
    );
  }

  final belongsInHistory = isHistoryBookingStatus(delta.status);
  final keepInThisList = kind == BookingQueryPatchKind.history
      ? belongsInHistory
      : !belongsInHistory;

  if (!keepInThisList) {
    final items = [...current.items]..removeAt(index);
    return BookingQueryApplyResult(
      status: BookingQueryApplyStatus.removed,
      state: current.copyWith(
        items: items,
        count: current.count > 0 ? current.count - 1 : 0,
      ),
    );
  }

  final items = [...current.items];
  items[index] = existing.copyWith(
    status: delta.status,
    workStatus: delta.workStatus,
    price: delta.price,
    priceRate: delta.priceRate,
    updatedAt: delta.updatedAt,
  );

  return BookingQueryApplyResult(
    status: BookingQueryApplyStatus.patched,
    state: current.copyWith(items: items),
  );
}

enum RequestQueryPatchKind { active, history }

enum RequestQueryApplyStatus {
  patched,
  removed,
  notFound,
  skippedStale,
  skipped,
}

class RequestQueryApplyResult {
  const RequestQueryApplyResult({required this.status, this.state});

  final RequestQueryApplyStatus status;
  final QueryState<RequestModel>? state;
}

RequestQueryApplyResult applyRequestDeltaToQuery({
  required QueryState<RequestModel> current,
  required WorkflowRequestDelta delta,
  required RequestQueryPatchKind kind,
}) {
  final index = current.items.indexWhere((item) => item.id == delta.id);
  if (index < 0) {
    return const RequestQueryApplyResult(
      status: RequestQueryApplyStatus.notFound,
    );
  }

  final existing = current.items[index];
  if (isIncomingWorkflowStale(existing.updatedAt, delta.updatedAt)) {
    return const RequestQueryApplyResult(
      status: RequestQueryApplyStatus.skippedStale,
    );
  }

  final belongsInHistory = isArchivedRequestStatus(delta.status);
  final keepInThisList = kind == RequestQueryPatchKind.history
      ? belongsInHistory
      : !belongsInHistory;

  if (!keepInThisList) {
    final items = [...current.items]..removeAt(index);
    return RequestQueryApplyResult(
      status: RequestQueryApplyStatus.removed,
      state: current.copyWith(
        items: items,
        count: current.count > 0 ? current.count - 1 : 0,
      ),
    );
  }

  final items = [...current.items];
  items[index] = existing.copyWith(
    status: delta.status,
    updatedAt: delta.updatedAt,
  );

  return RequestQueryApplyResult(
    status: RequestQueryApplyStatus.patched,
    state: current.copyWith(items: items),
  );
}

List<BookingModel> mergeBookingsPreferringNewer({
  required List<BookingModel> incoming,
  required List<BookingModel> previous,
}) {
  if (previous.isEmpty) return incoming;
  final previousById = {for (final item in previous) item.id: item};

  return incoming.map((item) {
    final cached = previousById[item.id];
    if (cached == null) return item;
    if (isIncomingWorkflowStale(
      cached.updatedAt,
      item.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    )) {
      return cached;
    }
    return item;
  }).toList();
}
