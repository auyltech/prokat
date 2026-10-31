import 'request_comment_panel.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/state/request_lifetime.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Presentation only. The tile retains offer, visibility and online guards.
class OwnerRequestFlowCard extends StatelessWidget {
  final RequestModel request;
  final OwnerRequestState requestState;
  final String lifetimeLabel;
  final Widget clientSummary;
  final Widget moreAction;
  final bool hasActiveOffer;
  final VoidCallback? onLocation;
  final VoidCallback onHide;
  final VoidCallback onSend;
  final VoidCallback onChat;
  final VoidCallback onViewOffer;

  const OwnerRequestFlowCard({
    super.key,
    required this.request,
    required this.requestState,
    required this.lifetimeLabel,
    required this.clientSummary,
    required this.moreAction,
    required this.hasActiveOffer,
    this.onLocation,
    required this.onHide,
    required this.onSend,
    required this.onChat,
    required this.onViewOffer,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final category = request.category?.name.trim() ?? '';
    final address =
        request.location?.streetLine(l10n.localeName) ?? l10n.unknownLocation;
    final unit = request.offeredPrice > 0 && request.offeredPriceRate != null
        ? getPriceRate(request.offeredPriceRate, l10n: l10n)
        : '';
    final budget = formatRequestOfferedPrice(
      request.offeredPrice,
      waitOwnerLabel: l10n.requestWaitOwnerPrice,
    );
    final stateColor = switch (requestState) {
      OwnerRequestState.newRequest ||
      OwnerRequestState.accepted => palette.success,
      OwnerRequestState.offerSent => palette.primary,
      _ => palette.secondary,
    };
    final location = _RequestMeta(
      label: l10n.location,
      value: address,
      icon: LucideIcons.mapPin,
      onTap: onLocation,
      palette: palette,
    );
    final schedule = _RequestMeta(
      label: l10n.dateAndTime,
      value: formatDateTime(
        request.requiredOn,
        request.requiredAt,
        locale: l10n.localeName,
      ),
      icon: LucideIcons.calendarDays,
      palette: palette,
    );
    return Container(
      padding: const EdgeInsets.all(AppDimens.s16$base),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppDimens.r20$xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.r12$lg),
                child: OptimizedNetworkImage(
                  imageUrl: request.category?.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  fallbackIcon: LucideIcons.image,
                  backgroundColor: palette.background,
                ),
              ),
              const SizedBox(width: AppDimens.s12$md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.isEmpty ? l10n.requestStatus : category,
                      style: AppFonts.headingS(context)
                          .copyWith(color: palette.title),
                    ),
                    if (hasVisibleRequestCapacity(request.capacity)) ...[
                      const SizedBox(height: AppDimens.s04$xs),
                      Text(
                        request.capacity,
                        style: AppFonts.body14SemiBold(context)
                            .copyWith(color: palette.secondary),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        getOwnerRequestStatus(requestState, l10n: l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body14SemiBold(context)
                            .copyWith(color: stateColor, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: palette.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lifetimeLabel,
                            style: AppFonts.caption(
                              context,
                            ).copyWith(color: palette.secondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.s12$md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: clientSummary),
              const SizedBox(width: AppDimens.s04$xs),
              moreAction,
            ],
          ),
          const SizedBox(height: AppDimens.s12$md),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    location,
                    const SizedBox(height: AppDimens.s08$sm),
                    schedule,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: location),
                  const SizedBox(width: AppDimens.s08$sm),
                  Expanded(child: schedule),
                ],
              );
            },
          ),
          if (request.comment?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            RequestCommentPanel(comment: request.comment!),
          ],
          const SizedBox(height: AppDimens.s16$base),
          Text(
            l10n.offeredRate,
            style: AppFonts.caption(context)
                .copyWith(color: palette.secondary, fontSize: 12),
          ),
          const SizedBox(height: AppDimens.s04$xs),
          Text(
            '$budget${unit.isEmpty ? '' : ' $unit'}',
            key: const ValueKey('owner-request-budget'),
            style: AppFonts.headingM(context).copyWith(color: palette.title),
          ),
          const SizedBox(height: AppDimens.s12$md),
          if (hasActiveOffer)
            Row(
              children: [
                ProkatFlowIconButton(
                  icon: LucideIcons.messageCircle,
                  label: l10n.navChats,
                  onPressed: onChat,
                ),
                const SizedBox(width: AppDimens.s08$sm),
                Expanded(
                  child: ProkatFlowPrimaryButton(
                    title: l10n.viewOffer,
                    onPressed: onViewOffer,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ProkatFlowPrimaryButton(
                    title: l10n.sendOffer,
                    onPressed: onSend,
                  ),
                ),
                const SizedBox(width: AppDimens.s08$sm),
                ProkatFlowIconButton(
                  icon: LucideIcons.x,
                  label: l10n.hideRequest,
                  onPressed: onHide,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RequestMeta extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final ProkatFlowPalette palette;
  const _RequestMeta({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: palette.background,
    borderRadius: BorderRadius.circular(AppDimens.r12$lg),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.s12$md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: palette.primary),
            const SizedBox(width: AppDimens.s08$sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppFonts.caption(context)
                        .copyWith(color: palette.secondary, fontSize: 11),
                  ),
                  const SizedBox(height: AppDimens.s04$xs),
                  Text(
                    value,
                    style: AppFonts.body14SemiBold(context)
                        .copyWith(color: palette.title),
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
