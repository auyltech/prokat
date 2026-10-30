import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/updates/app_update_policy.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

class PolicyAppUpgrader extends Upgrader {
  PolicyAppUpgrader({super.storeController, super.upgraderOS})
    : super(countryCode: 'KZ');

  String? _emergencyMinimum;
  List<ForcedAppVersion> _forcedVersions = const [];
  String? _lastDiagnostic;
  void setEmergencyRules({
    String? minimum,
    List<ForcedAppVersion> forcedVersions = const [],
  }) {
    if (_emergencyMinimum == minimum &&
        listEquals(_forcedVersions, forcedVersions)) {
      return;
    }
    _emergencyMinimum = minimum;
    _forcedVersions = List.unmodifiable(forcedVersions);
    updateStream();
  }

  void setEmergencyMinimum(String? value) {
    setEmergencyRules(minimum: value, forcedVersions: _forcedVersions);
  }

  String? get effectiveMinimum => effectiveAppMinimum(
    remote: _emergencyMinimum,
    store: effectiveAppMinimum(
      remote: state.minAppVersion?.toString(),
      store: versionInfo?.minAppVersion?.toString(),
    )?.toString(),
  )?.toString();

  AppUpdateDecision get decision => evaluateAppUpdate(
    installed: state.packageInfo?.version,
    installedBuild: state.packageInfo?.buildNumber,
    latest: versionInfo?.appStoreVersion?.toString(),
    minimum: effectiveMinimum,
    forcedVersions: _forcedVersions,
  );

  AppUpdatePolicy get policy {
    final result = decision;
    final diagnostic = result.diagnostics.isEmpty
        ? null
        : '${result.diagnostics}: installed=${state.packageInfo?.version}+${state.packageInfo?.buildNumber}, '
              'store=${versionInfo?.appStoreVersion}, minimum=$effectiveMinimum';
    if (diagnostic != _lastDiagnostic) {
      _lastDiagnostic = diagnostic;
      if (diagnostic != null) {
        Logger.log('Update enforcement deferred: $diagnostic');
      }
    }
    return result.policy;
  }

  @override
  bool belowMinAppVersion() =>
      evaluateAppUpdate(
        installed: state.packageInfo?.version,
        latest: versionInfo?.appStoreVersion?.toString(),
        minimum: effectiveMinimum,
      ).reason ==
      AppUpdateReason.minimum;

  @override
  bool blocked() => policy == AppUpdatePolicy.hard;

  @override
  bool shouldDisplayUpgrade() => switch (policy) {
    AppUpdatePolicy.hard => true,
    AppUpdatePolicy.soft => super.shouldDisplayUpgrade(),
    _ => false,
  };

  @override
  Future<void> sendUserToAppStore() async {
    if (currentAppStoreListingURL?.isNotEmpty ?? false) {
      return super.sendUserToAppStore();
    }
    // A voluntary store action may use the known listing before lookup. This
    // URL fallback does not constitute proof for mandatory update availability.
    final url = state.upgraderOS.currentOSType == UpgraderOSType.ios
        ? 'https://apps.apple.com/kz/app/prokat/id6817078475'
        : 'https://play.google.com/store/apps/details?id=com.auyltech.prokat';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      Logger.log('Update store launch failed: $error');
    }
  }
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
    required this.backButtonDispatcher,
    required this.locale,
    required this.enabled,
    required this.child,
    this.upgrader,
    this.emergencyMinimum,
    this.forcedVersions = const [],
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final BackButtonDispatcher backButtonDispatcher;
  final Locale locale;
  final bool enabled;
  final Widget child;
  final PolicyAppUpgrader? upgrader;
  final String? emergencyMinimum;
  final List<ForcedAppVersion> forcedVersions;

  @override
  State<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends State<AppUpdatePrompt> {
  late final PolicyAppUpgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _upgrader = widget.upgrader ?? PolicyAppUpgrader();
    _upgrader.setEmergencyRules(
      minimum: widget.emergencyMinimum,
      forcedVersions: widget.forcedVersions,
    );
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
    if (oldWidget.emergencyMinimum != widget.emergencyMinimum ||
        !listEquals(oldWidget.forcedVersions, widget.forcedVersions)) {
      _upgrader.setEmergencyRules(
        minimum: widget.emergencyMinimum,
        forcedVersions: widget.forcedVersions,
      );
    }
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
    if (!mobile || Env.isLocal) return widget.child;
    return _RouteSafeUpgradeAlert(
      enabled: widget.enabled,
      upgrader: _upgrader,
      navigatorKey: widget.navigatorKey,
      backButtonDispatcher: widget.backButtonDispatcher,
      child: widget.child,
    );
  }
}

