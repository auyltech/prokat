import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/location_tile.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class SelectAddressSheet extends ConsumerWidget {
  final String from;
  final ScrollController scrollController;

  const SelectAddressSheet({
    super.key,
    required this.from,
    required this.scrollController,
  });

  /// [onChooseOnMap] runs only after this sheet route is fully gone.
  /// Callers outside the shell (share booking `/e/:id`) must pass it and open
  /// their own map. Pushing `/client/addresses/map` from that screen stacks a
  /// second shell and the UI stops receiving taps.
  static Future<void> show(
    BuildContext context, {
    required String service,
    required String from,
    String? equipmentId,
    VoidCallback? onChooseOnMap,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final openMap = await AppBottomSheet.showScrollable<bool>(
      context,
      minChildSize: 0.3,
      maxChildSize: 0.4,
      initialChildSize: 0.4,
      title: l10n.selectAddress,
      headerBuilder: (_) => const SizedBox.shrink(),
      scrollableListBuilder: (context, controller) =>
          SelectAddressSheet(from: from, scrollController: controller),
      footerBuilder: (sheetContext) => _SelectAddressFooter(
        service: service,
        from: from,
        equipmentId: equipmentId,
        onChooseOnMap: onChooseOnMap,
      ),
    );

    if (openMap == true) onChooseOnMap?.call();
  }

  Future<void> _confirmDeleteAddress(
    BuildContext context,
    WidgetRef ref,
    String addressId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppAlertBottomSheet.show(
      context,
      title: l10n.deleteAddressQuestion,
      description: l10n.deleteAddressConfirmation,
      primaryLabel: l10n.delete,
      secondaryLabel: l10n.cancel,
      isDestructivePrimary: true,
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await ref
        .read(locationProvider.notifier)
        .deleteLocation(addressId);

    if (!context.mounted) return;

    if (deleted) {
      await ref.read(clientProfileProvider.notifier).refresh();
      return;
    }

    AppToast.show(
      message: l10n.failedToDeleteAddress,
      type: AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final addresses = locationState.clientLocations;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sheetHorizontalPadding,
      ),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        final addressId = address.id;
        final isDeleting =
            addressId != null &&
            locationState.isActionActive('location:$addressId:delete');

        return LocationTile(
          location: address,
          isDeleting: isDeleting,
          onDelete: addressId == null || isDeleting
              ? null
              : () => unawaited(_confirmDeleteAddress(context, ref, addressId)),
          onTap: () {
            ref.read(locationProvider.notifier).selectAddress(address);

            if (from == 'profile' && (addressId ?? '').isNotEmpty) {
              unawaited(
                ref
                    .read(clientProfileMutationProvider.notifier)
                    .selectAddress(addressId!),
              );
            }

            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _SelectAddressFooter extends StatelessWidget {
  final String service;
  final String from;
  final String? equipmentId;
  final VoidCallback? onChooseOnMap;

  const _SelectAddressFooter({
    required this.service,
    required this.from,
    this.equipmentId,
    this.onChooseOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.sheetHorizontalPadding,
        AppDimens.s08$sm,
        AppDimens.sheetHorizontalPadding,
        AppDimens.sheetBottomPadding + bottomInset,
      ),
      child: AppOutlinedButton(
        title: l10n.chooseOnMap,
        prefix: const Icon(Icons.map_outlined),
        onTap: () {
          if (onChooseOnMap != null) {
            Navigator.of(context).pop(true);
            return;
          }

          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          unawaited(
            router.push(
              AppRoutes.clientPinAddress,
              extra: {
                'equipmentId': equipmentId,
                'service': service,
                'from': from,
              },
            ),
          );
        },
      ),
    );
  }
}
