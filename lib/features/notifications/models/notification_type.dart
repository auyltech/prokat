enum NotificationType {
  requestCreated,
  requestCancelled,
  requestExpired,

  offerCreated,
  offerCancelled,
  offerAccepted,
  offerRejected,
  offerExpired,

  bookingCreated,
  bookingAccepted,
  bookingRejected,
  bookingConfirmed,
  bookingCancelled,
  bookingCompleted,
  clientConfirmedCompletion,

  counterOfferCreated,
  counterOfferAccepted,
  counterOfferRejected,
  negotiationExpired,
  negotiationClosed,

  workOnTheWay,
  workOnSite,
  workStarted,
  workPaused,
  workFailed,
  workCompleted,
  clientConfirmationRequired,

  chatMessageCreated,
  bookingEventMessageCreated,
  priceNegotiationMessageCreated,
  adminMessageCreated,

  reviewAvailable,
  reviewSubmitted,
  reviewReminder,

  ownerProfileSubmitted,
  ownerApproved,
  ownerRejected,
  equipmentApproved,
  equipmentRejected,
  equipmentSuspended,
  documentRequired,
  adminWarning,

  balanceToppedUp,
  lowBalanceWarning,
  equipmentOfflineInsufficientBalance,
  paymentFailed,
  minutesPackageUsed,

  systemNotice,
}

extension NotificationTypeX on NotificationType {
  String get backend => switch (this) {
    NotificationType.requestCreated => 'REQUEST_CREATED',
    NotificationType.requestCancelled => 'REQUEST_CANCELLED',
    NotificationType.requestExpired => 'REQUEST_EXPIRED',

    NotificationType.offerCreated => 'OFFER_CREATED',
    NotificationType.offerCancelled => 'OFFER_CANCELLED',
    NotificationType.offerAccepted => 'OFFER_ACCEPTED',
    NotificationType.offerRejected => 'OFFER_REJECTED',
    NotificationType.offerExpired => 'OFFER_EXPIRED',

    NotificationType.bookingCreated => 'BOOKING_CREATED',
    NotificationType.bookingAccepted => 'BOOKING_ACCEPTED',
    NotificationType.bookingRejected => 'BOOKING_REJECTED',
    NotificationType.bookingConfirmed => 'BOOKING_CONFIRMED',
    NotificationType.bookingCancelled => 'BOOKING_CANCELLED',
    NotificationType.bookingCompleted => 'BOOKING_COMPLETED',
    NotificationType.clientConfirmedCompletion => 'CLIENT_CONFIRMED_COMPLETION',

    NotificationType.counterOfferCreated => 'COUNTER_OFFER_CREATED',
    NotificationType.counterOfferAccepted => 'COUNTER_OFFER_ACCEPTED',
    NotificationType.counterOfferRejected => 'COUNTER_OFFER_REJECTED',
    NotificationType.negotiationExpired => 'NEGOTIATION_EXPIRED',
    NotificationType.negotiationClosed => 'NEGOTIATION_CLOSED',

    NotificationType.workOnTheWay => 'WORK_ON_THE_WAY',
    NotificationType.workOnSite => 'WORK_ON_SITE',
    NotificationType.workStarted => 'WORK_STARTED',
    NotificationType.workPaused => 'WORK_PAUSED',
    NotificationType.workFailed => 'WORK_FAILED',
    NotificationType.workCompleted => 'WORK_COMPLETED',
    NotificationType.clientConfirmationRequired =>
      'CLIENT_CONFIRMATION_REQUIRED',

    NotificationType.chatMessageCreated => 'CHAT_MESSAGE_CREATED',
    NotificationType.bookingEventMessageCreated =>
      'BOOKING_EVENT_MESSAGE_CREATED',
    NotificationType.priceNegotiationMessageCreated =>
      'PRICE_NEGOTIATION_MESSAGE_CREATED',
    NotificationType.adminMessageCreated => 'ADMIN_MESSAGE_CREATED',

    NotificationType.reviewAvailable => 'REVIEW_AVAILABLE',
    NotificationType.reviewSubmitted => 'REVIEW_SUBMITTED',
    NotificationType.reviewReminder => 'REVIEW_REMINDER',

    NotificationType.ownerProfileSubmitted => 'OWNER_PROFILE_SUBMITTED',
    NotificationType.ownerApproved => 'OWNER_APPROVED',
    NotificationType.ownerRejected => 'OWNER_REJECTED',
    NotificationType.equipmentApproved => 'EQUIPMENT_APPROVED',
    NotificationType.equipmentRejected => 'EQUIPMENT_REJECTED',
    NotificationType.equipmentSuspended => 'EQUIPMENT_SUSPENDED',
    NotificationType.documentRequired => 'DOCUMENT_REQUIRED',
    NotificationType.adminWarning => 'ADMIN_WARNING',

    NotificationType.balanceToppedUp => 'BALANCE_TOPPED_UP',
    NotificationType.lowBalanceWarning => 'LOW_BALANCE_WARNING',
    NotificationType.equipmentOfflineInsufficientBalance =>
      'EQUIPMENT_OFFLINE_INSUFFICIENT_BALANCE',
    NotificationType.paymentFailed => 'PAYMENT_FAILED',
    NotificationType.minutesPackageUsed => 'MINUTES_PACKAGE_USED',

    NotificationType.systemNotice => 'SYSTEM_NOTICE',
  };

  static NotificationType? fromBackend(String? value) {
    if (value == null) return null;

    return NotificationType.values.cast<NotificationType?>().firstWhere(
      (e) => e!.backend == value,
      orElse: () => null,
    );
  }
}

extension NotificationTypeParser on NotificationType {
  /// Converts a backend value (e.g. BOOKING_CONFIRMED)
  /// into a NotificationType.
  static NotificationType parse(dynamic value) {
    if (value == null) return NotificationType.systemNotice;

    final input = value.toString().trim().toUpperCase();

    for (final type in NotificationType.values) {
      if (type.backendName == input) {
        return type;
      }
    }

    return NotificationType.systemNotice;
  }

  /// Converts this enum to the backend format
  /// e.g. bookingConfirmed -> BOOKING_CONFIRMED
  String get backendName => name
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .toUpperCase();
}
