import 'package:flutter/material.dart';

class AppImage {
  final String iconKey;

  const AppImage(this.iconKey);

  static final RegExp _rasterFileRegex = RegExp(r'\.(png|webp)$');

  bool get isRaster => _rasterFileRegex.hasMatch(iconKey);

  Widget call({
    Color? color,
    double? size,
    BoxFit? fit,
    VoidCallback? onTap,
    double padding = 0,
  }) {
    assert(isRaster, 'AppImage currently supports png/webp only');

    return ClipRRect(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Image.asset(
            iconKey,
            //Не используется т.к. UIkit не в отдельном пакете
            //package: kPackageName,
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
