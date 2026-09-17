import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';

abstract final class AppInputFieldStyle {
  static BorderRadius get borderRadius =>
      BorderRadius.circular(AppDimens.r16$xl);

  static EdgeInsets get contentPadding => const EdgeInsets.symmetric(
    horizontal: AppDimens.s16$base,
    vertical: AppDimens.s12$md,
  );

  static const EdgeInsetsDirectional prefixIconPadding =
      EdgeInsetsDirectional.only(start: AppDimens.s12$md);

  static const EdgeInsetsDirectional suffixIconPadding =
      EdgeInsetsDirectional.only(end: AppDimens.s12$md);

  static const InputBorder noBorder = InputBorder.none;

  static const BoxConstraints affixIconConstraints = BoxConstraints();
}
