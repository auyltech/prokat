import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class LocationTile extends ConsumerWidget {
  const LocationTile({
    super.key,
    required this.location,
    required this.onTap,
    this.onDelete,
    this.isDeleting = false,
  });

  final LocationModel location;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final radius = BorderRadius.circular(AppDimens.r16$xl);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.s08$sm),
      child: Material(
        color: theme.colorScheme.surfaceBright,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: theme.colorScheme.outline.withAlpha(50)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            Icons.location_on_outlined,
            color: theme.colorScheme.onSurface,
            size: AppDimens.iconButtonIconSize,
          ),
          title: Text(
            formatLocationModel(ref, context, location),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppDimens.s12$md,
            0,
            AppDimens.s08$sm,
            0,
          ),
          trailing: isDeleting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : AppIconButton(
                  tooltip: l10n.deleteAddress,
                  onTap: onDelete,
                  icon: Icons.delete_outline,
                  tone: AppIconButtonTone.destructive,
                ),
        ),
      ),
    );
  }
}
