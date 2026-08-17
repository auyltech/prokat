import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/widgets/owner_status_tile.dart';

class OwnerBusinessPreferencesSection extends ConsumerStatefulWidget {
  const OwnerBusinessPreferencesSection({super.key});

  @override
  ConsumerState<OwnerBusinessPreferencesSection> createState() =>
      _OwnerBusinessPreferencesSectionState();
}

class _OwnerBusinessPreferencesSectionState
    extends ConsumerState<OwnerBusinessPreferencesSection> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_loadBusinessData);
  }

  Future<void> _loadBusinessData() async {
    await ref.read(ownerProfileProvider.notifier).refreshIfStale();

    if (ref.read(locationProvider).ownerLocations.isEmpty) {
      await ref.read(locationProvider.notifier).getOwnerLocations();
    }

    if (ref.read(ownerEquipmentProvider).value == null) {
      await ref.read(ownerEquipmentProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(ownerProfileProvider).valueOrNull;

    final equipmentCount =
        ref.watch(ownerEquipmentProvider).value?.items.length ?? 0;

    final accent = AppColors.teal800;
    final accentBackground = accent.withValues(alpha: 0.15);

    final equipmentText = equipmentCount == 0
        ? 'No equipment added'
        : '$equipmentCount '
              '${equipmentCount == 1 ? 'item' : 'items'} in your fleet';

    final businessName = (profile?.companyName ?? '').trim().isNotEmpty
        ? profile!.companyName!.trim()
        : profile?.ownerType == OwnerType.organization
        ? 'Organization'
        : 'Individual owner';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business preferences',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 16),

        const OwnerStatusTile(),

        const SizedBox(height: 20),

        ProkatListTile(
          icon: LucideIcons.briefcase,
          iconColor: accent,
          iconBgColor: accentBackground,
          title: 'Business profile',
          subtitle: businessName,
          onTap: () => context.push(AppRoutes.ownerRegistration),
        ),

        const SizedBox(height: 20),

        ProkatListTile(
          icon: LucideIcons.truck,
          iconColor: accent,
          iconBgColor: accentBackground,
          title: 'Manage my equipment',
          subtitle: equipmentText,
          onTap: () => context.push(AppRoutes.ownerEquipment),
        ),
      ],
    );
  }
}
