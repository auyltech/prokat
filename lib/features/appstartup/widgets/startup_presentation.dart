import 'dart:async';

import 'package:flutter/material.dart';

/// Branding covers the already loading app, without delaying authentication or
/// router decisions. Only the first presentation in this app instance is held.
class StartupPresentation extends StatefulWidget {
  const StartupPresentation({
    super.key,
    required this.loading,
    required this.splash,
    required this.child,
  });
  final bool loading;
  final Widget splash;
  final Widget child;
  static const minimumDuration = Duration(seconds: 2);
  static const transitionDuration = Duration(milliseconds: 320);

  @override
  State<StartupPresentation> createState() => _StartupPresentationState();
}

class _StartupPresentationState extends State<StartupPresentation> {
  Timer? _timer;
  bool _elapsed = false;
  bool _revealing = false;
  bool _covered = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(StartupPresentation.minimumDuration, () {
      _elapsed = true;
      _revealIfReady();
    });
  }

  @override
  void didUpdateWidget(covariant StartupPresentation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _revealIfReady();
  }

  void _revealIfReady() {
    if (_elapsed && !widget.loading && !_revealing && mounted) {
      setState(() => _revealing = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      // Mount the destination as soon as routing is ready so its data can load
      // during the remaining logo animation; avoid mounting a duplicate splash.
      if (!widget.loading || !_covered)
        ExcludeSemantics(
          excluding: _covered,
          child: IgnorePointer(ignoring: _covered, child: widget.child),
        ),
      if (_covered)
        AnimatedOpacity(
          opacity: _revealing ? 0 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : StartupPresentation.transitionDuration,
          onEnd: () {
            if (_revealing && mounted) setState(() => _covered = false);
          },
          child: widget.splash,
        ),
    ],
  );
}
