import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

class AppRadio extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const AppRadio({
    super.key,
    required this.value,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radioColor = enabled ? colors.radio.enabled : colors.radio.disabled;

    return SizedBox.square(
      dimension: AppDimens.buttonHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => onChanged?.call(!value) : null,
          customBorder: const CircleBorder(),
          child: Center(
            child: Container(
              width: AppDimens.s20$lg,
              height: AppDimens.s20$lg,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: radioColor, width: 2),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: AppDimens.defaultAnimationDuration,
                  width: AppDimens.r10$base,
                  height: AppDimens.r10$base,
                  decoration: BoxDecoration(
                    color: value ? radioColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppRadioTile extends StatelessWidget {
  final bool value;
  final String title;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const AppRadioTile({
    super.key,
    required this.value,
    required this.title,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: enabled ? () => onChanged?.call(!value) : null,
      child: Row(
        children: [
          AppRadio(value: value, enabled: enabled, onChanged: onChanged),
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
    );
  }
}
