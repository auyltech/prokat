import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:prokat/core/analytics/analytics_client.dart';

class FirebaseAnalyticsClient implements AnalyticsClient {
  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (_) {}
  }

  @override
  Future<void> setUserId(String? id) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance.setUserId(id: id);
    } catch (_) {}
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance.setUserProperty(
        name: name,
        value: value,
      );
    } catch (_) {}
  }

  @override
  Future<void> logScreenView(String screenName) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
    } catch (_) {}
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {}
  }
}
