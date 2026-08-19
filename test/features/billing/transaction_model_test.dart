import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/billing/models/transaction_model.dart';

void main() {
  test('parseTransactionType accepts backend ADJUSTMENT wire value', () {
    expect(parseTransactionType('ADJUSTMENT'), TransactionType.adjustment);
  });

  test('TransactionModel.fromJson parses backend transaction payload', () {
    final transaction = TransactionModel.fromJson({
      'type': 'ADJUSTMENT',
      'seconds': 120,
      'createdAt': '2026-01-01T00:00:00.000Z',
    });

    expect(transaction.type, TransactionType.adjustment);
    expect(transaction.seconds, 120);
    expect(
      transaction.createdAt,
      DateTime.parse('2026-01-01T00:00:00.000Z').toLocal(),
    );
  });
}
