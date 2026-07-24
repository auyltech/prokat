import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/settings_switch_tile.dart';
import 'package:prokat/features/user/models/client_notification_preferences.dart';

class ClientNotificationsSection extends StatefulWidget {
  final ClientNotificationPreferences initialValue;
  final Future<void> Function()? onPushAuthorized;

  /// Return true when the preferences were saved successfully.
  final Future<bool> Function(ClientNotificationPreferences preferences) onSave;

  const ClientNotificationsSection({
    super.key,
    required this.initialValue,
    required this.onSave,
    this.onPushAuthorized,
  });

  @override
  State<ClientNotificationsSection> createState() =>
      _ClientNotificationsSectionState();
}

class _ClientNotificationsSectionState extends State<ClientNotificationsSection>
    with WidgetsBindingObserver {
  late ClientNotificationPreferences _preferences;

  NotificationSettings? _notificationSettings;
  bool _loadingPermission = true;
  String? _savingPreference;

  @override
  void initState() {
    super.initState();

    _preferences = widget.initialValue;
    WidgetsBinding.instance.addObserver(this);

    _refreshPermission();
  }

  @override
  void didUpdateWidget(ClientNotificationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue) {
      _preferences = widget.initialValue;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAndSyncPermission();
    }
  }

  Future<void> _refreshAndSyncPermission() async {
    await _refreshPermission();

    if (_pushEnabled) {
      await widget.onPushAuthorized?.call();
    }
  }

  Future<void> _refreshPermission() async {
    setState(() {
      _loadingPermission = true;
    });

    final settings = await FirebaseMessaging.instance.getNotificationSettings();

    if (!mounted) return;

    setState(() {
      _notificationSettings = settings;
      _loadingPermission = false;
    });
  }

  Future<void> _manageNotificationPermission() async {
    final status = _notificationSettings?.authorizationStatus;

    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      await openAppSettings();
      return;
    }

    if (status == AuthorizationStatus.denied) {
      await openAppSettings();
      return;
    }

    setState(() {
      _loadingPermission = true;
    });

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    await _refreshAndSyncPermission();
  }

  String get _permissionTitle {
    if (_loadingPermission) return 'Checking permission';

    return switch (_notificationSettings?.authorizationStatus) {
      AuthorizationStatus.authorized => 'Enabled',
      AuthorizationStatus.provisional => 'Enabled quietly',
      AuthorizationStatus.denied => 'Blocked',
      AuthorizationStatus.notDetermined => 'Not enabled',
      null => 'Unavailable',
    };
  }

  Future<void> _updatePreference({
    required String key,
    required ClientNotificationPreferences nextValue,
  }) async {
    if (_savingPreference != null) return;

    final previousValue = _preferences;

    setState(() {
      _preferences = nextValue;
      _savingPreference = key;
    });

    final saved = await widget.onSave(nextValue);

    if (!mounted) return;

    setState(() {
      _savingPreference = null;

      if (!saved) {
        _preferences = previousValue;
      }
    });

    if (!saved) {
      AppSnackBar.show(
        message: 'Failed to save notification preferences.',
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _pushEnabled {
    final status = _notificationSettings?.authorizationStatus;

    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),

        SettingsSwitchTile(
          onTap: _loadingPermission ? null : _manageNotificationPermission,
          icon: Icons.notifications_outlined,
          title: 'Push notifications',
          subtitle: _permissionTitle,
          value: _pushEnabled,
          onChanged: (_) {
            _manageNotificationPermission();
          },
          isLoading: _loadingPermission,
        ),

        const SizedBox(height: 16),
        SettingsSwitchTile(
          icon: Icons.notifications_outlined,
          title: 'Rental requests and offers',
          subtitle: 'New offers, counteroffers and request updates',
          value: _preferences.requestsAndOffers,
          onChanged: (value) => _updatePreference(
            key: 'requests',
            nextValue: _preferences.copyWith(requestsAndOffers: value),
          ),
          isLoading: _savingPreference == 'requests',
        ),

        const SizedBox(height: 16),
        SettingsSwitchTile(
          icon: Icons.notifications_outlined,
          title: 'Order updates',
          subtitle: 'Confirmations, cancellations and status changes',
          value: _preferences.orderUpdates,
          isLoading: _savingPreference == 'orders',
          onChanged: (value) => _updatePreference(
            key: 'orders',
            nextValue: _preferences.copyWith(orderUpdates: value),
          ),
        ),

        const SizedBox(height: 16),

        SettingsSwitchTile(
          icon: Icons.notifications_outlined,
          title: 'Work progress',
          subtitle: 'Owner on the way, arrived, started or completed',
          value: _preferences.workProgress,
          isLoading: _savingPreference == 'work',
          onChanged: (value) => _updatePreference(
            key: 'work',
            nextValue: _preferences.copyWith(workProgress: value),
          ),
        ),

        const SizedBox(height: 16),
        SettingsSwitchTile(
          icon: Icons.notifications_outlined,
          title: 'Messages',
          subtitle: 'New chat and negotiation messages',
          value: _preferences.messages,
          isLoading: _savingPreference == 'messages',
          onChanged: (value) => _updatePreference(
            key: 'messages',
            nextValue: _preferences.copyWith(messages: value),
          ),
        ),

        const SizedBox(height: 16),

        SettingsSwitchTile(
          icon: Icons.notifications_outlined,
          title: 'Reminders and reviews',
          subtitle: 'Upcoming rentals and review reminders',
          value: _preferences.remindersAndReviews,
          isLoading: _savingPreference == 'reminders',
          onChanged: (value) => _updatePreference(
            key: 'reminders',
            nextValue: _preferences.copyWith(remindersAndReviews: value),
          ),
        ),
      ],
    );
  }
}
