import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';

OwnerRequestState getOwnerRequestState(
  RequestModel request,
  List<OfferModel> offers,
) {
  // 1. Immediately handle the empty list case safely
  if (offers.isEmpty) {
    if (request.status == RequestStatus.created) {
      return OwnerRequestState.newRequest;
    }
    if (request.status == RequestStatus.viewed) {
      return OwnerRequestState.viewed;
    }
    if (request.status == RequestStatus.responded) {
      return OwnerRequestState.viewed;
    }
    // Fallback if status is neither CREATED nor VIEWED and list is empty
    return OwnerRequestState.newRequest;
  }

  // 2. Safely extract the first offer
  final offer = offers.firstOrNull;

  // 3. Null safety check to prevent "Receiver: null" errors
  if (offer == null) {
    if (request.status == RequestStatus.created) {
      return OwnerRequestState.newRequest;
    }

    return OwnerRequestState.newRequest;
  }

  // 4. Safely read properties now that we know 'offer' is not null
  if (offer.status == OfferStatus.accepted) {
    return OwnerRequestState.accepted;
  }

  return OwnerRequestState.offerSent;
}
