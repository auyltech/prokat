abstract interface class AnalyticsClient {
  Future<void> logEvent(String name, Map<String, Object> params);

  Future<void> setUserId(String? id);

  Future<void> setUserProperty(String name, String? value);

  Future<void> logScreenView(String screenName);

  Future<void> setCollectionEnabled(bool enabled);
}

class NoopAnalyticsClient implements AnalyticsClient {
  const NoopAnalyticsClient();

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}
