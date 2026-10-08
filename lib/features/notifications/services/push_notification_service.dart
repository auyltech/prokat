import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';
import 'package:prokat/features/notifications/services/notification_api_service.dart';
import 'package:prokat/features/notifications/services/notification_local_storage.dart';
import 'package:prokat/features/notifications/services/notification_navigation_service.dart';
import 'package:prokat/features/notifications/utils/chat_push_tag.dart';

class PushNotificationService {
  static const String _androidChannelId = 'prokat_alerts';
  static const String _androidNotificationIcon = 'ic_notification';
  static const Color _androidNotificationColor = Color(0xFFFFCA0A);

  final FirebaseMessaging messaging;
  final FlutterLocalNotificationsPlugin localNotifications;
  final NotificationApiService api;
  final NotificationLocalStorage storage;
  final NotificationNavigationService navigation;
  final void Function(AppNotification notification) onIncoming;
  final bool Function(String id)? shouldSuppressDisplay;
  final String Function()? currentLocale;
  final bool Function(AppNotification)? accepts;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  bool _initialized = false;
  bool _localNotificationsReady = false;
  bool _syncInFlight = false;
  String? _registeredScope;
  bool _apnsSyncPending = false;
  final Map<String, DateTime> _displayedIds = {};

  static const int _apnsTokenAttempts = 10;
  static const Duration _apnsTokenDelay = Duration(milliseconds: 500);

  /// True after an Apple sync stopped because the APNs token was still null.
  /// Cleared when a later [syncCurrentDevice] obtains the token.
  bool get apnsSyncPending => _apnsSyncPending;

  bool get _isApplePushPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  PushNotificationService({
    required this.messaging,
    required this.localNotifications,
    required this.api,
    required this.storage,
    required this.navigation,
    required this.onIncoming,
    this.shouldSuppressDisplay,
    this.currentLocale,
    this.accepts,
  });

