import 'package:prokat/l10n/app_localizations.dart';

enum WorkStatus {
  pending, // 0
  onMyWay, // 1
  onSite, // 2
  started, // 3
  postponed, // 3
  stopped, // 4
  completed, // 5
  cancelled, // 5
}

WorkStatus parseWorkStatus(dynamic value) {
  if (value == null) return WorkStatus.pending;
  final normalized = value.toString().trim().toLowerCase();
  for (final status in WorkStatus.values) {
    if (status.name.toLowerCase() == normalized) {
      return status;
    }
  }
  return WorkStatus.pending;
}

extension WorkStatusX on WorkStatus {
  int get level {
    switch (this) {
      case WorkStatus.pending:
        return 0;
      case WorkStatus.onMyWay:
        return 1;
      case WorkStatus.onSite:
        return 2;
      case WorkStatus.started:
      case WorkStatus.postponed:
        return 3;
      case WorkStatus.stopped:
        return 4;
      case WorkStatus.completed:
      case WorkStatus.cancelled:
        return 5;
    }
  }

  String get label {
    switch (this) {
      case WorkStatus.pending:
        return "Pending";
      case WorkStatus.onMyWay:
        return "On my way";
      case WorkStatus.onSite:
        return "On site";
      case WorkStatus.started:
        return "Start work";
      case WorkStatus.postponed:
        return "Postpone";
      case WorkStatus.stopped:
        return "Stop work";
      case WorkStatus.completed:
        return "Complete work";
      case WorkStatus.cancelled:
        return "Cancel job";
    }
  }

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case WorkStatus.pending:
        return l10n.workStatusPending;
      case WorkStatus.onMyWay:
        return l10n.workStatusOnMyWay;
      case WorkStatus.onSite:
        return l10n.workStatusOnSite;
      case WorkStatus.started:
        return l10n.workStatusStartWork;
      case WorkStatus.postponed:
        return l10n.workStatusPostpone;
      case WorkStatus.stopped:
        return l10n.workStatusStopWork;
      case WorkStatus.completed:
        return l10n.workStatusCompleteWork;
      case WorkStatus.cancelled:
        return l10n.workStatusCancelJob;
    }
  }
}

bool canTransition(WorkStatus current, WorkStatus next) {
  return next.level >= current.level;
}

final preStartStatuses = [
  WorkStatus.pending,
  WorkStatus.onMyWay,
  WorkStatus.onSite,
  WorkStatus.started,
  WorkStatus.postponed,
];

final postStartStatuses = [
  WorkStatus.stopped,
  WorkStatus.completed,
  WorkStatus.cancelled,
];
