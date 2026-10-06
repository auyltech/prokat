class ChatBlockState {
  final bool isBlocked;
  final bool isBlockedByMe;
  final String? counterpartUserId;

  const ChatBlockState({
    required this.isBlocked,
    required this.isBlockedByMe,
    this.counterpartUserId,
  });

  static ChatBlockState? tryParse(Object? json) {
    if (json is! Map) return null;
    final counterpart = json['counterpartUserId']?.toString().trim();
    return ChatBlockState(
      isBlocked: json['isBlocked'] == true,
      isBlockedByMe: json['isBlockedByMe'] == true,
      counterpartUserId: counterpart == null || counterpart.isEmpty
          ? null
          : counterpart,
    );
  }

  Map<String, dynamic> toJson() => {
    'isBlocked': isBlocked,
    'isBlockedByMe': isBlockedByMe,
    'counterpartUserId': counterpartUserId,
  };

  @override
  bool operator ==(Object other) =>
      other is ChatBlockState &&
      other.isBlocked == isBlocked &&
      other.isBlockedByMe == isBlockedByMe &&
      other.counterpartUserId == counterpartUserId;

  @override
  int get hashCode => Object.hash(isBlocked, isBlockedByMe, counterpartUserId);
}
