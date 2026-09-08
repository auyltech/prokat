import 'package:flutter/material.dart';

/// Overlay pin whose **tip** sits on the map camera center.
///
/// [Icon] is laid out around its box center. Without the bottom padding the
/// geocoded point would be the middle of the teardrop, not the tip.
class CenterPin extends StatelessWidget {
  const CenterPin({super.key, this.iconKey});

  final Key? iconKey;
  static const double size = 50;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: size),
          child: Icon(
            Icons.location_pin,
            key: iconKey,
            size: size,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
