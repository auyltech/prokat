import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_tile.dart';

OwnerRequestUIState getOwnerRequestState(
  RequestModel request,
  List<OfferModel> offers,
) {
  if (offers.isEmpty) {
    if (request.status == "CREATED") return OwnerRequestUIState.newRequest;
    if (request.status == "VIEWED") return OwnerRequestUIState.viewed;
  }

  final offer = offers.first;

  if (offer.status == "ACCEPTED") {
    return OwnerRequestUIState.accepted;
  }

  return OwnerRequestUIState.offerSent;
}
