import 'package:flutter/material.dart';

class TimePickerComponent extends StatelessWidget {
  final DateTime? selectedDateTime;
  final ValueChanged<DateTime> onTimeSelected;
  final int slotLengthMinutes; // Slot duration (e.g., 30, 45, 60)
  final int startHour; // Day start hour (24hr, e.g., 8)
  final int endHour; // Day end hour (24hr, e.g., 22)
  final bool isRequired;

  /// Calendar day used to build slots and to decide which times are in the past.
  /// Falls back to [selectedDateTime]'s date, then today.
  final DateTime? referenceDate;

  /// When true, slots earlier than [DateTime.now] are disabled and faded.
  final bool disablePast;

  const TimePickerComponent({
    super.key,
    required this.selectedDateTime,
    required this.onTimeSelected,
    this.slotLengthMinutes = 60, // Defaults to 1 hour slots
    this.startHour = 0, // Defaults to midnight
    this.endHour = 24, // Defaults to end of day
    this.isRequired = false,
    this.referenceDate,
    this.disablePast = true,
  });

  DateTime get _baseDate {
    final source = referenceDate ?? selectedDateTime ?? DateTime.now();
    return DateTime(source.year, source.month, source.day);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final List<DateTime> timeSlots = _generateTimeSlots(_baseDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: timeSlots.map((slotDateTime) {
              final bool isPast = disablePast && slotDateTime.isBefore(now);
              final bool isSelected =
                  !isPast &&
                  selectedDateTime != null &&
                  selectedDateTime!.hour == slotDateTime.hour &&
                  selectedDateTime!.minute == slotDateTime.minute;

              return _buildTimeButton(
                time: slotDateTime,
                isSelected: isSelected,
                isDisabled: isPast,
                onTap: isPast ? null : () => onTimeSelected(slotDateTime),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<DateTime> _generateTimeSlots(DateTime base) {
    final List<DateTime> slots = [];

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

  Widget _buildTimeButton({
    required DateTime time,
    required bool isSelected,
    required bool isDisabled,
    required VoidCallback? onTap,
  }) {
    final Color backgroundColor = isDisabled
        ? Colors.grey.shade200
        : (isSelected ? Colors.blue : Colors.grey.shade100);
    final Color borderColor = isDisabled
        ? Colors.grey.shade300
        : (isSelected ? Colors.blue : Colors.grey.shade300);
    final Color textColor = isDisabled
        ? Colors.black26
        : (isSelected ? Colors.white : Colors.black87);

    final String hourStr = time.hour.toString().padLeft(2, '0');
    final String minuteStr = time.minute.toString().padLeft(2, '0');

    return Opacity(
      opacity: isDisabled ? 0.45 : 1,
      child: Material(
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
      ),
    );
  }
}
