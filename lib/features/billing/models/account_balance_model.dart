import 'package:prokat/core/utils/parse.dart';

class AccountBalanceModel {
  final int secondsRemaining;
  final int burnRateMinutesPerHour;
  final DateTime? estimatedExhaustionAt;
  final DateTime? lastCalculatedAt;

  AccountBalanceModel({
    required this.secondsRemaining,
    this.burnRateMinutesPerHour = 0,
    this.estimatedExhaustionAt,
    this.lastCalculatedAt,
  });

  factory AccountBalanceModel.fromJson(Map<String, dynamic> json) {
    try {
      return AccountBalanceModel(
        secondsRemaining: parseInt(
          json['secondsRemaining'],
          fieldName: 'secondsRemaining',
        ),
        burnRateMinutesPerHour: parseInt(
          json['burnRateMinutesPerHour'] ?? 0,
          fieldName: 'burnRateMinutesPerHour',
        ),
        estimatedExhaustionAt: parseNullableDate(json['estimatedExhaustionAt']),
        lastCalculatedAt: parseNullableDate(json['lastCalculatedAt']),
      );
    } catch (error, stackTrace) {
      throw FormatException(
        'Failed to parse AccountBalanceModel: $error',
        stackTrace,
      );
    }
  }
}
