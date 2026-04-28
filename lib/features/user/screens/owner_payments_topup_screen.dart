import 'package:flutter/material.dart';

class OwnerPaymentsTopupScreen extends StatefulWidget {
  const OwnerPaymentsTopupScreen({super.key});

  @override
  State<OwnerPaymentsTopupScreen> createState() =>
      _OwnerPaymentsTopupScreenState();
}

class _OwnerPaymentsTopupScreenState extends State<OwnerPaymentsTopupScreen> {
  int? selectedIndex;

  final List<Map<String, dynamic>> packages = [
    {'title': '1 Day', 'min': 1440, 'price': 300, 'label': '1 Equipment'},
    {'title': '5 Days', 'min': 7200, 'price': 1200, 'label': 'Save 20%'},
    {'title': '10 Days', 'min': 14400, 'price': 2200, 'label': 'Save 25%'},
    {'title': 'Full Month', 'min': 43200, 'price': 5000, 'label': 'Best Value'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Top Up Minutes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- 1. Package Selection ---
          Text(
            "Select Package",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final isSelected = selectedIndex == index;
              final pkg = packages[index];
              return GestureDetector(
                onTap: () => setState(() => selectedIndex = index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pkg['title'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${pkg['price']} KZT",
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        pkg['label'],
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // --- 2. Action Buttons ---
          ElevatedButton.icon(
            onPressed: selectedIndex == null
                ? null
                : () => _payWithKaspi(packages[selectedIndex!]),
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text("Pay with Kaspi.kz"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF14635), // Kaspi Red
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _submitManualRequest(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text("Submit Manual Request (Offline Pay)"),
          ),

          const SizedBox(height: 40),

          // --- 3. Recent History / Repeat ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Payments",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(onPressed: () {}, child: const Text("View All")),
            ],
          ),
          _historyItem(context, "5 Days Package", "1,200 KZT", "24 Oct"),
          _historyItem(context, "1 Day Package", "300 KZT", "12 Oct"),
        ],
      ),
    );
  }

  Widget _historyItem(
    BuildContext context,
    String title,
    String price,
    String date,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(date, style: const TextStyle(fontSize: 12)),
        trailing: TextButton(
          onPressed: () {
            /* Repeat logic */
          },
          child: Text("Repeat", style: TextStyle(color: colorScheme.primary)),
        ),
      ),
    );
  }

  void _payWithKaspi(Map pkg) {
    // Generate Kaspi deep link logic here
    // Example: launchUrlString("https://kaspi.kz{pkg['price']}");
  }

  void _submitManualRequest() {
    // Show a dialog or navigate to a simple form
  }
}
