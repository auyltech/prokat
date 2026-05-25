import 'package:flutter/material.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CounterOfferSheet extends StatefulWidget {
  final BookingModel booking;
  
  const CounterOfferSheet({super.key, required this.booking});

  @override
  State<CounterOfferSheet> createState() => _CounterOfferSheetState();
}

class _CounterOfferSheetState extends State<CounterOfferSheet> {
  final _priceController = TextEditingController();
  String _selectedRate = "per hour";

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sendCounterOffer,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.newPrice,
              suffixText: "KZT",
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedRate,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: ["per hour", "for full job", "per day"]
                .map((rate) => DropdownMenuItem(value: rate, child: Text(rate)))
                .toList(),
            onChanged: (val) => setState(() => _selectedRate = val!),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // TODO: API Call with _priceController.text and _selectedRate
                Navigator.pop(context);
              },
              child: Text(l10n.sendOffer),
            ),
          ),
        ],
      ),
    );
  }
}
