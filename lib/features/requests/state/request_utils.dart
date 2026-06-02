import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_tile.dart';

OwnerRequestUIState getOwnerRequestState(
  RequestModel request,
  List<OfferModel> offers,
) {
  // 1. Immediately handle the empty list case safely
  if (offers.isEmpty) {
    if (request.status == "CREATED") return OwnerRequestUIState.newRequest;
    if (request.status == "VIEWED") return OwnerRequestUIState.viewed;
    // Fallback if status is neither CREATED nor VIEWED and list is empty
    return OwnerRequestUIState.newRequest;
  }

  // 2. Safely extract the first offer
  final offer = offers.firstOrNull;

  // 3. Null safety check to prevent "Receiver: null" errors
  if (offer == null) {
    if (request.status == "CREATED") return OwnerRequestUIState.newRequest;
    return OwnerRequestUIState.newRequest;
  }

  // 4. Safely read properties now that we know 'offer' is not null
  if (offer.status == "ACCEPTED") {
    return OwnerRequestUIState.accepted;
  }

  return OwnerRequestUIState.offerSent;
}
