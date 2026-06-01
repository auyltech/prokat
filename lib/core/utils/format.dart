import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

String formatRequestTime(String date) {
  final dt = DateTime.parse(date).toLocal();
  final now = DateTime.now();

  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return "Just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
  if (diff.inHours < 24) return "${diff.inHours} h ago";

  // older → show date
  return DateFormat("d MMM, HH:mm").format(dt);
}

// String formatKZT(num amount) {
//   final formatter = NumberFormat("#,###", "en_US");
//   return "₸ ${formatter.format(amount).replaceAll(",", ",")}";
// }

String formatDate({
  DateTime? date,
  String? format = 'MMM dd',
  String? presetStyle,
}) {
  if (presetStyle != null && presetStyle.isNotEmpty) {
    if (presetStyle == "short") {
      return DateFormat('MMM dd').format(date ?? DateTime.now());
    }
    return DateFormat(presetStyle).format(date ?? DateTime.now());
  } else if (format != null && format.isNotEmpty) {
    return DateFormat(format).format(date ?? DateTime.now());
  } else {
    return DateFormat("d MMM yyyy").format(date ?? DateTime.now());
  }
}

String formatTime(BuildContext context, DateTime date) {
  return TimeOfDay.fromDateTime(date).format(context);
}

String formatDateTime(dynamic date, dynamic time) {
  final dateStr = DateFormat('MMM dd').format(date);
  if (time != null) {
    final timeStr = DateFormat('HH:mm').format(time!);
    return "$dateStr • $timeStr";
  }
  return dateStr;
}

String formatPhoneNumber(String phoneNumber) {
  // 1. Remove all non-digit characters
  String cleaned = phoneNumber.replaceAll(RegExp(r'\D'), '');

  // 2. Handle Russian formatting (usually 11 digits, starting with 7 or 8)
  // If it starts with 8, replace with 7
  if (cleaned.length == 11 && cleaned.startsWith('8')) {
    cleaned = '7${cleaned.substring(1)}';
  }

  // 3. Ensure it has 11 digits for this format
  if (cleaned.length != 11) {
    // Return original or handle error if format is invalid
    return phoneNumber;
  }

  // 4. Format: +7 111 222 3333
  return '+${cleaned[0]} ${cleaned.substring(1, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
}

String formatPrice(dynamic price) {
  final number = (price is num)
      ? price
      : (double.tryParse(price.toString()) ?? 0);

  // Custom pattern using space as a separator
  final formatter = NumberFormat("#,###", "en_US");
  String formatted = formatter.format(number).replaceAll(',', ',');

  return "₸ $formatted";
}

String getPriceRate(dynamic priceRate, {AppLocalizations? l10n}) {
  if (priceRate == null || priceRate.toString().isEmpty) {
    return "";
  }

  final temp = priceRate.toString().trim().replaceAll(" ", "_").toUpperCase();

  if (l10n != null) {
    if (temp == "PER_TRIP") return l10n.perTrip;
    if (temp == "PER_CUBIC_METER") return l10n.perM3;
    if (temp == "PER_HOUR") return l10n.perHour;
    return temp;
  }

  return temp == "PER_TRIP"
      ? "/ Trip"
      : temp == "PER_CUBIC_METER"
      ? "/ M3"
      : temp == "PER_HOUR"
      ? "/ Hour"
      : temp == "PER_DAY"
      ? "/ Day"
      : temp;
}

String getBookingStatus(dynamic status, {AppLocalizations? l10n}) {
  final temp = status.toString().trim().toUpperCase();

  if (l10n != null) {
    switch (temp) {
      case "DRAFT":
        return l10n.statusDraft;
      case "CREATED":
        return l10n.newOrder;
      case "CONFIRMED":
        return l10n.statusConfirmed;
      case "REJECTED":
        return l10n.statusRejected;
      case "WITHDRAW":
        return l10n.statusCanceled;
      case "FAILED":
        return l10n.statusCanceled;
      case "COMPLETED":
        return l10n.statusCompleted;
      default:
        return "";
    }
  }

  switch (temp) {
    case "DRAFT":
      return "Draft";
    case "CREATED":
      return "New Order";
    case "CONFIRMED":
      return "Confirmed";
    case "REJECTED":
      return "Rejected";
    case "WITHDRAW":
      return "Canceled";
    case "FAILED":
      return "Canceled";
    case "COMPLETED":
      return "Completed";
    default:
      return "";
  }
}

