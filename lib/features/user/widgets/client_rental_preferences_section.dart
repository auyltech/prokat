import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
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
        .read(userProfileProvider)
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

  Future<void> _showAddressPicker() async {
    if (ref.read(locationProvider).clientLocations.isEmpty) {
      await ref.read(locationProvider.notifier).getClientLocations();
    }

    if (!mounted) return;

    String? savingAddressId;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Consumer(
              builder: (context, sheetRef, _) {
                final theme = Theme.of(context);
                final locationState = sheetRef.watch(locationProvider);
                final addresses = locationState.clientLocations;

                return SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.7,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Select address',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose the default address used when creating a rental.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),

                          if (locationState.isFetching)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (addresses.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.location_off_outlined,
                                      size: 40,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('You have no saved addresses.'),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        context.push(AppRoutes.clientAddresses);
                                      },
                                      icon: const Icon(Icons.add_location_alt),
                                      label: const Text('Add address'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: addresses.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final address = addresses[index];
                                  final addressId = address.id;
                                  final isSelected =
                                      locationState.selectedAddress?.id ==
                                      addressId;
                                  final isSaving = savingAddressId == addressId;

                                  return ListTile(
                                    enabled:
                                        addressId != null &&
                                        savingAddressId == null,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.location_on_outlined,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(_formatAddress(address)),
                                    subtitle:
                                        (address.instructions ?? '')
                                            .trim()
                                            .isNotEmpty
                                        ? Text(address.instructions!)
                                        : null,
                                    trailing: isSaving
                                        ? const SizedBox.square(
                                            dimension: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.chevron_right_rounded,
                                          ),
                                    onTap: addressId == null
                                        ? null
                                        : () async {
                                            setSheetState(() {
                                              savingAddressId = addressId;
                                            });

                                            final saved = await sheetRef
                                                .read(
                                                  userProfileProvider.notifier,
                                                )
                                                .selectAddress(addressId);

                                            if (!sheetContext.mounted) return;

                                            if (saved) {
                                              sheetRef
                                                  .read(
                                                    locationProvider.notifier,
                                                  )
                                                  .selectAddress(address);

                                              Navigator.pop(sheetContext);
                                            } else {
                                              setSheetState(() {
                                                savingAddressId = null;
                                              });

                                              ScaffoldMessenger.of(
                                                sheetContext,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Failed to save the selected address.',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                  );
                                },
                              ),
                            ),

                          if (addresses.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: savingAddressId != null
                                    ? null
                                    : () {
                                        Navigator.pop(sheetContext);
                                        context.push(AppRoutes.clientAddresses);
                                      },
                                icon: const Icon(Icons.edit_location_alt),
                                label: const Text('Manage my addresses'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final selectedAddress = locationState.selectedAddress;
    final selectedCategory = ref.watch(categoriesProvider).selectedCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProkatListTile(
          icon: Icons.location_city_outlined,
          iconColor: Colors.black,
          iconBgColor: Colors.black12,
          title: 'City',
          subtitle:
              ref.watch(userProfileProvider).userProfile?.city ?? "Select City",
          onTap: () => CityPickerSheet.show(context: context),
        ),

        const SizedBox(height: 12),
        ProkatListTile(
          icon: LucideIcons.penTool,
          iconColor: Colors.black,
          iconBgColor: Colors.black12,
          title: 'Service',
          subtitle: selectedCategory?.name ?? "Select Service",
          onTap: () {},
        ),

        const SizedBox(height: 12),
        ProkatListTile(
          icon: Icons.location_on_outlined,
          iconColor: Colors.black,
          iconBgColor: Colors.black12,
          title: 'Selected address',
          subtitle: _formatAddress(selectedAddress),
          onTap: _showAddressPicker,
        ),

        const SizedBox(height: 12),

        ProkatListTile(
          icon: Icons.edit_location_alt_outlined,
          iconColor: Colors.black,
          iconBgColor: Colors.black12,
          title: 'Manage my addresses',
          subtitle: 'Add, edit or delete saved addresses',
          onTap: () => context.push(AppRoutes.clientAddresses),
        ),
      ],
    );
  }
}
