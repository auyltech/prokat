import 'package:flutter/material.dart';

class ChatTileSkeleton extends StatelessWidget {
  final int index;
  const ChatTileSkeleton({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
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
