import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/core/theme/app_theme.dart';
import 'package:prokat/core/theme/theme_provider.dart';
import 'package:prokat/features/notifications/providers/notification_bootstrap_provider.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStartupProvider.notifier).init();
    });
  }

  // TODO: Adjust darkTheme colors and set darktheme
  @override
  Widget build(BuildContext context) {
    ref.watch(notificationBootstrapProvider);
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
      darkTheme: AppTheme.lightTheme, // AppTheme.darkTheme
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
