import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/settings_switch_tile.dart';
import 'package:prokat/features/user/models/client_notification_preferences.dart';
import 'package:prokat/l10n/app_localizations.dart';

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

    unawaited(_refreshPermission());
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
      unawaited(_refreshAndSyncPermission());
    }
  }

  Future<void> _refreshAndSyncPermission() async {
    await _refreshPermission();

    if (_pushEnabled) {
      await widget.onPushAuthorized?.call();
    }
  }

  Future<void> _refreshPermission() async {
    if (!Env.firebaseServicesEnabled) {
      _loadingPermission = false;
      return;
    }

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
    if (!Env.firebaseServicesEnabled) return;

    final status = _notificationSettings?.authorizationStatus;

    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional ||
        status == AuthorizationStatus.denied ||
        status == AuthorizationStatus.deniedPermanently) {
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

  String _permissionTitle(AppLocalizations l10n) {
    if (_loadingPermission) return l10n.checkingPermission;

    return switch (_notificationSettings?.authorizationStatus) {
      AuthorizationStatus.authorized => l10n.pushEnabled,
      AuthorizationStatus.provisional => l10n.pushEnabledQuietly,
      AuthorizationStatus.denied => l10n.pushBlocked,
      AuthorizationStatus.deniedPermanently => l10n.pushBlocked,
      AuthorizationStatus.notDetermined => l10n.pushNotEnabled,
      null => l10n.pushUnavailable,
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
        message: AppLocalizations.of(context)!
            .failedToSaveNotificationPreferences,
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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notifications,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),

        SettingsSwitchTile(
          onTap: _loadingPermission ? null : _manageNotificationPermission,
          icon: Icons.notifications_outlined,
          title: l10n.pushNotifications,
          subtitle: _permissionTitle(l10n),
          value: _pushEnabled,
          onChanged: (_) {
            unawaited(_manageNotificationPermission());
          },
          isLoading: _loadingPermission,
        ),

        const SizedBox(height: 16),
        SettingsSwitchTile(
          icon: Icons.notifications_outlined,
          title: l10n.notifRentalRequestsAndOffers,
          subtitle: l10n.notifRentalRequestsAndOffersSubtitle,
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
          title: l10n.notifOrderUpdates,
          subtitle: l10n.notifOrderUpdatesSubtitle,
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
          title: l10n.notifWorkProgress,
          subtitle: l10n.notifWorkProgressSubtitle,
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
          title: l10n.messages,
          subtitle: l10n.notifMessagesSubtitle,
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
          title: l10n.notifRemindersAndReviews,
          subtitle: l10n.notifRemindersAndReviewsSubtitle,
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
