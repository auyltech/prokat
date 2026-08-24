bool isIncomingWorkflowStale(DateTime? existing, DateTime incoming) {
  if (existing == null) return false;
  return existing.isAfter(incoming);
}

DateTime? laterTimestamp(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}
