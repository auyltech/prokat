import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';

abstract final class AppInputFieldStyle {
  static BorderRadius get borderRadius =>
      BorderRadius.circular(AppDimens.r10$base);

  static EdgeInsets get contentPadding => const EdgeInsets.symmetric(
    horizontal: AppDimens.s12$md,
    vertical: AppDimens.s12$md,
  );

  static const InputBorder noBorder = InputBorder.none;

  static const BoxConstraints affixIconConstraints = BoxConstraints();
}
