import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/auth/providers/auth_api_service.dart';
import 'package:prokat/features/auth/providers/auth_notifier.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/features/user_safety/models/blocked_user.dart';
import 'package:prokat/features/user_safety/models/report_reason.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';
import 'package:prokat/features/user_safety/state/user_safety_providers.dart';
import 'package:prokat/features/user_safety/state/user_safety_service.dart';
import 'package:prokat/l10n/app_localizations.dart';

const testCurrentUserId = 'user-me';

class FakeUserSafetyApi implements UserSafetyApi {
  FakeUserSafetyApi({List<BlockedUser>? blocked}) : blocked = blocked ?? [];

  List<BlockedUser> blocked;
  final List<String> blockCalls = [];
  final List<String> unblockCalls = [];
  final List<(ReportTarget, ReportReason, String?)> reportCalls = [];
  int listCalls = 0;
  bool failBlock = false;
  String? reportErrorCode;

  @override
  Future<ApiResponse<List<BlockedUser>>> getBlockedUsers({
    required int page,
    required int itemsPerPage,
  }) async {
    listCalls++;
    return ApiResponse.success(
      List<BlockedUser>.from(blocked),
      count: blocked.length,
    );
  }

  @override
  Future<MutationResponse> blockUser(String userId) async {
    blockCalls.add(userId);
    if (failBlock) {
      return MutationResponse(success: false, message: 'fail');
    }
    return MutationResponse(success: true, message: 'ok');
  }

  @override
  Future<MutationResponse> unblockUser(String userId) async {
    unblockCalls.add(userId);
    blocked = blocked.where((item) => item.userId != userId).toList();
    return MutationResponse(success: true, message: 'ok');
  }

  @override
  Future<MutationResponse> createReport({
    required ReportTarget target,
    required ReportReason reason,
    String? comment,
  }) async {
    reportCalls.add((target, reason, comment));
    final code = reportErrorCode;
    if (code != null) {
      return MutationResponse(success: false, message: 'fail', errorCode: code);
    }
    return MutationResponse(success: true, message: 'ok');
  }
}

BlockedUser blockedUser(String id, {String? firstName}) {
  return BlockedUser(
    user: UserModel(id: id, firstName: firstName ?? 'User $id'),
    blockedAt: DateTime(2026, 10, 1),
  );
}

AuthNotifier signedInAuth(Ref ref) => _LocalAuthNotifier(ref, signedIn: true);

AuthNotifier guestAuth(Ref ref) => _LocalAuthNotifier(ref, signedIn: false);

class _LocalAuthNotifier extends AuthNotifier {
  _LocalAuthNotifier(Ref ref, {required bool signedIn})
    : super(ref, AuthApiService(Dio()), AuthSecureStorage()) {
    state = signedIn
        ? const AuthState(
            session: AuthSession(
              sessionToken: 'session-user-me',
              user: UserModel(id: testCurrentUserId, role: UserRole.client),
            ),
          )
        : const AuthState();
  }
}

List<Override> userSafetyOverrides(
  FakeUserSafetyApi api, {
  bool signedIn = true,
}) {
  return [
    authProvider.overrideWith(signedIn ? signedInAuth : guestAuth),
    userSafetyServiceProvider.overrideWithValue(api),
  ];
}

Widget testApp({required List<Override> overrides, required Widget home}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}
