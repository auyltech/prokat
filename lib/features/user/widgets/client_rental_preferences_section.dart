import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';

class ClientRentalPreferencesSection extends ConsumerStatefulWidget {
  const ClientRentalPreferencesSection({super.key});

  @override
  ConsumerState<ClientRentalPreferencesSection> createState() =>
      _ClientRentalPreferencesSectionState();
}

class _ClientRentalPreferencesSectionState
    extends ConsumerState<ClientRentalPreferencesSection> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_loadAddresses);
  }

  Future<void> _loadAddresses() async {
    await ref.read(locationProvider.notifier).getClientLocations();

    final selectedAddressId = ref
        .read(clientProfileProvider)
        .userProfile
        ?.selectedAddressId;

    if ((selectedAddressId ?? '').isNotEmpty) {
      ref.read(locationProvider.notifier).selectAddressById(selectedAddressId);
    }
  }

  String _formatAddress(LocationModel? address) {
    if (address == null) return 'No address selected';

    return [
      address.street,
      address.city,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationState = ref.watch(locationProvider);
    final selectedAddress = locationState.selectedAddress;
    final selectedCategory = ref.watch(categoriesProvider).selectedCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(selectedAddress?.city ?? ""),

        const SizedBox(height: 16),

        ProkatListTile.secondary(
          icon: LucideIcons.building,
          iconColor: theme.colorScheme.onSurface,
          iconBgColor: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          title: 'City',
          subtitle:
              ref.watch(clientProfileProvider).userProfile?.city ??
              "Select City",
          onTap: () => CityPickerSheet.show(
            context: context,
            service: CitySelectorService.clientcity,
          ),
        ),

        const SizedBox(height: 12),

        ProkatListTile.secondary(
          icon: LucideIcons.hammer,
          iconColor: theme.colorScheme.onSurface,
          iconBgColor: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          title: 'Service',
          subtitle: selectedCategory?.name ?? "Select Service",
          onTap: () => CategorySelectionSheet.show(
            context,
            service: CategorySheetMode.selectCategory,
          ),
        ),

        const SizedBox(height: 12),

        ProkatListTile.secondary(
          icon: LucideIcons.mapPin,
          iconColor: theme.colorScheme.onSurface,
          iconBgColor: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          title: 'Selected address',
          subtitle: _formatAddress(selectedAddress),
          onTap: () => SelectAddressSheet.show(
            context,
            service: "select_primary",
            from: "profile",
          ),
        ),

        // const SizedBox(height: 12),

        // ProkatListTile(
        //   icon: Icons.edit_location_alt_outlined,
        //   iconColor: Colors.black,
        //   iconBgColor: Colors.black12,
        //   title: 'Manage my addresses',
        //   subtitle: 'Add, edit or delete saved addresses',
        //   onTap: () => context.push(AppRoutes.clientAddresses),
        // ),
      ],
    );
  }
}
