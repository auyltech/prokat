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

PriceRateOption parseRateOption(String? value) {
  final normalized = (value ?? '').trim().toUpperCase();
  if (normalized.isEmpty || normalized == 'NULL') {
    return priceRateOptions.first;
  }

  return priceRateOptions.firstWhere(
    (option) => option.value == normalized,
    // Keep unknown backend codes (e.g. PER_MONTH) — never remap to PER_TRIP.
    orElse: () => PriceRateOption(value: normalized, label: normalized),
  );
}

String getRateLabel(String? value) {
  return parseRateOption(value).label;
}
