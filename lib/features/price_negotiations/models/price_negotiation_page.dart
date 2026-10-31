import 'package:prokat/features/bookings/models/query_result.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';

QueryResult<PriceNegotiation> parsePriceNegotiationPage(
  Object? raw, {
  required PriceNegotiationQuery query,
  required int page,
}) {
  Map<String, dynamic>? payload;
  Object? rows = raw;
  if (raw is Map) {
    payload = Map<String, dynamic>.from(raw);
    if (payload['data'] is Map) {
      payload = Map<String, dynamic>.from(payload['data'] as Map);
    }
    rows = payload['items'] ?? payload['data'];
  }
  if (rows is! List) {
    throw const FormatException('Expected price negotiation list');
  }
  final matching = rows
      .map((row) {
        if (row is! Map) {
          throw const FormatException('Invalid price negotiation item');
        }
        return PriceNegotiation.fromJson(Map<String, dynamic>.from(row));
      })
      .where((item) {
        if (query.bookingId != null && item.bookingId != query.bookingId) {
          return false;
        }
        if (query.offerId != null && item.offerId != query.offerId) {
          return false;
        }
        return switch (query.filter) {
          PriceNegotiationListFilter.active => item.isPending,
          PriceNegotiationListFilter.history =>
            !item.isPending && item.status != PriceNegotiationStatus.unknown,
          null => true,
        };
      })
      .toList();
  final legacyArray = payload == null;
  return QueryResult(
    items: legacyArray
        ? matching
              .skip((page - 1) * query.itemsPerPage)
              .take(query.itemsPerPage)
              .toList()
        : matching,
    page: (payload?['page'] as num?)?.toInt() ?? page,
    itemsPerPage:
        (payload?['itemsPerPage'] as num?)?.toInt() ?? query.itemsPerPage,
    count: (payload?['count'] as num?)?.toInt() ?? matching.length,
  );
}

PriceNegotiation resolveMessageNegotiation(
  Map<String, dynamic> eventMeta,
  List<PriceNegotiation> canonical,
) {
  final event = PriceNegotiation.fromJson(eventMeta);
  final current = canonical.where((item) => item.id == event.id).firstOrNull;
  if (current != null) {
    final eventIsNewer =
        event.updatedAt != null &&
        current.updatedAt != null &&
        event.updatedAt!.isAfter(current.updatedAt!);
    if (!eventIsNewer) return current;
  }
  if (!event.isPending) return event;
  return PriceNegotiation.fromJson({...eventMeta, 'status': 'UNKNOWN'});
}
