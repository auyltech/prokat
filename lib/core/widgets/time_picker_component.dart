import 'package:flutter/material.dart';

class TimePickerComponent extends StatelessWidget {
  final DateTime? selectedDateTime;
  final ValueChanged<DateTime> onTimeSelected;
  final int slotLengthMinutes; // Slot duration (e.g., 30, 45, 60)
  final int startHour; // Day start hour (24hr, e.g., 8)
  final int endHour; // Day end hour (24hr, e.g., 22)
  final bool isRequired;

  const TimePickerComponent({
    super.key,
    required this.selectedDateTime,
    required this.onTimeSelected,
    this.slotLengthMinutes = 60, // Defaults to 1 hour slots
    this.startHour = 0, // Defaults to midnight
    this.endHour = 24, // Defaults to end of day
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Fallback to today's base date if no date is selected yet
    final baseDate = selectedDateTime ?? DateTime.now();

    // 2. Generate the array of full DateTime slots
    final List<DateTime> timeSlots = _generateTimeSlots(baseDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grid-like Wrapped Flow Layout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Wrap(
            spacing: 8.0, // Horizontal space between items
            runSpacing: 8.0, // Vertical space between rows
            children: timeSlots.map((slotDateTime) {
              // 3. Match exact hour and minutes for selection highlighting
              final bool isSelected =
                  selectedDateTime != null &&
                  selectedDateTime!.hour == slotDateTime.hour &&
                  selectedDateTime!.minute == slotDateTime.minute;

              return _buildTimeButton(
                time: slotDateTime,
                isSelected: isSelected,
                onTap: () => onTimeSelected(slotDateTime),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 4. Generates complete DateTime entries based on the input date
  List<DateTime> _generateTimeSlots(DateTime base) {
    final List<DateTime> slots = [];

    // Create local tracker variables based on the current active base day
    int currentMinutes = startHour * 60;
    final int endMinutes = endHour * 60;

    while (currentMinutes < endMinutes) {
      final int hour = currentMinutes ~/ 60;
      final int minute = currentMinutes % 60;

      if (hour < 24) {
        slots.add(DateTime(base.year, base.month, base.day, hour, minute));
      }

      currentMinutes += slotLengthMinutes;
    }
    return slots;
  }

  // 5. Reusable UI Button Component
  Widget _buildTimeButton({
    required DateTime time,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color backgroundColor = isSelected
        ? Colors.blue
        : Colors.grey.shade100;
    final Color borderColor = isSelected ? Colors.blue : Colors.grey.shade300;
    final Color textColor = isSelected ? Colors.white : Colors.black87;

    // Pad single digits for clean 24hr format rendering (e.g., 09:05)
    final String hourStr = time.hour.toString().padLeft(2, '0');
    final String minuteStr = time.minute.toString().padLeft(2, '0');

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          alignment: Alignment.center,
          child: Text(
            "$hourStr:$minuteStr",
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
