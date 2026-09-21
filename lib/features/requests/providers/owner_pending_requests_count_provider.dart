import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/requests/state/request_lifetime.dart';

/// Tenders still waiting for this owner: neither rejected nor answered.
///
/// Rejecting hides the request server-side, so it leaves both the feed and this
/// count. Sending an offer counts as handled. Merely opening the tender screen
/// changes nothing, so the badge does not reset on navigation.
final ownerPendingRequestsCountProvider = Provider<int>((ref) {
  final requests = ref.watch(ownerActiveRequestsProvider).valueOrNull;
  if (requests == null) return 0;

  final offers = ref
      .watch(ownerOffersProvider(const OfferQuery.active()))
      .valueOrNull;

  final answeredRequestIds = <String>{
    for (final offer in offers?.items ?? const <OfferModel>[])
      if (offer.status == OfferStatus.created ||
          offer.status == OfferStatus.accepted)
        offer.requestId,
  };

  return requests.items.where((request) {
    if (isArchivedRequestStatus(request.status)) return false;
    if (requestLifetimeRemaining(request.createdAt) <= Duration.zero) {
      return false;
    }
    return !answeredRequestIds.contains(request.id);
  }).length;
});
