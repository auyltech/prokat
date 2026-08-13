import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'equipment_demand_models.dart';
import 'equipment_demand_service.dart';

final equipmentDemandServiceProvider = Provider((ref) {
  return EquipmentDemandService(ref.watch(apiClientProvider));
});

class DemandConfigNotifier extends AsyncNotifier<DemandConfig> {
  @override
  Future<DemandConfig> build() async {
    try {
      return await ref.read(equipmentDemandServiceProvider).getConfig();
    } catch (_) {
      return const DemandConfig.disabled();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(equipmentDemandServiceProvider).getConfig(),
    );
  }

  void markResponded(String campaignId) {
    final current = state.valueOrNull;
    if (current != null) state = AsyncData(current.markResponded(campaignId));
  }
}

final demandConfigProvider =
    AsyncNotifierProvider<DemandConfigNotifier, DemandConfig>(
      DemandConfigNotifier.new,
    );

final demandFormProvider = FutureProvider.family<DemandForm, String>((
  ref,
  campaignId,
) {
  final locale = ref.watch(localeProvider).languageCode;
  return ref.watch(equipmentDemandServiceProvider).getForm(campaignId, locale);
});
