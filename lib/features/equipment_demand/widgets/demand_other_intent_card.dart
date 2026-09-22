import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

class DemandOtherIntentCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? description;
  final TextEditingController provideController;
  final TextEditingController rentController;

  const DemandOtherIntentCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.description,
    required this.provideController,
    required this.rentController,
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
          0,
          AppDimens.s20$lg,
          0,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.s16$base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppDimens.s20$lg),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? OptimizedNetworkImage(
                        imageUrl: imageUrl,
                        height: 160,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        Icons.agriculture_outlined,
                        size: 100,
                        color: colors.text.secondary,
                      ),
              ),
              const SizedBox(height: AppDimens.s32$xxl),
              Text(
                title,
                style: AppFonts.headingM(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (description != null && description!.trim().isNotEmpty) ...[
                const SizedBox(height: AppDimens.s12$md),
                Text(
                  description!,
                  style: AppFonts.body16(context),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppDimens.s32$xxl),
              AppTextArea(
                title: l10n.demandSurveyOtherProvidePrompt,
                controller: provideController,
                hint: l10n.demandSurveyOtherProvideHint,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: AppDimens.s16$base),
              AppTextArea(
                title: l10n.demandSurveyOtherRentPrompt,
                controller: rentController,
                hint: l10n.demandSurveyOtherRentHint,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
