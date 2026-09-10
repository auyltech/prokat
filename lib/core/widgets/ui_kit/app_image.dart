import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/asset_paths.dart';

class AppImage {
  final String iconKey;

  const AppImage(this.iconKey);

  static final RegExp _pngFileRegex = RegExp(r'\.png$');

  bool get isPNG => _pngFileRegex.hasMatch(iconKey);

  Widget call({
    Color? color,
    double? size,
    BoxFit? fit,
    VoidCallback? onTap,
    double padding = 0,
  }) {
    assert(isPNG, 'AppImage currently supports png only');

    return ClipRRect(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Image.asset(
            iconKey,
            package: kPackageName,
            fit: fit ?? BoxFit.contain,
            height: size,
            width: size,
            color: color,
          ),
        ),
      ),
    );
  }
}
