import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_models.dart';
import 'package:prokat/l10n/app_localizations.dart';

class DemandIntentCard extends StatelessWidget {
  final DemandOption option;
  final DemandOptionIntent intent;
  final ValueChanged<DemandOptionIntent> onChanged;

  const DemandIntentCard({
    super.key,
    required this.option,
    required this.intent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: colors.background.elevated,
      borderRadius: BorderRadius.circular(AppDimens.r16$xl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.r16$xl),
          border: Border.all(color: colors.borders.main),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.s20$lg,
          AppDimens.s16$base,
          AppDimens.s20$lg,
          AppDimens.s16$base,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 1),
            SizedBox(
              height: 160,
              width: double.infinity,
              child: option.imageUrl != null && option.imageUrl!.isNotEmpty
                  ? OptimizedNetworkImage(
                      imageUrl: option.imageUrl,
                      height: 160,
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      Icons.agriculture_outlined,
                      size: 100,
                      color: colors.text.secondary,
                    ),
            ),
            const Spacer(flex: 1),
            Text(
              option.name,
              style: AppFonts.headingM(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (option.description != null &&
                option.description!.trim().isNotEmpty) ...[
              const SizedBox(height: AppDimens.s12$md),
              Text(
                option.description!,
                style: AppFonts.body16(context),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(flex: 3),
            Text(
              l10n.demandSurveyWantAbility,
              style: AppFonts.headingS(context),
            ),
            const SizedBox(height: AppDimens.s12$md),
            AppCheckboxTile(
              value: intent.provide,
              title: l10n.demandSurveyProvide,
              onChanged: (value) => onChanged(intent.copyWith(provide: value)),
            ),
            const SizedBox(height: AppDimens.s08$sm),
            AppCheckboxTile(
              value: intent.rent,
              title: l10n.demandSurveyRent,
              onChanged: (value) => onChanged(intent.copyWith(rent: value)),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
