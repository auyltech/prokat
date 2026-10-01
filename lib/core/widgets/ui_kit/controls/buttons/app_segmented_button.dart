import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

class AppSegmentedOption<T> {
  final String title;
  final T value;
  final Widget? prefix;
  final Widget? postfix;

  const AppSegmentedOption({
    required this.title,
    required this.value,
    this.prefix,
    this.postfix,
  });
}

/// Exclusive segment control as one chrome unit.
///
/// Selected segment matches [AppElevatedButton] fill. Idle segments use field
/// fill; their outer edges are a 1px input-field border, shared idle|idle
/// edges are 0.5px each (1px combined), and selected|idle edges have no border.
class AppSegmentedButton<T> extends StatelessWidget {
  final List<AppSegmentedOption<T>> segments;
  final T? value;
  final ValueChanged<T> onChanged;
  final bool isExpanded;
  final bool enabled;

  const AppSegmentedButton({
    super.key,
    required this.segments,
    required this.onChanged,
    this.value,
    this.isExpanded = false,
    this.enabled = true,
  }) : assert(
         segments.length >= 2,
         'AppSegmentedButton needs at least 2 segments',
       );

  static const _outerBorderWidth = AppDimens.buttonBorderWidth;
  static const _sharedIdleBorderWidth = AppDimens.buttonBorderWidth * 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = context.colors.segmentedButton;
    final borderColor = context.colors.textField.border;
    final textStyle = AppFonts.button(context);
    final flexes = isExpanded
        ? _contentFlexes(context, textStyle)
        : List<int>.filled(segments.length, 1);

    final row = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < segments.length; i++)
          if (isExpanded)
            Expanded(
              flex: flexes[i],
              child: _Segment(
                option: segments[i],
                selected: _isSelected(i),
                expanded: true,
                borderRadius: _segmentRadius(i),
                border: _segmentBorder(index: i, borderColor: borderColor),
                onTap: enabled ? () => onChanged(segments[i].value) : null,
              ),
            )
          else
            _Segment(
              option: segments[i],
              selected: _isSelected(i),
              expanded: false,
              borderRadius: _segmentRadius(i),
              border: _segmentBorder(index: i, borderColor: borderColor),
              onTap: enabled ? () => onChanged(segments[i].value) : null,
            ),
      ],
    );

    final control = SizedBox(height: AppDimens.buttonHeight, child: row);

    return Opacity(
      opacity: enabled ? 1 : theme.disabledOpacity,
      child: isExpanded
          ? control
          : Align(alignment: Alignment.centerLeft, child: control),
    );
  }

  bool _isSelected(int index) => segments[index].value == value;

  bool _neighborSelected(int index) {
    if (index < 0 || index >= segments.length) return false;
    return _isSelected(index);
  }

  Border _segmentBorder({required int index, required Color borderColor}) {
    if (_isSelected(index)) {
      return const Border.fromBorderSide(BorderSide.none);
    }

    final outer = BorderSide(color: borderColor, width: _outerBorderWidth);
    final sharedIdle = BorderSide(
      color: borderColor,
      width: _sharedIdleBorderWidth,
    );
    const none = BorderSide.none;

    final leftNeighborSelected = _neighborSelected(index - 1);
    final rightNeighborSelected = _neighborSelected(index + 1);

    return Border(
      top: outer,
      bottom: outer,
      left: index == 0 ? outer : (leftNeighborSelected ? none : sharedIdle),
      right: index == segments.length - 1
          ? outer
          : (rightNeighborSelected ? none : sharedIdle),
    );
  }

  BorderRadius _segmentRadius(int index) {
    const radius = Radius.circular(AppDimens.r12$lg);
    final last = segments.length - 1;
    if (index == 0 && index == last) {
      return const BorderRadius.all(radius);
    }
    if (index == 0) {
      return const BorderRadius.only(topLeft: radius, bottomLeft: radius);
    }
    if (index == last) {
      return const BorderRadius.only(topRight: radius, bottomRight: radius);
    }
    return BorderRadius.zero;
  }

  List<int> _contentFlexes(BuildContext context, TextStyle textStyle) {
    final direction = Directionality.of(context);
    return [
      for (final option in segments)
        math.max(1, _measureContentWidth(option, textStyle, direction).round()),
    ];
  }

  double _measureContentWidth(
    AppSegmentedOption<T> option,
    TextStyle textStyle,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: option.title, style: textStyle),
      textDirection: direction,
      maxLines: 1,
    )..layout();
    var extras = 0.0;
    if (option.prefix != null) {
      extras += AppDimens.s20$lg + AppDimens.s08$sm;
    }
    if (option.postfix != null) {
      extras += AppDimens.s20$lg + AppDimens.s08$sm;
    }
    return painter.width + extras + AppDimens.s16$base * 2;
  }
}

class _Segment extends StatelessWidget {
  final AppSegmentedOption<dynamic> option;
  final bool selected;
  final bool expanded;
  final BorderRadius borderRadius;
  final Border border;
  final VoidCallback? onTap;

  const _Segment({
    required this.option,
    required this.selected,
    required this.expanded,
    required this.borderRadius,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.colors.segmentedButton;
    final background = selected
        ? theme.selectedBackground
        : theme.unselectedBackground;
    final contentColor = selected
        ? theme.selectedContent
        : theme.unselectedContent;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        border: border,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.s20$lg),
            child: IconTheme.merge(
              data: IconThemeData(color: contentColor, size: AppDimens.s20$lg),
              child: Row(
                mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppDimens.s08$sm,
                children: [
                  ?option.prefix,
                  if (expanded)
                    Flexible(
                      child: Text(
                        option.title,
                        style: AppFonts.button(context)
                            .copyWith(color: contentColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Text(
                      option.title,
                      style: AppFonts.button(context)
                          .copyWith(color: contentColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ?option.postfix,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
