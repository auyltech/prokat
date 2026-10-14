import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// This release only offers updates. Store description minimum-version tags
/// and critical-update metadata must never turn it into a blocking prompt.
class SoftAppUpgrader extends Upgrader {
  SoftAppUpgrader({super.storeController, super.upgraderOS})
    : super(countryCode: 'KZ');

  @override
  bool blocked() => false;
}

class AppUpgradeMessages extends UpgraderMessages {
  AppUpgradeMessages(String code) : super(code: code);

  @override
  String get buttonTitleIgnore => switch (languageCode) {
    'kk' => 'Елемеу',
    'ru' => 'Игнорировать',
    _ => super.buttonTitleIgnore,
  };

  @override
  String get body => languageCode == 'kk'
      ? '{{appName}} қолданбасының жаңа нұсқасы қолжетімді! '
            'Жаңа нұсқа: {{currentAppStoreVersion}}, '
            'қазіргі нұсқа: {{currentInstalledVersion}}.'
      : super.body;

  @override
  String get releaseNotes =>
      languageCode == 'kk' ? 'Жаңартудағы өзгерістер' : super.releaseNotes;
}

/// Kept above the router child so route changes do not recreate the controller.
/// Prompts wait until startup has established a usable app route.
class AppUpdatePrompt extends StatefulWidget {
  const AppUpdatePrompt({
    super.key,
    required this.navigatorKey,
    required this.locale,
    required this.enabled,
    required this.child,
    this.upgrader,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Locale locale;
  final bool enabled;
  final Widget child;
  final SoftAppUpgrader? upgrader;

  @override
  State<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends State<AppUpdatePrompt> {
  late final SoftAppUpgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _upgrader = widget.upgrader ?? SoftAppUpgrader();
    _applyLocale();
  }

  void _applyLocale() {
    final code = widget.locale.languageCode;
    _upgrader.updateState(
      _upgrader.state.copyWith(
        languageCodeOverride: code,
        messages: AppUpgradeMessages(code),
      ),
    );
  }

  @override
  void didUpdateWidget(AppUpdatePrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) _applyLocale();
  }

  @override
  void dispose() {
    if (widget.upgrader == null) _upgrader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!mobile) return widget.child;
    return _RouteSafeUpgradeAlert(
      enabled: widget.enabled,
      upgrader: _upgrader,
      navigatorKey: widget.navigatorKey,
      child: widget.child,
    );
  }
}

class _RouteSafeUpgradeAlert extends UpgradeAlert {
  _RouteSafeUpgradeAlert({
    required this.enabled,
    required super.upgrader,
    required super.navigatorKey,
    required super.child,
  }) : super(barrierDismissible: true);

  final bool enabled;

  @override
  UpgradeAlertState createState() => _RouteSafeUpgradeAlertState();
}

class _RouteSafeUpgradeAlertState extends UpgradeAlertState {
  void _checkAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || displayed) return;
      final context = widget.navigatorKey?.currentContext;
      if (context != null) checkVersion(context: context);
    });
  }

  @override
  void initState() {
    super.initState();
    _checkAfterFrame();
  }

  @override
  void didUpdateWidget(UpgradeAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAfterFrame();
  }

  @override
  void checkVersion({required BuildContext context}) {
    if (!(widget as _RouteSafeUpgradeAlert).enabled ||
        widget.navigatorKey?.currentContext == null) {
      return;
    }
    super.checkVersion(context: context);
  }

  @override
  void showTheDialog({
    Key? key,
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool barrierDismissible,
    required UpgraderMessages messages,
  }) {
    if (!mounted ||
        !context.mounted ||
        !(widget as _RouteSafeUpgradeAlert).enabled) {
      displayed = false;
      return;
    }
    unawaited(widget.upgrader.saveLastAlerted());
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => PopScope(
        canPop: true,
        child: alertDialog(
          key,
          title ?? '',
          message,
          releaseNotes,
          dialogContext,
          false,
          messages,
        ),
      ),
    );
    unawaited(
      Navigator.of(context, rootNavigator: true).push(route).whenComplete(() {
        // Barrier/back, router replacement, and buttons all release the guard.
        displayed = false;
      }),
    );
  }

  @override
  void popNavigator(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    final navigator = Navigator.of(context);
    if (route.isCurrent) {
      navigator.pop();
    } else {
      // A warm app link may have pushed equipment above this dialog. Removing
      // the specific dialog keeps that equipment and its navigation stack.
      navigator.removeRoute(route);
    }
    displayed = false;
  }
}
