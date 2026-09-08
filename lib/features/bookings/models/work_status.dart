import 'package:prokat/l10n/app_localizations.dart';

enum WorkStatus {
  pending,
  onMyWay,
  onSite,
  started,
  postponed,
  stopped,
  completed,
  cancelled,
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

  String sheetLabel(AppLocalizations l10n, {required WorkStatus current}) {
    if (this == WorkStatus.started && current == WorkStatus.stopped) {
      return l10n.workStatusResumeWork;
    }
    return localizedLabel(l10n);
  }
}

List<WorkStatus> nextWorkStatuses(WorkStatus current) {
  switch (current) {
    case WorkStatus.pending:
      return [
        WorkStatus.onMyWay,
        WorkStatus.onSite,
        WorkStatus.started,
        WorkStatus.postponed,
      ];
    case WorkStatus.onMyWay:
      return [WorkStatus.onSite, WorkStatus.started, WorkStatus.postponed];
    case WorkStatus.onSite:
      return [WorkStatus.started, WorkStatus.postponed];
    case WorkStatus.postponed:
      return [WorkStatus.onMyWay, WorkStatus.onSite, WorkStatus.started];
    case WorkStatus.started:
      return [WorkStatus.stopped, WorkStatus.completed];
    case WorkStatus.stopped:
      return [WorkStatus.started, WorkStatus.completed];
    case WorkStatus.completed:
      return const [];
    case WorkStatus.cancelled:
      return [WorkStatus.started, WorkStatus.stopped, WorkStatus.completed];
  }
}

bool canTransition(WorkStatus current, WorkStatus next) {
  return nextWorkStatuses(current).contains(next);
}
