import 'package:prokat/core/utils/parse.dart';

enum TransactionType { topup, consumption, freecredit, refund, adjsutment }

TransactionType parseTransactionType(dynamic value) {
  if (value == null) {
    throw const FormatException("Transaction type cannot be null");
  }

  final normalized = value.toString().trim().toLowerCase();

  for (final type in TransactionType.values) {
    if (type.name.toLowerCase() == normalized) return type;
  }

  throw FormatException("Unknown TransactionType received: $value");
}

class TransactionModel {
  final TransactionType type;
  final int seconds;
  final DateTime createdAt;

  TransactionModel({
    required this.type,
    required this.seconds,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    try {
      return TransactionModel(
        type: parseTransactionType(json['type']),
        seconds: parseInt(json['seconds'], fieldName: 'seconds'),
        createdAt: parseDateTime(json['createdAt'], fieldName: 'createdAt'),
      );
    } catch (e, stackTrace) {
      throw FormatException('Failed to parse TransactionModel: $e', stackTrace);
    }
  }

  static List<TransactionModel> fromJsonList(dynamic jsonList) {
    if (jsonList is! List) return [];

    final List<TransactionModel> validTransactions = [];

    for (final item in jsonList) {
      if (item is! Map<String, dynamic>) {
        continue; // Skip if item structure is invalid
      }

      try {
        validTransactions.add(TransactionModel.fromJson(item));
      } catch (error) {}
    }

    return validTransactions;
  }
}
