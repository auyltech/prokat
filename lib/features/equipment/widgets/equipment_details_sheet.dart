import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Bottom sheet with full vehicle specifications.
class EquipmentDetailsSheet extends StatelessWidget {
  final String? name;
  final String? model;
  final String? plateNumber;
  final String? imageUrl;
  final List<String>? specifications;

  const EquipmentDetailsSheet({
    super.key,
    this.name,
    this.model,
    this.plateNumber,
    this.imageUrl,
    this.specifications,
  });

  static void show(
    BuildContext context, {
    required String? name,
    required String? model,
    required String? plateNumber,
    required String? imageUrl,
    List<String>? specifications,
  }) {
    final theme = Theme.of(context);

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => EquipmentDetailsSheet(
          name: name,
          model: model,
          plateNumber: plateNumber,
          imageUrl: imageUrl,
          specifications: specifications,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          top: 12,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              l10n.equipmentDetails,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            if (imageUrl != null && imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: OptimizedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],

            _buildSpecRow(context, l10n.vehicleName, name ?? '—'),
            Divider(
              height: 24,
              thickness: 0.5,
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
            _buildSpecRow(context, l10n.modelType, model ?? '—'),
            Divider(
              height: 24,
              thickness: 0.5,
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
            _buildSpecRow(context, l10n.plateNumberLabel, plateNumber ?? '—'),

            if (specifications != null && specifications!.isNotEmpty) ...[
              Divider(
                height: 24,
                thickness: 0.5,
                color: theme.dividerColor.withValues(alpha: 0.6),
              ),
              _buildSpecRow(
                context,
                l10n.technicalSpecs,
                specifications!.join(' • '),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
