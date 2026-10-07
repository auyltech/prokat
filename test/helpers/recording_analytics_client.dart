import 'package:prokat/core/analytics/analytics_client.dart';

class RecordedAnalyticsEvent {
  const RecordedAnalyticsEvent(this.name, this.params);

  final String name;
  final Map<String, Object> params;
}

class RecordingAnalyticsClient implements AnalyticsClient {
  RecordingAnalyticsClient({this.throwOnCall = false});

  final bool throwOnCall;

  final events = <RecordedAnalyticsEvent>[];
  final userIds = <String?>[];
  final userProperties = <MapEntry<String, String?>>[];
  final screens = <String>[];
  final collectionEnabled = <bool>[];

  void _maybeThrow() {
    if (throwOnCall) throw StateError('analytics client failure');
  }

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {
    _maybeThrow();
    events.add(RecordedAnalyticsEvent(name, Map.of(params)));
  }

  @override
  Future<void> setUserId(String? id) async {
    _maybeThrow();
    userIds.add(id);
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    _maybeThrow();
    userProperties.add(MapEntry(name, value));
  }

  @override
  Future<void> logScreenView(String screenName) async {
    _maybeThrow();
    screens.add(screenName);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    _maybeThrow();
    collectionEnabled.add(enabled);
  }
}
