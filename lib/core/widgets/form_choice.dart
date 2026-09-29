import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

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
    return AppSegmentedButton<int>(
      isExpanded: true,
      value: leftSelected
          ? 0
          : rightSelected
          ? 1
          : null,
      segments: [
        AppSegmentedOption(title: leftLabel, value: 0),
        AppSegmentedOption(title: rightLabel, value: 1),
      ],
      onChanged: (value) {
        if (value == 0) {
          onLeft();
        } else {
          onRight();
        }
      },
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
