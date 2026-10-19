class PriceRateOption {
  final String value;
  final String label;

  const PriceRateOption({required this.value, required this.label});
}

const priceRateOptions = [
  PriceRateOption(value: "PER_TRIP", label: "Per Trip"),
  PriceRateOption(value: "PER_CUBIC_METER", label: "Per Cubic Meter"),
  PriceRateOption(value: "PER_DAY", label: "Per Day"),
  PriceRateOption(value: "PER_HOUR", label: "Per Hour"),
];

/// DTOs must preserve an absent/future unit instead of inventing a trip rate.
PriceRateOption? parseKnownRateOption(Object? value) {
  final normalized = value?.toString().trim().toUpperCase();
  for (final option in priceRateOptions) {
    if (option.value == normalized) return option;
  }
  return null;
}

PriceRateOption parseRateOption(String? value) {
  final normalized = (value ?? '').trim().toUpperCase();

  return priceRateOptions.firstWhere(
    (option) => option.value == normalized,
    orElse: () => priceRateOptions.first,
  );
}

String getRateLabel(String? value) {
  return parseRateOption(value).label;
}
