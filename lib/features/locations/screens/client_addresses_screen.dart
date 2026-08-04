import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';

class ClientAddressesScreen extends ConsumerStatefulWidget {
  const ClientAddressesScreen({super.key});

  @override
  ConsumerState<ClientAddressesScreen> createState() =>
      _ClientAddressesScreenState();
}

class _ClientAddressesScreenState extends ConsumerState<ClientAddressesScreen> {
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
  void initState() {
    super.initState();

    Future.microtask(_loadAddresses);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final locationState = ref.watch(locationProvider);
    final addresses = locationState.clientLocations;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          Navigator.pop(context);
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
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    final addressId = address.id;
                    final isSelected =
                        locationState.selectedAddress?.id == addressId;
                    final isSaving = ref.watch(locationProvider).isSubmitting;

                    return ListTile(
                      enabled: addressId != null,
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
                      subtitle: (address.instructions ?? '').trim().isNotEmpty
                          ? Text(address.instructions!)
                          : null,
                      trailing: isSaving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: addressId == null
                          ? null
                          : () async {
                              final saved = await ref
                                  .read(clientProfileMutationProvider.notifier)
                                  .selectAddress(addressId);

                              if (!context.mounted) return;

                              if (saved) {
                                ref
                                    .read(locationProvider.notifier)
                                    .selectAddress(address);

                                Navigator.pop(context);
                              } else {
                                AppSnackBar.show(
                                  message:
                                      'Failed to save the selected address.',
                                  isError: true,
                                );
                              }
                            },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AddressPrivacy extends StatelessWidget {
  const AddressPrivacy({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Extract the theme directly inside the build method
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Address privacy',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Your selected address is shared only with the equipment '
            'owner during an active order when it is needed to fulfil '
            'the rental. It is not displayed publicly or shared with '
            'other users.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => context.push(AppRoutes.contactSupport),
            child: const Text('More privacy options? Contact support'),
          ),
        ],
      ),
    );
  }
}
