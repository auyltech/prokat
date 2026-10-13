import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_input_field_style.dart';

class AppInputFieldBox extends StatelessWidget {
  final bool isFocused;
  final bool hasError;
  final Color backgroundColor;
  final double? height;
  final double? minHeight;
  final Widget child;

  const AppInputFieldBox({
    required this.isFocused,
    required this.hasError,
    required this.backgroundColor,
    required this.child,
    this.height,
    this.minHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.colors.textField;
    final flow = ProkatFlowScope.maybeOf(context);
    final borderColor = hasError
        ? theme.borderError
        : isFocused
        ? flow?.primary ?? theme.borderFocused
        : flow?.border ?? theme.border;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: flow == null
            ? AppInputFieldStyle.borderRadius
            : BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: AppDimens.inputBorderWidth,
        ),
      ),
      child: SizedBox(
        height: height,
        child: height != null
            ? Center(child: child)
            : ConstrainedBox(
                constraints: minHeight == null
                    ? const BoxConstraints()
                    : BoxConstraints(minHeight: minHeight!),
                child: child,
              ),
      ),
    );
  }
}
