import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// App bar title for the owner request inbox. Depends on which groups the
/// owner actually has in the fleet.
class OwnerRequestsTitle extends ConsumerWidget {
  const OwnerRequestsTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Text(l10n.rentalRequests);
  }
}
