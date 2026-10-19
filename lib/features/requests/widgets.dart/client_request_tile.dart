import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/state/request_lifetime.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/features/requests/widgets.dart/request_status_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientRequestTile extends ConsumerStatefulWidget {
  final RequestModel request;

  /// Pending offers already loaded by the surrounding request card.
  final int? offerCount;

  const ClientRequestTile({super.key, required this.request, this.offerCount});

  @override
  ConsumerState<ClientRequestTile> createState() => _ClientRequestTileState();
}

class _ClientRequestTileState extends ConsumerState<ClientRequestTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final request = widget.request;
    final id = request.id;
    final flow = ProkatFlowScope.maybeOf(context);
    if (flow != null) return _buildFlow(context, flow, l10n);

    return Container(
      decoration: BoxDecoration(color: theme.cardColor),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Tile
              SizedBox(
                width: 110,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: OptimizedNetworkImage(
                      imageUrl: request.category?.imageUrl ?? "",
                      fit: BoxFit.contain,
                      fallbackIcon: Icons.image,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.category?.name.toUpperCase() ?? "",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (hasVisibleRequestCapacity(request.capacity))
                      Text(
                        request.capacity,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),

              RequestStatusBadge(
                status: request.status,
                mode: AppMode.clientMode,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InfoTile(
                  label: l10n.location,
                  value:
                      request.location?.streetLine(
                        Localizations.localeOf(context).languageCode,
                      ) ??
                      l10n.unknownLocation,
                  onTap: () {
                    final location = request.location;
                    if (location == null) return;

                    showLocationSheet(context, location);
                  },
                  icon: Icons.map_outlined,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: InfoTile(
                  icon: Icons.timelapse,
                  label: l10n.dateAndTime,
                  value: formatDateTime(
                    request.requiredOn,
                    request.requiredAt,
                    locale: l10n.localeName,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (request.comment != null && request.comment!.isNotEmpty)
            InfoTile(label: l10n.comments, value: request.comment!),

          Row(
            children: [
              // Offered Rate and Comment
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.offeredRate, style: theme.textTheme.labelSmall),
                  Text(
                    formatRequestOfferedPrice(
                      request.offeredPrice,
                      waitOwnerLabel: l10n.requestWaitOwnerPrice,
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              if (ref
                  .watch(requestMutationProvider)
                  .isActionActive("request:$id:cancel"))
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
              else
                AppIconButton(
                  onTap: () => unawaited(
                    _showCancelConfirmation(context, ref, request.id, l10n),
                  ),
                  icon: LucideIcons.x,
                  tone: AppIconButtonTone.destructive,
                ),

              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlow(
    BuildContext context,
    ProkatFlowPalette palette,
    AppLocalizations l10n,
  ) {
    final request = widget.request;
    final language = Localizations.localeOf(context).languageCode;
    final categoryName = request.category?.localizedName(language).trim() ?? '';
    final street = request.location?.streetLine(language).trim() ?? '';
    final address = street.isEmpty ? l10n.unknownLocation : street;
    final date = request.requiredOn == null
        ? l10n.dateNotSet
        : formatDateTime(
            request.requiredOn,
            request.requiredAt,
            locale: l10n.localeName,
          );
    final isOpen = isActiveRequestStatus(request.status);
    final cancelling =
        isOpen &&
        ref
            .watch(requestMutationProvider)
            .isActionActive('request:${request.id}:cancel');
    final remaining = requestLifetimeRemaining(request.createdAt);
    final showRemaining =
        isOpen && request.createdAt != null && remaining > Duration.zero;
    final lifetimeLabel = remaining >= const Duration(hours: 1)
        ? l10n.hoursLeft(requestLifetimeHoursLeft(remaining))
        : l10n.minutesLeft(requestLifetimeMinutesLeft(remaining));
    final price = formatRequestOfferedPrice(
      request.offeredPrice,
      waitOwnerLabel: l10n.requestWaitOwnerPrice,
    );
    final priceUnit = request.offeredPrice > 0
        ? getPriceRate(request.offeredPriceRate, l10n: l10n)
        : '';
    final hasPendingOffers = (widget.offerCount ?? 0) > 0;
    final showStatus =
        request.status != RequestStatus.responded || !hasPendingOffers;
    final budget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          request.offeredPrice > 0
              ? l10n.requestClientBudget
              : l10n.offeredRate,
          style: AppFonts.caption(context)
              .copyWith(color: palette.secondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: price,
            children: [
              if (priceUnit.isNotEmpty)
                TextSpan(
                  text: ' $priceUnit',
                  style: AppFonts.body14SemiBold(context)
                      .copyWith(color: palette.secondary, fontSize: 13),
                ),
            ],
          ),
          style: AppFonts.headingM(context).copyWith(
            color: request.offeredPrice > 0 ? palette.primary : palette.title,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showRemaining) ...[
          Icon(LucideIcons.clock, size: 14, color: palette.secondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              lifetimeLabel,
              style: AppFonts.caption(context)
                  .copyWith(color: palette.secondary, fontSize: 12),
            ),
          ),
        ],
        if (isOpen)
          AppIconButton(
            tooltip: l10n.cancelRequestAction,
            icon: LucideIcons.x,
            tone: AppIconButtonTone.destructive,
            isLoading: cancelling,
            onTap: cancelling
                ? null
                : () => unawaited(
                    _showCancelConfirmation(context, ref, request.id, l10n),
                  ),
          ),
      ],
    );

    final locationChip = _RequestMetaValue(
      label: l10n.location,
      value: address,
      icon: LucideIcons.mapPin,
      palette: palette,
      onTap: request.location == null
          ? null
          : () => showLocationSheet(context, request.location!),
    );
    final dateChip = _RequestMetaValue(
      label: l10n.dateAndTime,
      value: date,
      icon: LucideIcons.calendarDays,
      palette: palette,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.title.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: OptimizedNetworkImage(
                  imageUrl: request.category?.imageUrl,
                  width: 72,
                  height: 54,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.category_outlined,
                  backgroundColor: palette.background,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName.isEmpty ? l10n.requestStatus : categoryName,
                      style: AppFonts.headingS(context).copyWith(
                        color: palette.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hasVisibleRequestCapacity(request.capacity)) ...[
                      const SizedBox(height: 4),
                      Text(
                        request.capacity.trim(),
                        style: AppFonts.body14SemiBold(context)
                            .copyWith(color: palette.secondary, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        if (showStatus)
                          _summaryBadge(
                            context,
                            request.status == RequestStatus.viewed
                                ? l10n.offerStatusViewed
                                : getRequestStatus(request.status, l10n: l10n),
                            request.status == RequestStatus.accepted
                                ? palette.success
                                : palette.secondary,
                            palette.background,
                          ),
                        if (widget.offerCount != null)
                          _summaryBadge(
                            context,
                            l10n.offerCount(widget.offerCount!),
                            hasPendingOffers ? Colors.white : palette.primary,
                            hasPendingOffers
                                ? palette.filledPrimary
                                : palette.primarySoft,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [locationChip, const SizedBox(height: 8), dateChip],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: locationChip),
                  const SizedBox(width: 8),
                  Expanded(child: dateChip),
                ],
              );
            },
          ),
          if (request.comment?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              request.comment!.trim(),
              style: AppFonts.body14(
                context,
              ).copyWith(color: palette.secondary, fontSize: 13, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (!showRemaining && !isOpen) return budget;
              final stacked =
                  constraints.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    budget,
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerRight, child: controls),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: budget),
                  const SizedBox(width: 8),
                  controls,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryBadge(
    BuildContext context,
    String title,
    Color foreground,
    Color background,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      title,
      style: AppFonts.captionMedium(
        context,
      ).copyWith(color: foreground, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

class _RequestMetaValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ProkatFlowPalette palette;
  final VoidCallback? onTap;

  const _RequestMetaValue({
    required this.label,
    required this.value,
    required this.icon,
    required this.palette,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: onTap != null,
    child: Material(
      color: palette.background,
      borderRadius: BorderRadius.circular(13),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: palette.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body14SemiBold(
                    context,
                  ).copyWith(color: palette.title, fontSize: 13, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showCancelConfirmation(
  BuildContext context,
  WidgetRef ref,
  String requestId,
  AppLocalizations l10n,
) async {
  final confirmed = await AppAlertBottomSheet.show(
    context,
    title: l10n.cancelRequest,
    description: l10n.cancelRequestContent,
    primaryLabel: l10n.yesCancel,
    secondaryLabel: l10n.no,
    isDestructivePrimary: true,
  );

  if (confirmed != true) return;

  final result = await ref
      .read(requestMutationProvider.notifier)
      .cancelRequest(requestId);

  AppToast.show(
    message: result.success
        ? l10n.requestCancelled
        : l10n.failedToCancelRequest,
    type: result.success ? AppToastType.success : AppToastType.error,
  );
}
