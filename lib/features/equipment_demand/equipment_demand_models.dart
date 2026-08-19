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
  const DemandOption({required this.id, required this.name});

  factory DemandOption.fromJson(dynamic json) {
    if (json is! Map || json['id'] is! String || json['name'] is! String) {
      throw const FormatException('Invalid demand option');
    }
    return DemandOption(id: json['id'] as String, name: json['name'] as String);
  }
}

class DemandForm {
  final String campaignId;
  final List<DemandOption> options;
  const DemandForm({required this.campaignId, required this.options});
}

class DemandApiException implements Exception {
  final String? code;
  final String message;
  const DemandApiException(this.message, {this.code});
}
