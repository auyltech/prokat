import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/core/theme/app_theme.dart';
import 'package:prokat/core/theme/theme_provider.dart';
import 'package:prokat/features/chat/providers/chat_sidebar_bootstrap_provider.dart';
import 'package:prokat/features/map/services/map_language.dart';
import 'package:prokat/features/notifications/providers/notification_bootstrap_provider.dart';
import 'package:prokat/features/workflow/providers/workflow_bootstrap_provider.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  ProviderSubscription<Locale>? _localeSub;

  @override
  void initState() {
    super.initState();

    _localeSub = ref.listenManual(localeProvider, (previous, next) {
      if (previous?.languageCode == next.languageCode) return;
      unawaited(applyMapboxLanguagePreference(next.languageCode));
    }, fireImmediately: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(appStartupProvider.notifier).init());
    });
  }

  @override
  void dispose() {
    _localeSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationBootstrapProvider);
    ref.watch(chatSidebarBootstrapProvider);
    ref.watch(workflowBootstrapProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Prokat',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppSnackBar.messengerKey,
      routerConfig: router,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
