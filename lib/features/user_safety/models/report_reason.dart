enum ReportReason {
  spam('SPAM'),
  abuse('ABUSE'),
  fraud('FRAUD'),
  other('OTHER');

  const ReportReason(this.apiValue);

  final String apiValue;
}
