class ClientNotificationPreferences {
  final int version;
  final bool requestsAndOffers;
  final bool orderUpdates;
  final bool workProgress;
  final bool messages;
  final bool remindersAndReviews;

  const ClientNotificationPreferences({
    this.version = 1,
    this.requestsAndOffers = true,
    this.orderUpdates = true,
    this.workProgress = true,
    this.messages = true,
    this.remindersAndReviews = true,
  });

  factory ClientNotificationPreferences.fromJson(Map<String, dynamic> json) {
    bool readBoolean(String key, {bool fallback = true}) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    final rawVersion = json['version'];

    return ClientNotificationPreferences(
      version: rawVersion is int
          ? rawVersion
          : int.tryParse(rawVersion?.toString() ?? '') ?? 1,
      requestsAndOffers: readBoolean('requestsAndOffers'),
      orderUpdates: readBoolean('orderUpdates'),
      workProgress: readBoolean('workProgress'),
      messages: readBoolean('messages'),
      remindersAndReviews: readBoolean('remindersAndReviews'),
    );
  }

  ClientNotificationPreferences copyWith({
    int? version,
    bool? requestsAndOffers,
    bool? orderUpdates,
    bool? workProgress,
    bool? messages,
    bool? remindersAndReviews,
  }) {
    return ClientNotificationPreferences(
      version: version ?? this.version,
      requestsAndOffers: requestsAndOffers ?? this.requestsAndOffers,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      workProgress: workProgress ?? this.workProgress,
      messages: messages ?? this.messages,
      remindersAndReviews: remindersAndReviews ?? this.remindersAndReviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'requestsAndOffers': requestsAndOffers,
      'orderUpdates': orderUpdates,
      'workProgress': workProgress,
      'messages': messages,
      'remindersAndReviews': remindersAndReviews,
    };
  }

  /// Use this if the backend PATCH schema does not accept `version`.
  Map<String, dynamic> toPatchJson() {
    return {
      'requestsAndOffers': requestsAndOffers,
      'orderUpdates': orderUpdates,
      'workProgress': workProgress,
      'messages': messages,
      'remindersAndReviews': remindersAndReviews,
    };
  }
}
