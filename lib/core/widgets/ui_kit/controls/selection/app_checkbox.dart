import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_icons.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

class AppCheckbox extends StatelessWidget {
  final bool value;
  final bool hasError;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool absorbPointer;

  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.hasError = false,
    this.enabled = true,
    this.absorbPointer = false,
  });

  @override
  Widget build(BuildContext context) {
    final box = _AppCheckboxBox(
      value: value,
      hasError: hasError,
      enabled: enabled,
    );

    if (absorbPointer) return box;

    return SizedBox.square(
      dimension: AppDimens.checkboxTapArea,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => onChanged(!value) : null,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppDimens.checkboxRadius),
          ),
          child: Center(child: box),
        ),
      ),
    );
  }
}

class AppCheckboxTile extends StatelessWidget {
  final bool value;
  final String title;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool hasError;

  const AppCheckboxTile({
    super.key,
    required this.value,
    required this.title,
    required this.onChanged,
    this.enabled = true,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.s08$sm),
        child: Row(
          children: [
            AppCheckbox(
              value: value,
              onChanged: onChanged,
              enabled: enabled,
              hasError: hasError,
              absorbPointer: true,
            ),
            const SizedBox(width: AppDimens.s12$md),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: enabled ? colors.text.main : colors.text.disabled,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppCheckboxBox extends StatelessWidget {
  final bool value;
  final bool hasError;
  final bool enabled;

  const _AppCheckboxBox({
    required this.value,
    required this.hasError,
    required this.enabled,
  });

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppDimens.checkboxRadius),
  );

  @override
  Widget build(BuildContext context) {
    final selection = context.colors.selection;
    final fillColor = value ? selection.fillSelected : selection.fillUnselected;
    final borderColor = hasError
        ? selection.borderError
        : (value ? selection.fillSelected : selection.border);

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: AnimatedContainer(
        duration: AppDimens.defaultAnimationDuration,
        curve: Curves.easeInOut,
        width: AppDimens.checkboxSize,
        height: AppDimens.checkboxSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: _radius,
          boxShadow: value ? const [] : selection.uncheckedShadows,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: _radius,
          border: Border.all(
            color: borderColor,
            width: AppDimens.checkboxBorderWidth,
          ),
        ),
        child: AnimatedScale(
          scale: value ? 1 : 0,
          duration: AppDimens.defaultAnimationDuration,
          child: IgnorePointer(
            child: AppIcons.check.call(
              size: AppDimens.s12$md,
              color: selection.iconOnFill,
            ),
          ),
        ),
      ),
    );
  }
}
