import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:riverpod/riverpod.dart';

class OwnerEquipmentNotifier extends AsyncNotifier<QueryState<Equipment>> {
  late final EquipmentService api;

  @override
  Future<QueryState<Equipment>> build() async {
    api = ref.read(equipmentServiceProvider);

    return _fetch();
  }

  List<Equipment> _sortEquipment(List<Equipment> list) {
    final sorted = [...list];

    int statusPriority(EquipmentStatus status) {
      switch (status) {
        case EquipmentStatus.available:
          return 0;
        case EquipmentStatus.booked:
          return 1;
        case EquipmentStatus.maintenance:
          return 2;
        default:
          return 99;
      }
    }

    sorted.sort((a, b) {
      /// 1. Online first
      final aOnline = a.status == EquipmentStatus.available ? 0 : 1;
      final bOnline = b.status == EquipmentStatus.available ? 0 : 1;
      if (aOnline != bOnline) return aOnline.compareTo(bOnline);

      /// 2. Status priority
      final statusCompare = statusPriority(
        a.status,
      ).compareTo(statusPriority(b.status));
      if (statusCompare != 0) return statusCompare;

      /// 3. Last updated (descending)
      return (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0));
    });

    return sorted;
  }

  Future<QueryState<Equipment>> _fetch() async {
    final response = await api.getOwnerEquipment();

    final items = response.data ?? [];

    items.sort(_compareEquipment);

    return QueryState(
      items: items,
      page: 1,
      itemsPerPage: items.length,
      count: items.length,
      lastFetchedAt: DateTime.now(),
    );
  }

  int _statusPriority(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return 0;
      case EquipmentStatus.booked:
        return 1;
      case EquipmentStatus.maintenance:
        return 2;
      default:
        return 99;
    }
  }

  int _compareEquipment(Equipment a, Equipment b) {
    final aOnline = a.isVisible ? 0 : 1;
    final bOnline = b.isVisible ? 0 : 1;

    if (aOnline != bOnline) {
      return aOnline.compareTo(bOnline);
    }

    final statusCompare = _statusPriority(
      a.status,
    ).compareTo(_statusPriority(b.status));

    if (statusCompare != 0) {
      return statusCompare;
    }

    return (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0));
  }

  Future<void> refresh() async {
    final previous = state.value;

    if (previous == null) {
      state = const AsyncLoading();
    } else {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }

    state = await AsyncValue.guard(() async {
      return _fetch();
    });
  }

  Future<void> invalidate() async {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(current.copyWith(lastFetchedAt: null));
  }

  Future<void> refreshIfStale() async {
    final current = state.value;

    if (current == null) {
      await refresh();
      return;
    }

    if (current.isStale) {
      await refresh();
    }
  }

  Equipment? findById(String id) {
    final items = state.value?.items ?? const [];

    for (final equipment in items) {
      if (equipment.id == id) {
        return equipment;
      }
    }

    return null;
  }

  int get onlineEquipmentCount {
    return (state.value?.items ?? const [])
        .where((item) => item.isVisible)
        .length;
  }

  Future<void> replaceItem(
    String equipmentId,
    Equipment Function(Equipment current) builder,
  ) async {
    final current = state.value;

    if (current == null) return;

    final items = current.items.map((item) {
      if (item.id != equipmentId) return item;

      return builder(item);
    }).toList();

    state = AsyncData(current.copyWith(items: items));
  }
}
