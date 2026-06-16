import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/billing/state/billing_service.dart';
import 'package:prokat/features/billing/state/billing_state.dart';

class BillingNotifier extends StateNotifier<BillingState> {
  final BillingService api;

  BillingNotifier(this.api) : super(BillingState());

  Future<void> loadDashboard() async {
    await Future.wait([
      getOwnerBalance(),
      getPricingTiers(),
      getOwnerTransactions(),
      getVolumeDiscounts(),
    ]);
  }

  Future<void> getOwnerBalance() async {
    state = state.copyWith(isBalanceLoading: true);

    try {
      final result = await api
          .getOwnerBalance(); // Single response model wrapper

      if (result.success) {
        // Clear errors for this key on success
        final updatedErrors = Map<String, String>.from(state.errors)
          ..remove('balance');

        state = state.copyWith(
          isBalanceLoading: false,
          accountBalance: () => result.data,
          errors: updatedErrors,
        );
      }

      state = state.copyWith(isBalanceLoading: false);
    } catch (e) {
      final updatedErrors = Map<String, String>.from(state.errors)
        ..['balance'] = e.toString();
      state = state.copyWith(isBalanceLoading: false, errors: updatedErrors);
    }
  }

  Future<void> getOwnerTransactions() async {
    state = state.copyWith(isTransactionsLoading: true);

    final result = await api.getOwnerTransactions();
    final updatedErrors = Map<String, String>.from(state.errors);

    if (result.success && result.data != null) {
      updatedErrors.remove('transactions');
      state = state.copyWith(
        isTransactionsLoading: false,
        transactions: result.data,
        errors: updatedErrors,
      );
    } else {
      updatedErrors['transactions'] = result.message;
      state = state.copyWith(
        isTransactionsLoading: false,
        errors: updatedErrors,
      );
    }
  }

  Future<void> getPricingTiers() async {
    state = state.copyWith(isTiersLoading: true);

    final result = await api.getPricingTiers();
    final updatedErrors = Map<String, String>.from(state.errors);

    if (result.success && result.data != null) {
      updatedErrors.remove('pricingTiers');
      state = state.copyWith(
        isTiersLoading: false,
        pricingTiers: result.data,
        errors: updatedErrors,
      );
    } else {
      updatedErrors['pricingTiers'] = result.message;
      state = state.copyWith(isTiersLoading: false, errors: updatedErrors);
    }
  }

  Future<void> getVolumeDiscounts() async {
    state = state.copyWith(isDiscountsLoading: true);

    final result = await api.getVolumeDiscounts();
    final updatedErrors = Map<String, String>.from(state.errors);

    if (result.success && result.data != null) {
      updatedErrors.remove('volumeDiscounts');
      state = state.copyWith(
        isDiscountsLoading: false,
        volumeDiscounts: result.data,
        errors: updatedErrors,
      );
    } else {
      updatedErrors['volumeDiscounts'] = result.message;
      state = state.copyWith(isDiscountsLoading: false, errors: updatedErrors);
    }
  }

  Future<bool> topUpBalance({required String id}) async {
    state = state.copyWith(isSubmitting: true);

    final result = await api.topUpBalance(id: id);
    final updatedErrors = Map<String, String>.from(state.errors);

    if (result.success) {
      updatedErrors.remove('topUp');
      state = state.copyWith(isSubmitting: false, errors: updatedErrors);

      // Refresh the balance view after a successful top-up
      await getOwnerBalance();

      return true;
    } else {
      updatedErrors['topUp'] = result.message;
      state = state.copyWith(isSubmitting: false, errors: updatedErrors);
      return false;
    }
  }
}
