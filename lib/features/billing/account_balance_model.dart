import 'package:prokat/core/utils/parse.dart';

class AccountBalanceModel {
  final int? secondsRemaining;
  final DateTime? estimatedExhaustionAt;
  final DateTime? lastCalculatedAt;

  AccountBalanceModel({
    this.secondsRemaining,
    this.estimatedExhaustionAt,
    this.lastCalculatedAt,
  });

  factory AccountBalanceModel.fromJson(Map<String, dynamic> json) {
    return AccountBalanceModel(
      secondsRemaining: parseNullableInt(json['secondsRemaining']) ?? 0,
      estimatedExhaustionAt: parseNullableDate(json['estimatedExhaustionAt']),
      lastCalculatedAt: parseNullableDate(json['lastCalculatedAt']),
    );
  }
}
