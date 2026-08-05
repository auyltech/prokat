import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/app.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/theme/app_theme.dart';
import 'package:prokat/core/theme/theme_provider.dart';
import 'package:prokat/features/appstatic/screens/launch_screen.dart';
import 'package:prokat/firebase_options.dart';
import 'package:prokat/l10n/app_localizations.dart';

Future<void> initializeFirebaseServices() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }
}

class FirebaseBootstrap extends ConsumerStatefulWidget {
  const FirebaseBootstrap({super.key});

  @override
  ConsumerState<FirebaseBootstrap> createState() =>
      _FirebaseBootstrapState();
}

class _FirebaseBootstrapState extends ConsumerState<FirebaseBootstrap> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = initializeFirebaseServices();
  }

  void _retry() {
    setState(() {
      _initialization = initializeFirebaseServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const MyApp();
        }

        final themeMode = ref.watch(themeModeProvider);
        final locale = ref.watch(localeProvider);

        return MaterialApp(
          title: 'Prokat',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: snapshot.hasError
              ? _FirebaseInitializationError(onRetry: _retry)
              : const LaunchScreen(),
        );
      },
    );
  }
}

class _FirebaseInitializationError extends StatelessWidget {
  const _FirebaseInitializationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sync_problem_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.initializationError,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.initializationErrorMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(l10n.retryConnection),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
