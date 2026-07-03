import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RequestStatusBadge extends StatelessWidget {
  final RequestStatus status;
  final OwnerRequestState? requestState;
  final AppMode mode;

  const RequestStatusBadge({
    super.key,
    required this.status,
    this.requestState,
    required this.mode,
  });

  Color get color {
    switch (status) {
      case RequestStatus.created:
      case RequestStatus.viewed:
      case RequestStatus.responded:
        return Color.fromARGB(255, 32, 57, 141);
      case RequestStatus.accepted:
        return const Color.fromARGB(255, 0, 121, 4);
      case RequestStatus.cancelled:
        return Color.fromARGB(255, 179, 0, 0);
      case RequestStatus.expired:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String statusText = "";
    final currentRequestState = requestState;

    if (mode == AppMode.ownerMode && currentRequestState != null) {
      statusText = getOwnerRequestStatus(currentRequestState, l10n: l10n);
    } else {
      statusText = getRequestStatus(status, l10n: l10n);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
