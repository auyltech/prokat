import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import '../../../core/api/api_provider.dart';
import 'auth_api_service.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final Dio dio = ref.watch(dioProvider);
  return AuthNotifier(ref, AuthApiService(dio), AuthSecureStorage());
});
