import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool absorbPointer;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.absorbPointer = false,
  });

  @override
  Widget build(BuildContext context) {
    final inkWidget = SizedBox.square(
      dimension: AppDimens.switchTapArea,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => onChanged(!value) : null,
          customBorder: const StadiumBorder(),
          child: Center(
            child: _AppSwitchTrack(value: value, enabled: enabled),
          ),
        ),
      ),
    );

    if (absorbPointer) return AbsorbPointer(child: inkWidget);
    return inkWidget;
  }
}

class _AppSwitchTrack extends StatelessWidget {
  final bool value;
  final bool enabled;

  const _AppSwitchTrack({required this.value, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final switchTheme = context.colors.appSwitch;
    final trackColor = value ? switchTheme.trackOn : switchTheme.trackOff;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: AnimatedContainer(
        duration: AppDimens.defaultAnimationDuration,
        curve: Curves.easeInOut,
        width: AppDimens.switchTrackWidth,
        height: AppDimens.switchTrackHeight,
        padding: const EdgeInsets.all(AppDimens.switchTrackPadding),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppDimens.r999$full),
          ),
        ),
        child: SizedBox.square(
          dimension: AppDimens.s20$lg,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: switchTheme.thumb,
              shape: BoxShape.circle,
              boxShadow: switchTheme.thumbShadows,
            ),
          ),
        ),
      ),
    );
  }
}
