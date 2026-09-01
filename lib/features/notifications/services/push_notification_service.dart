import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';
import 'package:prokat/features/notifications/services/notification_api_service.dart';
import 'package:prokat/features/notifications/services/notification_local_storage.dart';
import 'package:prokat/features/notifications/services/notification_navigation_service.dart';
import 'package:prokat/features/notifications/utils/chat_push_tag.dart';

class PushNotificationService {
  static const String _androidChannelId = 'prokat_notifications';

  final FirebaseMessaging messaging;
  final FlutterLocalNotificationsPlugin localNotifications;
  final NotificationApiService api;
  final NotificationLocalStorage storage;
  final NotificationNavigationService navigation;
  final void Function(AppNotification notification) onIncoming;
  final bool Function(String id)? shouldSuppressDisplay;
  final String Function()? currentLocale;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  bool _initialized = false;

  PushNotificationService({
    required this.messaging,
    required this.localNotifications,
    required this.api,
    required this.storage,
    required this.navigation,
    required this.onIncoming,
    this.shouldSuppressDisplay,
    this.currentLocale,
  });

  Future<void> initialize({required AuthSession session}) async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (!kIsWeb) {
        await _initLocalNotifications();
      }
    } catch (_) {
      // Best-effort: local notifications shouldn't crash startup.
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
    } catch (_) {
      // Best-effort: missing OS permission should not crash startup.
    }

    // Register this device only when OS permission is granted.
    try {
      await syncCurrentDevice(session: session);
    } catch (_) {
      // Best-effort: push setup should not crash startup.
    }

    // Future token changes are also permission-gated.
    try {
      listenForTokenRefresh(session: session);
    } catch (_) {}

    try {
      handleForegroundMessages();
    } catch (_) {}

    try {
      handleBackgroundNotificationTap();
    } catch (_) {}

    try {
      await handleTerminatedNotificationTap();
    } catch (_) {}
  }

  Future<String?> getFcmToken() async {
    if (kIsWeb) return null;
    return messaging.getToken();
  }

  Future<void> registerTokenWithBackend({
    required AuthSession session,
    required String token,
    String? locale,
    bool force = false,
  }) async {
    if (kIsWeb) return;
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) return;

    final userId = session.user?.id ?? session.user?.phoneNumber;
    final resolvedLocale =
        (locale ?? currentLocale?.call() ?? '').trim().toLowerCase();

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
        !localeChanged) {
      return;
    }

    final platform = _platformName();

    await api.registerDeviceToken(
      token: normalizedToken,
      platform: platform,
      metadata: resolvedLocale.isEmpty ? null : {'locale': resolvedLocale},
    );

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

        if (!authorized) return;

        await registerTokenWithBackend(session: session, token: token);
      } catch (_) {
        // Best-effort.
      }
    });
  }

  void handleForegroundMessages() {
    unawaited(_onMessageSub?.cancel());
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      final notification = _toAppNotification(message);
      if (notification == null) return;

      final id = notification.id.trim();
      final suppress =
          id.isNotEmpty && (shouldSuppressDisplay?.call(id) ?? false);

      onIncoming(notification);

      // Local notification (Phase 1): show something visible.
      try {
        if (suppress) {
          return;
        }
        await _showLocalNotification(notification);
      } catch (_) {}
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

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
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
        importance: Importance.high,
      );

      final androidPlugin = localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    final chatId = notification.chatId;
    final tag = chatId == null ? null : chatPushTag(chatId);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        'Notifications',
        channelDescription: 'Prokat notifications',
        importance: Importance.high,
        priority: Priority.high,
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

    final settings = await messaging.getNotificationSettings();

    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!authorized) {
      return false;
    }

    final token = await getFcmToken();

    if ((token ?? '').trim().isEmpty) {
      return false;
    }

    await registerTokenWithBackend(
      session: session,
      token: token!,
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
    _initialized = false;
  }
}
