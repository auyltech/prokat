class OwnerNotificationPreferences {
  final int version;
  final bool requestsAndOffers;
  final bool ordersAndWork;
  final bool messages;
  final bool equipmentAndVerification;
  final bool balanceAlerts;
  final bool remindersAndReviews;

  const OwnerNotificationPreferences({
    this.version = 1,
    this.requestsAndOffers = true,
    this.ordersAndWork = true,
    this.messages = true,
    this.equipmentAndVerification = true,
    this.balanceAlerts = true,
    this.remindersAndReviews = true,
  });

  factory OwnerNotificationPreferences.fromJson(Map<String, dynamic> json) {
    bool readBoolean(String key, {bool fallback = true}) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    final rawVersion = json['version'];

    return OwnerNotificationPreferences(
      version: rawVersion is int
          ? rawVersion
          : int.tryParse(rawVersion?.toString() ?? '') ?? 1,
      requestsAndOffers: readBoolean('requestsAndOffers'),
      ordersAndWork: readBoolean('ordersAndWork'),
      messages: readBoolean('messages'),
      equipmentAndVerification: readBoolean('equipmentAndVerification'),
      balanceAlerts: readBoolean('balanceAlerts'),
      remindersAndReviews: readBoolean('remindersAndReviews'),
    );
  }

  OwnerNotificationPreferences copyWith({
    int? version,
    bool? requestsAndOffers,
    bool? ordersAndWork,
    bool? messages,
    bool? equipmentAndVerification,
    bool? balanceAlerts,
    bool? remindersAndReviews,
  }) {
    return OwnerNotificationPreferences(
      version: version ?? this.version,
      requestsAndOffers: requestsAndOffers ?? this.requestsAndOffers,
      ordersAndWork: ordersAndWork ?? this.ordersAndWork,
      messages: messages ?? this.messages,
      equipmentAndVerification:
          equipmentAndVerification ?? this.equipmentAndVerification,
      balanceAlerts: balanceAlerts ?? this.balanceAlerts,
      remindersAndReviews: remindersAndReviews ?? this.remindersAndReviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'requestsAndOffers': requestsAndOffers,
      'ordersAndWork': ordersAndWork,
      'messages': messages,
      'equipmentAndVerification': equipmentAndVerification,
      'balanceAlerts': balanceAlerts,
      'remindersAndReviews': remindersAndReviews,
    };
  }

  Map<String, dynamic> toPatchJson() {
    return {
      'requestsAndOffers': requestsAndOffers,
      'ordersAndWork': ordersAndWork,
      'messages': messages,
      'equipmentAndVerification': equipmentAndVerification,
      'balanceAlerts': balanceAlerts,
      'remindersAndReviews': remindersAndReviews,
    };
  }
}
