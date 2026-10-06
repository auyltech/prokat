enum ReportTargetType {
  equipment('EQUIPMENT'),
  request('REQUEST'),
  chat('CHAT'),
  chatMessage('CHAT_MESSAGE');

  const ReportTargetType(this.apiValue);

  final String apiValue;
}

class ReportTarget {
  final ReportTargetType type;
  final String targetId;

  const ReportTarget(this.type, this.targetId);

  @override
  bool operator ==(Object other) =>
      other is ReportTarget && other.type == type && other.targetId == targetId;

  @override
  int get hashCode => Object.hash(type, targetId);
}
