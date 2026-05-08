import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import '../widgets/address_list_tile.dart';
import '../widgets/address_empty_state.dart';
import 'package:go_router/go_router.dart';

class OwnerAddressesScreen extends ConsumerWidget {
  const OwnerAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Equipment Locations")),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.ownerLocations.isEmpty
          ? const AddressEmptyState()
          : ListView.builder(
              itemCount: state.ownerLocations.length,
              itemBuilder: (context, index) {
                final location = state.ownerLocations[index];

                return AddressListTile(location: location);
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          context.push(AppRoutes.ownerAddressCreate);
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (_) => const OwnerAddressCreateScreen()),
          // );
        },
      ),
    );
  }
}
