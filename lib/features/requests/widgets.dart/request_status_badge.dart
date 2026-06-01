import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RequestStatusBadge extends StatelessWidget {
  final String status;

  const RequestStatusBadge({super.key, required this.status});

  Color get color {
    switch (status) {
      case "CREATED": 
        return Colors.blue;
      case "VIEWED":
        return Colors.orange;
      case "ACCEPTED":
        return Colors.green;
      case "CANCELLED":
        return Colors.red;
      case "EXPIRED":
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        getRequestStatus(status, l10n: l10n),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
