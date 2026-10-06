import 'package:prokat/features/auth/models/user_model.dart';

class BlockedUser {
  final UserModel user;
  final DateTime blockedAt;

  const BlockedUser({required this.user, required this.blockedAt});

  String get userId => user.id ?? '';

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final blockedAt = DateTime.tryParse(json['blockedAt']?.toString() ?? '');
    if (user is! Map<String, dynamic> || blockedAt == null) {
      throw const FormatException('Invalid blocked user');
    }
    return BlockedUser(
      user: UserModel.fromJson(user),
      blockedAt: blockedAt.toLocal(),
    );
  }
}
