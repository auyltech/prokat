enum PriceNegotiationResponse { accept, reject }

String toBackendPriceNegotiationResponse(PriceNegotiationResponse response) {
  switch (response) {
    case PriceNegotiationResponse.accept:
      return 'ACCEPT';
    case PriceNegotiationResponse.reject:
      return 'REJECT';
  }
}

