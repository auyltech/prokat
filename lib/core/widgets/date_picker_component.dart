import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerComponent extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int daysRange; // Your 'x' days parameter
  final bool isRequired;

  const DatePickerComponent({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysRange = 7,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Normalize today's date (remove time components)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 2. Generate the array of the next X days
    final List<DateTime> dateRange = List.generate(
      daysRange,
      (index) => today.add(Duration(days: index)),
    );

    // 3. Check if the initial selected date is an invalid past date
    final bool hasPastError =
        selectedDate != null &&
        DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
        ).isBefore(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Horizontal Scroll Timeline
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            children: [
              // 4. Render error box on the left if selected date is before today
              if (hasPastError)
                _buildDateButton(
                  date: selectedDate!,
                  isSelected: true,
                  isError: true,
                  onTap: () {},
                ),

              // 5. Render the valid upcoming days
              ...dateRange.map((date) {
                final bool isSelected =
                    selectedDate != null &&
                    selectedDate!.year == date.year &&
                    selectedDate!.month == date.month &&
                    selectedDate!.day == date.day;

                return _buildDateButton(
                  date: date,
                  isSelected: isSelected,
                  isError: false,
                  onTap: () => onDateSelected(date),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required DateTime date,
    required bool isSelected,
    required bool isError,
    required VoidCallback onTap,
  }) {
    // Styling states based on selection and error parameters
    final Color backgroundColor = isError
        ? Colors.red.shade100
        : (isSelected ? Colors.blue : Colors.grey.shade100);

    final Color borderColor = isError
        ? Colors.red
        : (isSelected ? Colors.blue : Colors.grey.shade300);

    final Color textColor = isError
        ? Colors.red.shade900
        : (isSelected ? Colors.white : Colors.black87);

    final Color subTextColor = isError
        ? Colors.red.shade700
        : (isSelected ? Colors.white70 : Colors.black54);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 70,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Weekday shorthand (e.g., Mon, Tue)
                Text(
                  DateFormat('E').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: subTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Day number (e.g., 12, 13)
                Text(
                  DateFormat('d').format(date),
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
