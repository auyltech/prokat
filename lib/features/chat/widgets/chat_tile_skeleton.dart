import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';

class ChatTileSkeleton extends StatelessWidget {
  final int index;
  const ChatTileSkeleton({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final flow = ProkatFlowScope.maybeOf(context);
    if (flow != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: flow.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: flow.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 24, backgroundColor: flow.border),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: .75,
                    child: Container(height: 14, color: flow.border),
                  ),
                  const SizedBox(height: 10),
                  Container(height: 12, color: flow.border),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: .55,
                    child: Container(height: 12, color: flow.border),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 24.0,
      ), // Match your list tile separation
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Avatar Placeholder
          const CircleAvatar(radius: 20),

          const SizedBox(width: 12),

          // 2. Middle Block (Title & Message Subtitle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // Sender Name Line
                Container(
                  width: 130,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Last Message Subtitle Line
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 3. Right Block (Status Badge & Timestamp)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 4),
              // Timestamp Placeholder (e.g., "12:59")
              Container(
                width: 35,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Optional: Show status badge placeholder for alternating rows
              if (index % 2 == 1) ...[
                const SizedBox(height: 8),
                Container(
                  width: 70,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
