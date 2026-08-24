class EventIdLru {
  EventIdLru({this.maxSize = 100});

  final int maxSize;
  final List<String> _order = [];
  final Set<String> _ids = {};

  bool remember(String eventId) {
    final id = eventId.trim();
    if (id.isEmpty) return false;
    if (_ids.contains(id)) return false;

    _ids.add(id);
    _order.add(id);

    while (_order.length > maxSize) {
      final removed = _order.removeAt(0);
      _ids.remove(removed);
    }

    return true;
  }

  bool contains(String eventId) => _ids.contains(eventId.trim());
}
