import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

class RequiredFieldLabel extends StatelessWidget {
  const RequiredFieldLabel({
    super.key,
    required this.title,
    required this.showRequired,
    this.requiredHint,
  });

  final String title;
  final bool showRequired;

  /// Ignored — required mark matches [AppTextField] (` *`).
  final String? requiredHint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text.rich(
      TextSpan(
        text: title,
        style: AppFonts.headingS(context),
        children: [
          if (showRequired)
            TextSpan(
              text: ' *',
              style: AppFonts.headingS(context)
                  .copyWith(color: colors.text.error),
            ),
        ],
      ),
    );
  }
}

class ChoicePair extends StatelessWidget {
  const ChoicePair({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.rightSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final bool rightSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ChoiceButton(
            label: leftLabel,
            selected: leftSelected,
            onTap: onLeft,
          ),
        ),
        const SizedBox(width: AppDimens.s08$sm),
        Expanded(
          child: ChoiceButton(
            label: rightLabel,
            selected: rightSelected,
            onTap: onRight,
          ),
        ),
      ],
    );
  }
}

class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevated = colors.elevatedButton;
    final field = colors.textField;
    final borderRadius = BorderRadius.circular(AppDimens.r12$lg);

    return Material(
      color: selected ? elevated.background : field.background,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          width: AppDimens.buttonBorderWidth,
          color: selected ? elevated.background : colors.borders.main,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppDimens.inputHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.s08$sm,
              vertical: AppDimens.s08$sm,
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.label(context).copyWith(
                  color: selected ? elevated.content : colors.text.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OutlinePickerField extends StatelessWidget {
  const OutlinePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final field = colors.textField;
    final borderRadius = BorderRadius.circular(AppDimens.r12$lg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.headingS(context)),
        const SizedBox(height: AppDimens.inputLabelGap),
        Material(
          color: field.background,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(
              width: AppDimens.inputBorderWidth,
              color: field.border,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.s12$md,
                vertical: AppDimens.s12$md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? '—',
                      style: AppFonts.body16(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, size: AppDimens.s20$lg, color: colors.icons.main),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
