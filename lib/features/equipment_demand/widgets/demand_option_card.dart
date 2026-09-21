import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

class DemandOptionCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const DemandOptionCard({
    super.key,
    required this.title,
    this.description,
    this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = selected ? colors.primary : colors.borders.main;

    return Material(
      color: colors.background.elevated,
      borderRadius: BorderRadius.circular(AppDimens.r16$xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.r16$xl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.r16$xl),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          padding: const EdgeInsets.all(AppDimens.s16$base),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? OptimizedNetworkImage(
                        imageUrl: imageUrl,
                        height: 64,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        Icons.agriculture_outlined,
                        size: 40,
                        color: colors.text.secondary,
                      ),
              ),
              const SizedBox(width: AppDimens.s12$md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.body16SemiBold(context).copyWith(
                        color: selected ? colors.primary : null,
                      ),
                    ),
                    if (description != null &&
                        description!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppDimens.s04$xs),
                      Text(
                        description!,
                        style: AppFonts.caption(context).copyWith(height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.s08$sm),
              AppCheckbox(
                value: selected,
                absorbPointer: true,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
