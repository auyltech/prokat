import 'package:flutter/material.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment/providers/equipment_dependencies.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/providers/owner_fleet_groups_provider.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_notifier.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/features/equipment/state/owner_equipment_notifier.dart';
import 'package:prokat/features/equipment/state/owner_equipment_details_notifier.dart';
import 'package:prokat/features/equipment/screens/owner_equipment_detail_screen.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_detail_title.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';

import 'company_profile_api.dart';
import 'company_profile_screen.dart';
import 'company_park_screen.dart';

/// Owns a separate navigation tree and equipment cache. A company member keeps
/// their personal account role; authorization is checked by the company API.
class CompanyWorkspace extends ConsumerWidget {
  final String companyId;
  const CompanyWorkspace({super.key, required this.companyId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(companyAccessProvider);
    return access.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Профиль компании')),
        body: Center(
          child: AppElevatedButton(
            title: 'Повторить',
            onTap: () => ref.invalidate(companyAccessProvider),
          ),
        ),
      ),
      data: (data) {
        final memberships = (data['memberships'] as List).cast<Map>();
        final membership = memberships
            .where(
              (m) =>
                  m['companyId'] == companyId &&
                  m['company']['status'] == 'APPROVED',
            )
            .firstOrNull;
        if (membership == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Профиль компании')),
            body: const Center(child: Text('Нет доступа к компании')),
          );
        }
        final company = membership['company'] as Map;
        final service = EquipmentService(
          ref.read(apiClientProvider),
          companyId: companyId,
          companyCity: company['city'],
        );
        return ProviderScope(
          key: ValueKey('$companyId:${company['city']}'),
          overrides: [
            equipmentServiceProvider.overrideWithValue(service),
            ownerEquipmentProvider.overrideWith(OwnerEquipmentNotifier.new),
            ownerEquipmentDetailsProvider.overrideWith(
              OwnerEquipmentDetailsNotifier.new,
            ),
            equipmentMutationProvider.overrideWith(
              (ref) => EquipmentMutationNotifier(api: service, ref: ref),
            ),
            ownerFleetGroupsProvider.overrideWith(
              (ref) async =>
                  (await service.getOwnerCatalogGroups()).data
                      ?.map((g) => CatalogGroup.fromApi(g))
                      .toList() ??
                  [],
            ),
            ownerEquipmentCatalogGroupProvider.overrideWith(
              (ref, id) => ref
                  .watch(ownerEquipmentDetailsProvider(id))
                  .valueOrNull
                  ?.category
                  ?.catalogGroup,
            ),
          ],
          child: _CompanyNavigation(
            companyId: companyId,
            companyName: company['name'],
          ),
        );
      },
    );
  }
}

class _CompanyNavigation extends StatefulWidget {
  final String companyId, companyName;
  const _CompanyNavigation({
    required this.companyId,
    required this.companyName,
  });
  @override
  State<_CompanyNavigation> createState() => _CompanyNavigationState();
}

class _CompanyNavigationState extends State<_CompanyNavigation> {
  final navigator = GlobalKey<NavigatorState>();
  int index = 0;
  Widget page(int i) => i == 0
      ? CompanyProfileScreen(
          companyId: widget.companyId,
          companyName: widget.companyName,
        )
      : CompanyParkScreen(companyId: widget.companyId);
  @override
  Widget build(BuildContext context) => Scaffold(
    body: NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => navigator.currentState!.pop(),
      child: Navigator(
        key: navigator,
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => page(0)),
      ),
    ),
    bottomNavigationBar: AppNavigationBar(
      tone: AppNavigationBarTone.company,
      currentIndex: index,
      items: const [
        AppNavigationBarItem(icon: LucideIcons.user2400, label: 'Профиль'),
        AppNavigationBarItem(icon: LucideIcons.warehouse400, label: 'Парк'),
        AppNavigationBarItem(icon: LucideIcons.radar400, label: 'Запросы'),
        AppNavigationBarItem(icon: LucideIcons.scrollText400, label: 'Заказы'),
        AppNavigationBarItem(icon: LucideIcons.messageCircle400, label: 'Чаты'),
      ],
      onItemTap: (next) {
        if (next > 1) {
          AppToast.show(
            message: 'Этот раздел компании будет доступен на следующем этапе',
          );
          return;
        }
        navigator.currentState!.popUntil((route) => route.isFirst);
        navigator.currentState!.pushReplacement(
          MaterialPageRoute(builder: (_) => page(next)),
        );
        setState(() => index = next);
      },
    ),
  );
}

class CompanyEquipmentDetailsPage extends StatelessWidget {
  final String id;
  const CompanyEquipmentDetailsPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ProkatAppBar(
      title: OwnerEquipmentDetailTitle(equipmentId: id),
      onBack: () => Navigator.of(context).pop(),
      actions: const [NotificationBadge()],
    ),
    body: OwnerEquipmentDetailScreen(equipmentId: id),
  );
}
