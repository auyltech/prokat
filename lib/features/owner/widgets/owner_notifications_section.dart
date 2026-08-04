import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/settings_switch_tile.dart';
import 'package:prokat/features/owner/models/owner_notification_preferences.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';

class OwnerNotificationsSection extends ConsumerStatefulWidget {
  final OwnerNotificationPreferences initialValue;
  final Future<void> Function()? onPushAuthorized;

  const OwnerNotificationsSection({
    super.key,
    required this.initialValue,
    this.onPushAuthorized,
  });

  @override
  ConsumerState<OwnerNotificationsSection> createState() =>
      _OwnerNotificationsSectionState();
}

class _OwnerNotificationsSectionState
    extends ConsumerState<OwnerNotificationsSection>
    with WidgetsBindingObserver {
  late OwnerNotificationPreferences _preferences;

  NotificationSettings? _notificationSettings;
  bool _loadingPermission = true;
  String? _savingPreference;

  Color get _ownerColor => AppColors.teal800;

  Color get _ownerBackground => _ownerColor.withValues(alpha: 0.15);

  bool get _pushEnabled {
    final status = _notificationSettings?.authorizationStatus;

    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<void> _refreshAndSyncPermission() async {
    await _refreshPermission();

    if (_pushEnabled) {
      await widget.onPushAuthorized?.call();
    }
  }

  @override
  void initState() {
    super.initState();

    _preferences = widget.initialValue;
    WidgetsBinding.instance.addObserver(this);

    _refreshPermission();
  }

  @override
  void didUpdateWidget(OwnerNotificationsSection oldWidget) {
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

  Future<void> _refreshPermission() async {
    if (mounted) {
      setState(() {
        _loadingPermission = true;
      });
    }

    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();

      if (!mounted) return;

      setState(() {
        _notificationSettings = settings;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingPermission = false;
        });
      }
    }
  }

  Future<void> _managePushPermission() async {
    final status = _notificationSettings?.authorizationStatus;

    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional ||
        status == AuthorizationStatus.denied) {
      await openAppSettings();
      return;
    }

    setState(() {
      _loadingPermission = true;
    });

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
    } finally {
      await _refreshAndSyncPermission();
    }
  }

  String get _permissionTitle {
    if (_loadingPermission) {
      return 'Checking permission';
    }

    return switch (_notificationSettings?.authorizationStatus) {
      AuthorizationStatus.authorized => 'Enabled in device settings',
      AuthorizationStatus.provisional => 'Enabled quietly',
      AuthorizationStatus.denied => 'Blocked in device settings',
      AuthorizationStatus.notDetermined => 'Permission not requested',
      null => 'Permission unavailable',
    };
  }

  Future<void> _updatePreference({
    required String key,
    required OwnerNotificationPreferences nextValue,
  }) async {
    if (_savingPreference != null) return;

    final previousValue = _preferences;

    setState(() {
      _preferences = nextValue;
      _savingPreference = key;
    });

    final saved = await ref
        .read(ownerRegistrationMutationProvider.notifier)
        .updateOwnerNotificationSettings(nextValue);

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
          icon: Icons.notifications_outlined,
          iconColor: _ownerColor,
          iconBgColor: _ownerBackground,
          title: 'Push notifications',
          subtitle: _permissionTitle,
          value: _pushEnabled,
          isLoading: _loadingPermission,
          onTap: _loadingPermission ? null : _managePushPermission,
          onChanged: (_) {
            _managePushPermission();
          },
        ),

        const SizedBox(height: 16),

        SettingsSwitchTile(
          icon: Icons.campaign_outlined,
          iconColor: _ownerColor,
          iconBgColor: _ownerBackground,
          title: 'Requests and offers',
          subtitle: 'New rental requests, offer decisions and negotiations',
          value: _preferences.requestsAndOffers,
          isLoading: _savingPreference == 'requestsAndOffers',
          onChanged: (value) {
            _updatePreference(
              key: 'requestsAndOffers',
              nextValue: _preferences.copyWith(requestsAndOffers: value),
            );
          },
        ),

        const SizedBox(height: 16),

        SettingsSwitchTile(
          icon: Icons.assignment_outlined,
          iconColor: _ownerColor,
          iconBgColor: _ownerBackground,
          title: 'Orders and work progress',
          subtitle: 'Confirmations, cancellations and work-status changes',
          value: _preferences.ordersAndWork,
          isLoading: _savingPreference == 'ordersAndWork',
          onChanged: (value) {
            _updatePreference(
              key: 'ordersAndWork',
              nextValue: _preferences.copyWith(ordersAndWork: value),
            );
          },
        ),

        const SizedBox(height: 16),

        SettingsSwitchTile(
          icon: Icons.chat_bubble_outline,
          iconColor: _ownerColor,
          iconBgColor: _ownerBackground,
          title: 'Messages',
          subtitle: 'New client and negotiation messages',
          value: _preferences.messages,
          isLoading: _savingPreference == 'messages',
          onChanged: (value) {
            _updatePreference(
              key: 'messages',
              nextValue: _preferences.copyWith(messages: value),
            );
          },
        ),

        const SizedBox(height: 16),

        SettingsSwitchTile(
          icon: Icons.verified_outlined,
          iconColor: _ownerColor,
          iconBgColor: _ownerBackground,
          title: 'Equipment and verification',
          subtitle: 'Equipment moderation, documents and profile status',
          value: _preferences.equipmentAndVerification,
          isLoading: _savingPreference == 'equipmentAndVerification',
          onChanged: (value) {
            _updatePreference(
              key: 'equipmentAndVerification',
              nextValue: _preferences.copyWith(equipmentAndVerification: value),
            );
          },
        ),

        const SizedBox(height: 16),

        SettingsSwitchTile(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: _ownerColor,
          iconBgColor: _ownerBackground,
          title: 'Balance alerts',
          subtitle: 'Low balance, top-up and payment-status alerts',
          value: _preferences.balanceAlerts,
          isLoading: _savingPreference == 'balanceAlerts',
          onChanged: (value) {
            _updatePreference(
              key: 'balanceAlerts',
              nextValue: _preferences.copyWith(balanceAlerts: value),
            );
          },
        ),

        const SizedBox(height: 16),

        SettingsSwitchTile(
          icon: Icons.event_available_outlined,
          iconColor: _ownerColor,
          iconBgColor: _ownerBackground,
          title: 'Reminders and reviews',
          subtitle: 'Upcoming rentals and review reminders',
          value: _preferences.remindersAndReviews,
          isLoading: _savingPreference == 'remindersAndReviews',
          onChanged: (value) {
            _updatePreference(
              key: 'remindersAndReviews',
              nextValue: _preferences.copyWith(remindersAndReviews: value),
            );
          },
        ),

        const SizedBox(height: 20),

        _RequiredOwnerNoticesTile(
          color: _ownerColor,
          backgroundColor: _ownerBackground,
        ),
      ],
    );
  }
}

class _RequiredOwnerNoticesTile extends StatelessWidget {
  final Color color;
  final Color backgroundColor;

  const _RequiredOwnerNoticesTile({
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.security_outlined, color: color, size: 30),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service and safety notices',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Security, account restrictions and urgent platform notices',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Tooltip(
          message: 'These notices are always available in the app.',
          child: Icon(
            Icons.lock_outline_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