String getRequestStatus(dynamic status, {AppLocalizations? l10n}) {
  final temp = status.toString().trim().toUpperCase();

  if (l10n != null) {
    switch (temp) {
      case "DRAFT":
        return l10n.statusDraft;
      case "CREATED":
        return l10n.statusRequestSent;
      case "RESPONDED":
        return l10n.statusOffersReceived;
      case "ACCEPTED":
        return l10n.statusBookingCreated;
      case "CANCELLED":
        return l10n.statusCanceled;
      case "EXPIRED":
        return l10n.statusExpired;
      default:
        return "";
    }
  }

  switch (temp) {
    case "DRAFT":
      return "Draft";
    case "CREATED":
      return "Request Sent";
    case "RESPONDED":
      return "Offers Sent";
    case "ACCEPTED":
      return "Booking Created";
    case "CANCELLED":
      return "Canceled";
    case "EXPIRED":
      return "Expired";
    default:
      return "";
  }
}

String getOwnerRequestStatus(
  OwnerRequestUIState requestState, {
  AppLocalizations? l10n,
}) {
  String? stateLabel;

  switch (requestState) {
    case OwnerRequestUIState.newRequest:
      stateLabel = l10n?.newRequestBadge;
      break;
    case OwnerRequestUIState.viewed:
      stateLabel = l10n?.viewedBadge;
      break;
    case OwnerRequestUIState.offerSent:
      stateLabel = l10n?.offerSentBadge;
      break;
    case OwnerRequestUIState.accepted:
      stateLabel = l10n?.acceptedBadge;
      break;
    case OwnerRequestUIState.hidden:
      stateLabel = l10n?.hiddenBadge;
      break;
  }

  return stateLabel ?? "";
}

MaterialColor getBookingColor(dynamic status) {
  final temp = status.toString().trim().toUpperCase();
  switch (temp) {
    case "DRAFT":
      return Colors.grey;
    case "CREATED":
      return Colors.blue;
    case "CONFIRMED":
      return Colors.green;
    case "REJECTED":
      return Colors.orange;
    case "WITHDRAW":
      return Colors.red;
    case "FAILED":
      return Colors.red;
    case "COMPLETED":
      return Colors.indigo;
    default:
      return Colors.brown;
  }
}

int getRemainingMinutes(dynamic createdAt, {int totalDuration = 60}) {
  try {
    // 1. Handle Null or empty values immediately
    if (createdAt == null || createdAt == "") return 0;

    DateTime? dt;

    // 2. Determine input type and parse accordingly
    if (createdAt is DateTime) {
      dt = createdAt;
    } else if (createdAt is String) {
      dt = DateTime.tryParse(createdAt); // Safely attempts to parse ISO8601
    }

    // 3. Check if parsing failed (not a valid date string)
    if (dt == null) return 0;

    // 4. Calculate difference (handling UTC vs Local)
    final now = dt.isUtc ? DateTime.now().toUtc() : DateTime.now();
    final difference = now.difference(dt).inMinutes;

    final remaining = totalDuration - difference;

    return remaining;
    // return remaining > 0 ? remaining : 0;
  } catch (e) {
    // 5. Catch-all for any unexpected errors (e.g., out-of-range dates)
    return 0;
  }
}

Map<String, String>? getBookingMessage(dynamic bookedOn, dynamic bookedAt) {
  try {
    if (bookedOn == null) return null;

    DateTime? target = DateTime.now();

    // 2. Determine input type and parse accordingly
    if (bookedAt is DateTime) {
      target = bookedAt;
    } else if (bookedAt is String) {
      // Node/Prisma ISO 8601 strings are handled natively by tryParse
      target =
          DateTime.tryParse(bookedAt)?.toLocal() ??
          DateTime.now(); // Safely attempts to parse ISO8601
    }

    final DateTime now = DateTime.now();

    final Duration diff = target.difference(now);

    final bool isOverdue = diff.isNegative;
    final Duration absDiff = diff.abs();

    String status;
    String message;

    if (isOverdue) {
      status = 'overdue';
      if (absDiff.inHours < 24) {
        message = 'overdue by ${absDiff.inHours} hours';
      } else {
        message = 'overdue by ${absDiff.inDays} days';
      }
    } else {
      status = 'upcoming';
      // Checking if it's the same calendar day for "due today"
      final bool isSameDay =
          target.year == now.year &&
          target.month == now.month &&
          target.day == now.day;

      if (isSameDay) {
        message = 'due today';
      } else if (absDiff.inHours < 24) {
        message = 'due in ${absDiff.inHours} hours';
      } else if (absDiff.inDays == 1) {
        message = 'planned tomorrow';
      } else {
        message = 'planned in ${absDiff.inDays} days';
      }
    }

    return {'status': status, 'message': message};
  } catch (e) {
    return null; // Returns null on any parsing or logic error
  }
}
