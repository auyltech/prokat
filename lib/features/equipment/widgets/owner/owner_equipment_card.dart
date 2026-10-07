import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/utils/equipment_submit_readiness.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_status_badge.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_image_header.dart';
import 'package:prokat/features/equipment/widgets/online_toggle.dart';
import 'package:prokat/features/equipment_share/equipment_share_gate.dart';
import 'package:prokat/features/equipment_share/widgets/share_equipment_button.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerEquipmentCard extends ConsumerWidget {
  final Equipment equipment;
  final VoidCallback? onOpen;
  final bool showShare;
  final bool companyControls;
  final bool readOnly;

  const OwnerEquipmentCard({
    super.key,
    required this.equipment,
    this.onOpen,
    this.showShare = true,
    this.companyControls = false,
    this.readOnly = false,
  });

  void _openEditor(BuildContext context, WidgetRef ref) {
    if (onOpen != null) {
      onOpen!();
      return;
    }
    ref
        .read(equipmentMutationProvider.notifier)
        .selectEditEquipment(equipment.id);
    unawaited(context.push('${AppRoutes.ownerEquipment}/${equipment.id}'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (equipment.status == EquipmentStatus.draft) {
      return _DraftOwnerEquipmentCard(
        equipment: equipment,
        onOpen: () => _openEditor(context, ref),
      );
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.5);
    final locationText = readOnly
        ? (equipment.ownerComment ?? '')
        : (equipment.city == null || equipment.city!.isEmpty)
        ? l10n.noLocationSet
        : catalogCityLabelOf(ref, context, equipment.city);
    final priceEntry = equipment.prices
        .where((entry) => entry.price > 0)
        .firstOrNull;

    final hasPrice = priceEntry != null;
    final priceDisplay = hasPrice
        ? "${priceEntry.price} ${getPriceRate(priceEntry.priceRate, l10n: l10n)}"
        : l10n.noPriceSet;

    if (companyControls && !readOnly) {
      final showVisibility =
          equipment.status == EquipmentStatus.available ||
          equipment.status == EquipmentStatus.accepted ||
          equipment.status == EquipmentStatus.booked;
      final showAvailability = equipment.isVisible && equipment.isModerated;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => _openEditor(context, ref),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 80,
                      child: _buildImage(equipment.imageUrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            equipment.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${equipment.model.toUpperCase()} ${equipment.plateNumber != null ? '• ${equipment.plateNumber!.toUpperCase()}' : ''}",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ghostGray,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: ghostGray,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  locationText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: ghostGray,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Tooltip(
                    message: hasPrice
                        ? l10n.hasPricesListed
                        : l10n.noPricesListed,
                    triggerMode: TooltipTriggerMode.tap,
                    child: Icon(
                      hasPrice
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 18,
                      color: hasPrice ? Colors.green : colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      priceDisplay,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: hasPrice ? colorScheme.primary : ghostGray,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  EquipmentStatusBadge(status: equipment.status),
                ],
              ),
              if (showAvailability || showVisibility) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.045),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showAvailability)
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                equipment.status == EquipmentStatus.booked
                                    ? 'Занята'
                                    : 'Свободна',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value:
                                      equipment.status !=
                                      EquipmentStatus.booked,
                                  onChanged: (free) async {
                                    final result = await ref
                                        .read(
                                          equipmentMutationProvider.notifier,
                                        )
                                        .updateEquipmentStatus(
                                          equipment.id,
                                          free
                                              ? EquipmentStatus.available
                                              : EquipmentStatus.booked,
                                        );
                                    if (!result.success) {
                                      AppToast.show(
                                        message: result.message,
                                        type: AppToastType.error,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (showVisibility)
                        Expanded(
                          child: OnlineToggle(
                            id: equipment.id,
                            isVisible: equipment.isVisible,
                            canShow: hasPrice,
                            vertical: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (showShare && canShowShareButton(equipment))
                Align(
                  alignment: Alignment.centerRight,
                  child: ShareEquipmentButton(
                    equipment: equipment,
                    variant: AppIconButtonVariant.filled,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: theme.cardColor),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _openEditor(context, ref),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImage(equipment.imageUrl),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipment.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${equipment.model.toUpperCase()} ${!readOnly && equipment.plateNumber != null ? '• ${equipment.plateNumber!.toUpperCase()}' : ''}",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ghostGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (!readOnly)
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 20,
                                    color: ghostGray,
                                  ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    locationText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: ghostGray,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (readOnly)
                    Text(priceDisplay, style: theme.textTheme.labelMedium)
                  else
                    EquipmentStatusBadge(status: equipment.status),
                  if (showShare && canShowShareButton(equipment)) ...[
                    const SizedBox(height: 8),
                    ShareEquipmentButton(
                      equipment: equipment,
                      variant: AppIconButtonVariant.filled,
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          if (!readOnly)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Tooltip(
                        message: hasPrice
                            ? l10n.hasPricesListed
                            : l10n.noPricesListed,
                        triggerMode: TooltipTriggerMode.tap,
                        child: Icon(
                          hasPrice
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          size: 18,
                          color: hasPrice ? Colors.green : colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          priceDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: hasPrice ? colorScheme.primary : ghostGray,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (equipment.status == EquipmentStatus.available ||
                    equipment.status == EquipmentStatus.accepted ||
                    (companyControls &&
                        equipment.status == EquipmentStatus.booked)) ...[
                  const SizedBox(width: 8),
                  OnlineToggle(
                    id: equipment.id,
                    isVisible: equipment.isVisible,
                    canShow: hasPrice,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: _OwnerCardPhoto(imageUrl: url),
    );
  }
}

class _DraftOwnerEquipmentCard extends ConsumerWidget {
  final Equipment equipment;
  final VoidCallback onOpen;

  const _DraftOwnerEquipmentCard({
    required this.equipment,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.62);
    final plate = (equipment.plateNumber ?? '').trim();
    final subtitle = plate.isEmpty
        ? equipment.model
        : '${equipment.model} • $plate';
    final filled = filledOwnerEquipmentSections(equipment);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _OwnerCardPhoto(imageUrl: equipment.imageUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            equipment.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        EquipmentStatusBadge(status: equipment.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.draftSectionsFilled(
                        filled,
                        ownerEquipmentSectionCount,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerCardPhoto extends StatelessWidget {
  final String? imageUrl;

  const _OwnerCardPhoto({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return const OwnerEquipmentPhotoPlaceholder(
        width: 120,
        height: 80,
        compact: true,
      );
    }

    return OptimizedNetworkImage(
      imageUrl: url,
      width: 120,
      height: 80,
      fit: BoxFit.cover,
    );
  }
}
