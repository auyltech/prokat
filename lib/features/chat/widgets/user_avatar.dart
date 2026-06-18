import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? firstName;
  final String? lastName;
  final String? fullName; // Optional fallback if names aren't split
  final double radius;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.firstName,
    this.lastName,
    this.fullName,
    this.radius = 18,
    this.textStyle,
  });

  /// Extracts up to 2 initials from the available name strings
  String _getInitials() {
    final fName = firstName?.trim() ?? '';
    final lName = lastName?.trim() ?? '';

    if (fName.isNotEmpty || lName.isNotEmpty) {
      final firstInitial = fName.isNotEmpty ? fName[0] : '';
      final lastInitial = lName.isNotEmpty ? lName[0] : '';
      return '$firstInitial$lastInitial'.toUpperCase();
    }

    // Fallback to parsing fullName if individual fields are empty
    final parsedFull = fullName?.trim() ?? '';
    if (parsedFull.isNotEmpty) {
      final parts = parsedFull.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }

    return 'U'; // System default fallback (User)
  }

  /// Generates a deterministic color based on the initials so the user
  /// always gets the same background color assignment.
  Color _getBackgroundColor(String initials) {
    if (initials == 'U') return Colors.grey.shade400;

    final int hash = initials.hashCode;
    final List<Color> avatarColors = [
      Colors.blue.shade600,
      Colors.teal.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.pink.shade600,
      Colors.purple.shade600,
      Colors.indigo.shade600,
    ];

    return avatarColors[hash.abs() % avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final initials = _getInitials();

    // Automatically size text proportionally to the radius container
    final defaultTextStyle = TextStyle(
      fontSize: radius * 0.8,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: hasImage
          ? Colors.transparent
          : _getBackgroundColor(initials),
      backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
      onBackgroundImageError: hasImage
          ? (exception, stackTrace) {
              // Gracefully handles broken network URLs in production environments
            }
          : null,
      child: hasImage
          ? null
          : Text(initials, style: textStyle ?? defaultTextStyle, maxLines: 1),
    );
  }
}