class _RouteSafeUpgradeAlert extends UpgradeAlert {
  _RouteSafeUpgradeAlert({
    required this.backButtonDispatcher,
    required this.enabled,
    required super.upgrader,
    required super.navigatorKey,
    required super.child,
  }) : super(barrierDismissible: true);

  final bool enabled;
  final BackButtonDispatcher backButtonDispatcher;

  @override
  UpgradeAlertState createState() => _RouteSafeUpgradeAlertState();
}

class _RouteSafeUpgradeAlertState extends UpgradeAlertState {
  DialogRoute<void>? _softRoute;
  late ChildBackButtonDispatcher _hardBackDispatcher;
  PolicyAppUpgrader get _controller => widget.upgrader as PolicyAppUpgrader;
  bool get _hard => _controller.policy == AppUpdatePolicy.hard;

  Future<bool> _consumeHardBack() async => _hard;

  void _removeSoftRoute() {
    final route = _softRoute;
    if (route?.isActive ?? false) route!.navigator?.removeRoute(route);
  }

  void _checkAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_hard) {
        _removeSoftRoute();
        _hardBackDispatcher.takePriority();
        return;
      }
      (widget as _RouteSafeUpgradeAlert).backButtonDispatcher.forget(
        _hardBackDispatcher,
      );
      if (_controller.policy != AppUpdatePolicy.soft) _removeSoftRoute();
      if (displayed) return;
      final context = widget.navigatorKey?.currentContext;
      if (context != null) checkVersion(context: context);
    });
  }

  @override
  void initState() {
    super.initState();
    _hardBackDispatcher =
        (widget as _RouteSafeUpgradeAlert).backButtonDispatcher
            .createChildBackButtonDispatcher()
          ..addCallback(_consumeHardBack);
    _checkAfterFrame();
  }

  @override
  void didUpdateWidget(UpgradeAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAfterFrame();
  }

  @override
  void dispose() {
    _hardBackDispatcher.removeCallback(_consumeHardBack);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<UpgraderState>(
    initialData: widget.upgrader.state,
    stream: widget.upgrader.stateStream,
    builder: (context, _) {
      _checkAfterFrame();
      final hard = _hard;
      final messages = widget.upgrader.determineMessages(context);
      return Stack(
        fit: StackFit.expand,
        children: [
          ExcludeFocus(
            excluding: hard,
            child: ExcludeSemantics(
              excluding: hard,
              child: widget.child ?? const SizedBox.shrink(),
            ),
          ),
          if (hard) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            FocusScope(
              autofocus: true,
              child: SafeArea(
                child: Center(
                  child: alertDialog(
                    const Key('upgrader_hard_dialog'),
                    messages.title,
                    widget.upgrader.body(messages),
                    shouldDisplayReleaseNotes
                        ? widget.upgrader.releaseNotes
                        : null,
                    context,
                    false,
                    messages,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );

  @override
  void checkVersion({required BuildContext context}) {
    if (_controller.policy != AppUpdatePolicy.soft ||
        !(widget as _RouteSafeUpgradeAlert).enabled ||
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
        _controller.policy != AppUpdatePolicy.soft ||
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
    _softRoute = route;
    unawaited(
      Navigator.of(context, rootNavigator: true).push(route).whenComplete(() {
        // Barrier/back, router replacement, and buttons all release the guard.
        if (_softRoute == route) {
          _softRoute = null;
          displayed = false;
        }
      }),
    );
  }

  @override
  void popNavigator(BuildContext context) {
    if (_hard) return;
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