  Future<void> initialize({required AuthSession session}) async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (!kIsWeb) {
        await _initLocalNotifications();
      }
    } catch (error, stackTrace) {
      // Best-effort: local notifications shouldn't crash startup.
      _pushLog('local notifications init failed: $error\n$stackTrace');
    }

    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
    } catch (error, stackTrace) {
      // Best-effort: missing OS permission should not crash startup.
      _pushLog('notification permission request failed: $error\n$stackTrace');
    }

    // Register this device only when OS permission is granted.
    try {
      await syncCurrentDevice(session: session);
    } catch (error, stackTrace) {
      // Best-effort: push setup should not crash startup.
      _pushLog('syncCurrentDevice failed: $error\n$stackTrace');
    }

    // Future token changes are also permission-gated.
    try {
      listenForTokenRefresh(session: session);
    } catch (error, stackTrace) {
      _pushLog('listenForTokenRefresh failed: $error\n$stackTrace');
    }

    try {
      handleForegroundMessages();
    } catch (error, stackTrace) {
      _pushLog('handleForegroundMessages failed: $error\n$stackTrace');
    }

    try {
      handleBackgroundNotificationTap();
    } catch (error, stackTrace) {
      _pushLog('handleBackgroundNotificationTap failed: $error\n$stackTrace');
    }

    try {
      await handleTerminatedNotificationTap();
    } catch (error, stackTrace) {
      _pushLog('handleTerminatedNotificationTap failed: $error\n$stackTrace');
    }
  }

  void _pushLog(String message) {
    Logger.log('push: $message');
  }

  Future<String?> getFcmToken() async {
    if (kIsWeb) return null;
    if (_isApplePushPlatform) {
      final apnsToken = await messaging.getAPNSToken();
      if ((apnsToken ?? '').trim().isEmpty) {
        _pushLog('getToken skipped: APNs token unavailable');
        return null;
      }
    }
    return messaging.getToken();
  }

  /// Polls until iOS/macOS delivers an APNs token, or the short window ends.
  /// Does not call FCM [FirebaseMessaging.getToken].
  Future<String?> _waitForApnsToken() async {
    Object? lastError;
    for (var attempt = 1; attempt <= _apnsTokenAttempts; attempt++) {
      try {
        final apnsToken = await messaging.getAPNSToken();
        if ((apnsToken ?? '').trim().isNotEmpty) {
          return apnsToken!.trim();
        }
      } catch (error) {
        lastError = error;
      }
      if (attempt < _apnsTokenAttempts) {
        await Future.delayed(_apnsTokenDelay);
      }
    }
    _pushLog(
      lastError == null
          ? 'APNs token still unavailable after $_apnsTokenAttempts attempts'
          : 'APNs token still unavailable after $_apnsTokenAttempts attempts: $lastError',
    );
    return null;
  }

  Future<void> registerTokenWithBackend({
    required AuthSession session,
    required String token,
    String? locale,
    bool force = false,
  }) async {
    if (kIsWeb) return;
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      _pushLog('device token registration skipped: empty FCM token');
      return;
    }

    final userId = session.user?.id ?? session.user?.phoneNumber;
    final resolvedLocale = (locale ?? currentLocale?.call() ?? '')
        .trim()
        .toLowerCase();

    final last = await storage.readLastRegisteredToken();
    final lastToken = last?.token.trim();
    final lastAt = last?.at;
    final lastUserId = last?.userId;
    final lastLocale = last?.locale?.trim().toLowerCase();

    final tooSoon =
        lastAt != null &&
        DateTime.now().difference(lastAt) < const Duration(hours: 12);

    final localeChanged =
        resolvedLocale.isNotEmpty && resolvedLocale != lastLocale;

    if (!force &&
        lastToken == normalizedToken &&
        lastUserId == userId &&
        tooSoon &&
        !localeChanged &&
        _registeredScope == api.currentScope) {
      return;
    }

    final platform = _platformName();
    final registeredScope = api.currentScope;

    await api.registerDeviceToken(
      token: normalizedToken,
      platform: platform,
      metadata: {
        if (resolvedLocale.isNotEmpty) 'locale': resolvedLocale,
        'notificationScope': registeredScope,
      },
    );

    _registeredScope = registeredScope;
    await storage.saveLastRegisteredToken(
      token: normalizedToken,
      at: DateTime.now(),
      userId: userId,
      locale: resolvedLocale.isEmpty ? null : resolvedLocale,
    );
  }

  String _platformName() {
    if (kIsWeb) return 'WEB';

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'IOS';
      case TargetPlatform.android:
        return 'ANDROID';
      default:
        return 'ANDROID';
    }
  }

  void listenForTokenRefresh({required AuthSession session}) {
    unawaited(_onTokenRefreshSub?.cancel());
    _onTokenRefreshSub = messaging.onTokenRefresh.listen((token) async {
      try {
        final settings = await messaging.getNotificationSettings();

        final authorized =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

        if (!authorized) {
          _pushLog(
            'onTokenRefresh skipped: notification permission not granted '
            '(${settings.authorizationStatus})',
          );
          return;
        }

        await registerTokenWithBackend(session: session, token: token);
      } catch (error, stackTrace) {
        // Best-effort.
        _pushLog('onTokenRefresh failed: $error\n$stackTrace');
      }
    });
  }

  void handleForegroundMessages() {
    unawaited(_onMessageSub?.cancel());
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      final notification = _toAppNotification(message);
      if (notification == null) return;

      onIncoming(notification);

      if (shouldSuppressDisplay?.call(notification.id.trim()) ?? false) {
        return;
      }

      await presentIncoming(notification);
    });
  }

  void handleBackgroundNotificationTap() {
    unawaited(_onMessageOpenedSub?.cancel());
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      unawaited(handleNotificationTap(message));
    });
  }

  Future<void> handleTerminatedNotificationTap() async {
    final initial = await messaging.getInitialMessage();
    if (initial == null) return;
    await handleNotificationTap(initial);
  }

  Future<void> handleNotificationTap(RemoteMessage message) async {
    final notification = _toAppNotification(message);
    if (notification == null) return;

    onIncoming(notification);
    await navigation.navigate(notification);
  }

  AppNotification? _toAppNotification(RemoteMessage message) {
    try {
      final data = Map<String, dynamic>.from(message.data);

      final id = (data['id'] ?? message.messageId ?? '').toString();
      if (id.trim().isEmpty) return null;

      final title =
          (data['title'] ?? message.notification?.title ?? 'Notification')
              .toString();
      final body = (data['body'] ?? message.notification?.body ?? '')
          .toString();

      return AppNotification(
        id: id,
        type: NotificationTypeParser.parse(data['type']),
        category: (data['category'] ?? '').toString(),
        title: title,
        body: body,
        data: data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : data,
        route: data['route']?.toString(),
        deepLink: data['deepLink']?.toString(),
        priority: data['priority']?.toString(),
        readAt: null,
        seenAt: null,
        createdAt: null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Heads-up banner while the app is open. FCM does not draw a system tray
  /// notification in the foreground, so socket events must use the same path.
  Future<void> presentIncoming(AppNotification notification) async {
    if (!(accepts?.call(notification) ?? true)) return;
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    final id = notification.id.trim();
    if (notification.isRead || (shouldSuppressDisplay?.call(id) ?? false)) {
      return;
    }
    final now = DateTime.now();
    _displayedIds.removeWhere(
      (_, at) => now.difference(at) > const Duration(minutes: 10),
    );
    if (id.isNotEmpty && _displayedIds.containsKey(id)) return;
    if (id.isNotEmpty) _displayedIds[id] = now;

    try {
      await _initLocalNotifications();
      await _showLocalNotification(notification);
    } catch (_) {
      if (id.isNotEmpty) _displayedIds.remove(id);
    }
  }

  Future<void> _initLocalNotifications() async {
    if (_localNotificationsReady) return;
    const android = AndroidInitializationSettings(_androidNotificationIcon);
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if ((payload ?? '').trim().isEmpty) return;
        try {
          final json = jsonDecode(payload!);
          if (json is Map<String, dynamic>) {
            await navigation.navigate(AppNotification.fromJson(json));
          }
        } catch (_) {}
      },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        _androidChannelId,
        'Notifications',
        description: 'Prokat notifications',
        importance: Importance.max,
      );

      final androidPlugin = localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(channel);
    }
    _localNotificationsReady = true;
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    final chatId = notification.chatId;
    final tag = chatId == null ? null : chatPushTag(chatId);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        'Notifications',
        channelDescription: 'Prokat notifications',
        icon: _androidNotificationIcon,
        color: _androidNotificationColor,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        tag: tag,
      ),
      iOS: tag == null
          ? const DarwinNotificationDetails()
          : DarwinNotificationDetails(threadIdentifier: tag),
    );

    await localNotifications.show(
      id: tag?.hashCode ?? notification.id.hashCode,
      title: notification.localizedTitle(currentLocale?.call() ?? 'ru'),
      body: notification.localizedBody(currentLocale?.call() ?? 'ru'),
      notificationDetails: details,
      payload: jsonEncode(notification.toJson()),
    );
  }

  Future<void> dismissDisplayedForChat(String chatId) async {
    if (kIsWeb) return;

    final normalizedChatId = chatId.trim();
    if (normalizedChatId.isEmpty) return;

    final tag = chatPushTag(normalizedChatId);

    try {
      await localNotifications.cancel(id: 0, tag: tag);
      await localNotifications.cancel(id: tag.hashCode, tag: tag);
    } catch (_) {}

    try {
      final active = await localNotifications.getActiveNotifications();
      for (final notification in active) {
        if (!displayedNotificationMatchesChat(
          chatId: normalizedChatId,
          tag: notification.tag,
          payload: notification.payload,
        )) {
          continue;
        }

        await localNotifications.cancel(
          id: notification.id ?? 0,
          tag: notification.tag,
        );
      }
    } catch (_) {}
  }

  Future<bool> syncCurrentDevice({
    required AuthSession session,
    String? locale,
    bool force = false,
  }) async {
    if (kIsWeb) return false;
    if (_syncInFlight) {
      return false;
    }
    _syncInFlight = true;
    late bool synced;
    try {
      synced = await _syncCurrentDevice(
        session: session,
        locale: locale,
        force: force,
      );
    } finally {
      _syncInFlight = false;
    }
    if (synced && _registeredScope != api.currentScope) {
      return syncCurrentDevice(session: session, locale: locale, force: true);
    }
    return synced;
  }

  Future<bool> _syncCurrentDevice({
    required AuthSession session,
    String? locale,
    bool force = false,
  }) async {
    final settings = await messaging.getNotificationSettings();

    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!authorized) {
      _pushLog(
        'notification permission not granted (${settings.authorizationStatus})',
      );
      return false;
    }

    if (_isApplePushPlatform) {
      final apnsToken = await _waitForApnsToken();
      if (apnsToken == null) {
        _apnsSyncPending = true;
        return false;
      }
    }

    final token = await getFcmToken();
    final fcmToken = token?.trim() ?? '';

    if (fcmToken.isEmpty) {
      _pushLog('FCM token unavailable');
      return false;
    }

    _apnsSyncPending = false;

    await registerTokenWithBackend(
      session: session,
      token: fcmToken,
      locale: locale,
      force: force,
    );

    return true;
  }

  Future<void> deactivateCurrentDevice() async {
    if (kIsWeb) return;

    final token = await getFcmToken();

    if ((token ?? '').isNotEmpty) {
      await api.deactivateDeviceToken(token: token!);
    }

    await storage.clearLastRegisteredToken();
  }

  void dispose() {
    unawaited(_onMessageSub?.cancel());
    unawaited(_onMessageOpenedSub?.cancel());
    unawaited(_onTokenRefreshSub?.cancel());
    _onMessageSub = null;
    _onMessageOpenedSub = null;
    _onTokenRefreshSub = null;
    _displayedIds.clear();
    _initialized = false;
    _localNotificationsReady = false;
    _apnsSyncPending = false;
    _syncInFlight = false;
  }
}
