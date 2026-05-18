import 'package:flutter/material.dart';

class OwnerPaymentsScreen extends StatelessWidget {
  const OwnerPaymentsScreen({super.key});

  /// Example values (replace with real state)
  final int balanceMinutes = 5760; // = 4 days
  final int balanceKzt = 1000;
  final int equipmentCount = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final humanReadable = _formatMinutes(balanceMinutes);

    final List<int> weeklyConsumption = [120, 150, 80, 200, 180, 450, 310];
    final List<Map<String, dynamic>> paymentHistoryExamples = [
      {
        'title': 'Full Month Package',
        'amount': '5,000 ₸',
        'date': '01 Nov, 10:00',
        'method': 'Kaspi.kz',
        'packageId': 'pkg_month', // Useful for the "Repeat" logic
      },
      {
        'title': '10 Days Package',
        'amount': '2,200 ₸',
        'date': '21 Oct, 16:45',
        'method': 'Manual',
        'packageId': 'pkg_10d',
      },
      {
        'title': '5 Days Package',
        'amount': '1,200 ₸',
        'date': '15 Oct, 09:12',
        'method': 'Kaspi.kz',
        'packageId': 'pkg_5d',
      },
      {
        'title': '1 Day Package',
        'amount': '300 ₸',
        'date': '14 Oct, 23:55',
        'method': 'Kaspi.kz',
        'packageId': 'pkg_1d',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Payments & Balance")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Balance Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text("Total Balance", style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(
                  "1,234 min",
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  "≈ $humanReadable for 2 equipment", // Human-friendly calculation
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 32),
                Text(
                  "370.2 KZT", // Value in local currency
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _usageCard(context, 4, 300),

          const SizedBox(height: 16),
          _quickTopUpTile(context, () {}),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Billing Tiers",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Badge(
                      label: Text("Save 15%"),
                      backgroundColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _tierRow(
                  "1st Equipment",
                  "300 KZT/day",
                  isCurrent: true,
                  colorScheme: colorScheme,
                ),
                _tierRow(
                  "2nd Equipment",
                  "250 KZT/day",
                  isCurrent: true,
                  colorScheme: colorScheme,
                ),
                _tierRow(
                  "3rd+ Equipment",
                  "200 KZT/day",
                  isCurrent: false,
                  colorScheme: colorScheme,
                ), // Future discount
              ],
            ),
          ),

          const SizedBox(height: 16),

          _consumptionChart(context, weeklyConsumption),

          const SizedBox(height: 16),

          // _activeEquipmentTile(context, "test", "123", "min", "12"),
          _paymentHistory(context, paymentHistoryExamples),
        ],
      ),
    );
  }

  Widget _paymentHistory(
    BuildContext context,
    List<Map<String, dynamic>> payments,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            "Payment History",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final payment = payments[index];
            final isKaspi = payment['method'] == 'Kaspi.kz';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // Method Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isKaspi
                          ? const Color(0xFFF14635).withValues(alpha: 0.1)
                          : colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isKaspi
                          ? Icons.account_balance_wallet_outlined
                          : Icons.handshake_outlined,
                      size: 20,
                      color: isKaspi
                          ? const Color(0xFFF14635)
                          : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${payment['date']} • ${payment['method']}",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Amount and Repeat
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        payment['amount'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => /* Trigger top-up with same package */ {},
                        child: Text(
                          "Repeat",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// ⚡ USAGE CARD
  Widget _usageCard(BuildContext context, int equipmentCount, int dailyCost) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 1. Icon Box (Matching your Fleet/Orders style)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: colorScheme.primary,
              size: 26,
            ),
          ),

          const SizedBox(width: 16),

          // 2. Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Active Equipment: $equipmentCount",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Daily cost: $dailyCost ₸",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 3. Rate Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${(dailyCost / equipmentCount).toStringAsFixed(0)} ₸/ea",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ------------------------
  /// 🧠 LOGIC HELPERS
  /// ------------------------

  String _formatMinutes(int minutes) {
    final days = minutes ~/ 1440;
    final hours = (minutes % 1440) ~/ 60;

    if (days > 0) return "$days days $hours hours";
    return "$hours hours";
  }

}

Widget _tierRow(
  String label,
  String rate, {
  required bool isCurrent,
  required ColorScheme colorScheme,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        // Status Indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isCurrent ? Colors.green : colorScheme.outlineVariant,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),

        // Label
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Rate
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrent
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rate,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isCurrent
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _quickTopUpTile(BuildContext context, VoidCallback onTap) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          colorScheme.primary,
          colorScheme.primary.withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: const Icon(Icons.add_moderator, color: Colors.white),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Running low?",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Top up minutes via Kaspi",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: colorScheme.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text(
            "Add",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

Widget _consumptionChart(BuildContext context, List<int> weeklyData) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  // Find max to scale the bars
  final maxUsage = weeklyData
      .reduce((a, b) => a > b ? a : b)
      .clamp(1, double.infinity);

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Usage Trend",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Last 7 Days",
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 120, // Fixed height for the chart area
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(weeklyData.length, (index) {
              final val = weeklyData[index];
              final percentage = val / maxUsage;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // The Bar
                  Container(
                    width: 12,
                    height: 80 * percentage, // Scales based on max value
                    decoration: BoxDecoration(
                      color: index == weeklyData.length - 1
                          ? colorScheme
                                .primary // Highlight today
                          : colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Day Label
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: index == weeklyData.length - 1
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    ),
  );
}
