import 'package:flutter/material.dart';

class AddressEmptyState extends StatelessWidget {
  const AddressEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.location_off, size: 64),
          SizedBox(height: 16),
          Text("No equipment locations yet", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
