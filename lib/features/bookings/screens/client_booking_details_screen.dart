import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientBookingDetailsScreen extends StatelessWidget {
  final String? bookingId;

  const ClientBookingDetailsScreen({super.key, this.bookingId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(body: Center(child: Text(l10n.clientBookingDetails)));
  }
}
