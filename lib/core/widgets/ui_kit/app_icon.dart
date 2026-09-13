import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/widgets/ui_kit/asset_paths.dart';

class AppIcon {
  final String? _svgAsset;

  const AppIcon._({this._svgAsset});

  const AppIcon.asset(String assetKey) : this._(svgAsset: assetKey);

  String get asset => _svgAsset ?? '';

  Widget call({
    Color? color,
    double size = AppDimens.defaultIconSize,
    BoxFit? fit,
    VoidCallback? onTap,
    double padding = 0,
  }) {
    final splashRadius = (size / 2) + padding + 8;
    final splashDiameter = splashRadius * 2;

    return Builder(
      builder: (context) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(padding),
              child: _svgAsset == null
                  ? const SizedBox.shrink()
                  : SvgPicture.asset(
                      _svgAsset,
                      package: kPackageName,
                      colorFilter: color != null
                          ? ColorFilter.mode(color, BlendMode.srcIn)
                          : null,
                      fit: fit ?? BoxFit.scaleDown,
                      height: size,
                      width: size,
                    ),
            ),
            Positioned(
              width: splashDiameter,
              height: splashDiameter,
              child: Theme(
                data: onTap != null
                    ? Theme.of(context)
                    : Theme.of(context).copyWith(
                        splashFactory: NoSplash.splashFactory,
                        highlightColor: Colors.transparent,
                      ),
                child: Material(
                  type: MaterialType.transparency,
                  borderRadius: BorderRadius.all(Radius.circular(splashRadius)),
                  clipBehavior: Clip.hardEdge,
                  child: InkResponse(
                    borderRadius: BorderRadius.all(
                      Radius.circular(splashRadius),
                    ),
                    radius: splashRadius,
                    onTap: onTap,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
