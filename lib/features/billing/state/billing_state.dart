import 'package:flutter/material.dart';
import 'package:prokat/features/billing/models/account_balance_model.dart';
import 'package:prokat/features/billing/models/pricing_tier_model.dart';
import 'package:prokat/features/billing/models/transaction_model.dart';
import 'package:prokat/features/billing/models/volume_discount_model.dart';

class BillingState {
  // Granular loading states
  final bool isBalanceLoading;
  final bool isTiersLoading;
  final bool isTransactionsLoading;
  final bool isDiscountsLoading;
  final bool isSubmitting;

  // Feature-specific data fields
  final AccountBalanceModel? accountBalance;
  final List<PricingTierModel> pricingTiers;
  final List<TransactionModel> transactions;
  final List<VolumeDiscountModel> volumeDiscounts;

  // Comprehensive Error Registry (Key: Feature Name, Value: Error Message)
  final Map<String, String> errors;

  BillingState({
    this.isBalanceLoading = false,
    this.isTiersLoading = false,
    this.isTransactionsLoading = false,
    this.isDiscountsLoading = false,
    this.isSubmitting = false,
    this.accountBalance,
    this.pricingTiers = const [],
    this.transactions = const [],
    this.volumeDiscounts = const [],
    this.errors = const {},
  });

  // ==========================================
  // Business Logic Derived Getters
  // ==========================================

  /// Returns true if the account has positive remaining balance time.
  bool get hasAvailableCredit {
    final remaining = accountBalance?.secondsRemaining;
    if (remaining == null) return false;
    return remaining > 0;
  }

  /// Converts remaining seconds cleanly to full minutes for the main display counter
  int get minutesRemaining =>
      ((accountBalance?.secondsRemaining ?? 0) / 60).floor();

  /// Converts the backend burn rate (seconds/hr) to an intuitive UI display (minutes/hr)
  int get burnRateMinutesPerHour =>
      ((accountBalance?.burnRateSecondsPerHour ?? 0) / 60).round();

  int getDailyCost(num onlineCount) {
    final foundDiscount = volumeDiscounts
        .where((item) => item.onlineCount == onlineCount)
        .firstOrNull;

    if (foundDiscount != null) {
      return foundDiscount.costPerMinute * 24;
    }

    return 0;
  }

  int getReminaingSeconds(num onlineCount) {
    final foundDiscount = volumeDiscounts
        .where((item) => item.onlineCount == onlineCount)
        .firstOrNull;

    if (foundDiscount == null) {
      return 0;
    }

    return (((accountBalance?.secondsRemaining ?? 0) /
            (foundDiscount.costPerMinute / 60))
        .round());
  }

  int getBurnRate(num onlineCount) {
    return 0;
  }

  /// Checks if any machine is currently consuming credit
  bool get hasActiveBurn => burnRateMinutesPerHour > 0;

  /// Dynamically computes the UI warning colors based on remaining credit metrics
  Color get balanceThemeColor {
    if (!hasAvailableCredit) return Colors.red;
    if (isRunningLow(thresholdInMinutes: 30)) return Colors.orange;
    return Colors.blue; // Normal operational color
  }

  /// Formats the estimated time when the machines will run out of power completely
  String get formattedExhaustionTime {
    final expiry = accountBalance?.estimatedExhaustionAt;

    if (expiry == null || !hasActiveBurn) return "No active depletion";

    // Example format: 14:35 (or use intl package standard: DateFormat.Hm().format(expiry))
    return "${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}";
  }

  /// Returns true if remaining seconds drop below your warning threshold (e.g., 30 minutes).
  bool isRunningLow({int thresholdInMinutes = 30}) {
    final remaining = accountBalance?.secondsRemaining;
    if (remaining == null) return false;

    final thresholdInSeconds = thresholdInMinutes * 60;
    return remaining > 0 && remaining <= thresholdInSeconds;
  }

  /// Global state loading indicator fallback
  bool get isAnyComponentLoading =>
      isBalanceLoading ||
      isTiersLoading ||
      isTransactionsLoading ||
      isDiscountsLoading;

  // ==========================================
  // 🔄 Deep Copy Engine
  // ==========================================
  BillingState copyWith({
    bool? isBalanceLoading,
    bool? isTiersLoading,
    bool? isTransactionsLoading,
    bool? isDiscountsLoading,
    bool? isSubmitting,
    AccountBalanceModel? Function()? accountBalance,
    List<PricingTierModel>? pricingTiers,
    List<TransactionModel>? transactions,
    List<VolumeDiscountModel>? volumeDiscounts,
    Map<String, String>? errors,
  }) {
    return BillingState(
      isBalanceLoading: isBalanceLoading ?? this.isBalanceLoading,
      isTiersLoading: isTiersLoading ?? this.isTiersLoading,
      isTransactionsLoading:
          isTransactionsLoading ?? this.isTransactionsLoading,
      isDiscountsLoading: isDiscountsLoading ?? this.isDiscountsLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      accountBalance: accountBalance != null
          ? accountBalance()
          : this.accountBalance,
      pricingTiers: pricingTiers ?? this.pricingTiers,
      transactions: transactions ?? this.transactions,
      volumeDiscounts: volumeDiscounts ?? this.volumeDiscounts,
      errors: errors ?? this.errors,
    );
  }
}
