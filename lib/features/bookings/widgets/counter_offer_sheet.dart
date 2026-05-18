import 'package:flutter/material.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';

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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Send Counter Offer",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "New Price",
              suffixText: "KZT",
              border: OutlineInputBorder(),
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
              child: const Text("Send Offer"),
            ),
          ),
        ],
      ),
    );
  }
}
