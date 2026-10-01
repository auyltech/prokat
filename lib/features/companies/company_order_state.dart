import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_service.dart';

String companyOrderStatus(AppLocalizations l, String status) =>
    switch (status) {
      'NEW' => l.companyOrderDiscussion,
      'PROPOSED' => l.companyOrderProposed,
      'CONFIRMED' => l.companyOrderConfirmed,
      'IN_PROGRESS' => l.companyOrderInProgress,
      'COMPLETED' => l.companyOrderCompleted,
      'CANCELLED' => l.companyOrderCancelled,
      _ => status,
    };
String companyOrderDate(dynamic value) {
  final d = DateTime.tryParse('$value')?.toLocal();
  return d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

final companyInquiryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) {
      final user = ref.watch(authProvider.select((s) => s.currentUserId));
      if (user == null) throw const CompanyApiException(401, 'UNAUTHORIZED');
      return ref.watch(companyServiceProvider).inquiry(id);
    });
final companyInquiryListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, companyId) {
      final user = ref.watch(authProvider.select((s) => s.currentUserId));
      if (user == null) throw const CompanyApiException(401, 'UNAUTHORIZED');
      return ref.watch(companyServiceProvider).inquiryList(companyId);
    });
