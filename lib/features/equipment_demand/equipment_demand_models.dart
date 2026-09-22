class DemandConfig {
  final bool enabled;
  final String? campaignId;
  final bool hasResponded;

  const DemandConfig({
    required this.enabled,
    this.campaignId,
    required this.hasResponded,
  });
  const DemandConfig.disabled()
    : enabled = false,
      campaignId = null,
      hasResponded = false;

  factory DemandConfig.fromJson(dynamic json) {
    if (json is! Map) return const DemandConfig.disabled();
    final enabled = json['enabled'] == true;
    final campaignId = json['campaignId'];
    if (!enabled || campaignId is! String || campaignId.isEmpty) {
      return const DemandConfig.disabled();
    }
    return DemandConfig(
      enabled: true,
      campaignId: campaignId,
      hasResponded: json['hasResponded'] == true,
    );
  }

  bool get shouldShow => enabled && campaignId != null && !hasResponded;
  DemandConfig markResponded(String id) => campaignId == id
      ? DemandConfig(
          enabled: enabled,
          campaignId: campaignId,
          hasResponded: true,
        )
      : this;
}

class DemandOption {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;

  const DemandOption({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory DemandOption.fromJson(dynamic json) {
    if (json is! Map || json['id'] is! String || json['name'] is! String) {
      throw const FormatException('Invalid demand option');
    }
    return DemandOption(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] is String
          ? json['description'] as String
          : null,
      imageUrl: json['imageUrl'] is String ? json['imageUrl'] as String : null,
    );
  }
}

class DemandOtherOption {
  final String name;
  final String? imageUrl;

  const DemandOtherOption({required this.name, this.imageUrl});

  factory DemandOtherOption.fromJson(dynamic json) {
    if (json is! Map || json['name'] is! String) {
      throw const FormatException('Invalid demand other option');
    }
    return DemandOtherOption(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] is String ? json['imageUrl'] as String : null,
    );
  }
}

class DemandForm {
  final String campaignId;
  final List<DemandOption> options;
  final bool allowOther;
  final DemandOtherOption? other;

  const DemandForm({
    required this.campaignId,
    required this.options,
    this.allowOther = false,
    this.other,
  });
}

class DemandApiException implements Exception {
  final String? code;
  final String message;
  const DemandApiException(this.message, {this.code});
}
