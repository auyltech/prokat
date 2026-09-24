import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/widgets/equipment_image_header.dart';
import 'package:prokat/features/bookings/widgets/service_tariff_block.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/public_equipment_provider.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/l10n/app_localizations.dart';

class GuestCreateBookingScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const GuestCreateBookingScreen({super.key, required this.equipmentId});

  @override
  ConsumerState<GuestCreateBookingScreen> createState() =>
      _GuestCreateBookingScreenState();
}

class _GuestCreateBookingScreenState
    extends ConsumerState<GuestCreateBookingScreen> {
  String? _selectedPriceId;

  void _openCatalog() {
    final session = ref.read(authProvider).session;
    context.go(session == null ? AppRoutes.main : AppRoutes.searchList);
  }

  void _book(Equipment equipment) {
    if (ref.read(authProvider).session != null) return;
    final from = Uri.encodeComponent(
      AppRoutes.equipmentSharePath(equipment.id),
    );
    context.go('${AppRoutes.login}?from=$from');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final equipment = ref.watch(publicEquipmentProvider(widget.equipmentId));

    return Scaffold(
      body: SafeArea(
        child: equipment.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Unavailable(
            title: error is PublicEquipmentException && error.statusCode == 404
                ? l10n.shareEquipmentUnavailable
                : l10n.somethingWentWrongTryAgain,
            actionLabel: l10n.shareEquipmentOpenCatalog,
            onCatalog: _openCatalog,
          ),
          data: (item) => _Card(
            equipment: item,
            selectedPriceId: _selectedPriceId,
            onSelectPrice: (id) => setState(() => _selectedPriceId = id),
            onBook: () => _book(item),
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onCatalog;

  const _Unavailable({
    required this.title,
    required this.actionLabel,
    required this.onCatalog,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EmptyStateTile(
          imageName: 'empty_equipment.png',
          title: title,
          actionButton: AppElevatedButton(title: actionLabel, onTap: onCatalog),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Equipment equipment;
  final String? selectedPriceId;
  final ValueChanged<String> onSelectPrice;
  final VoidCallback onBook;

  const _Card({
    required this.equipment,
    required this.selectedPriceId,
    required this.onSelectPrice,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final description = shortDescriptionOf(equipment);
    final prices = equipment.prices.where((entry) => entry.price > 0).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        EquipmentImageHeader(imageUrls: equipment.displayImageUrls),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                equipment.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
              if (prices.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...prices.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ServiceTariffBlock(
                      entry: entry,
                      selected: selectedPriceId == entry.id,
                      onTap: () => onSelectPrice(entry.id),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              AppElevatedButton(title: l10n.reserveNow, onTap: onBook),
            ],
          ),
        ),
      ],
    );
  }
}
