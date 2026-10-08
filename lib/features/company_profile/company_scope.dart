import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeCompanyIdProvider = Provider<String?>((ref) => null);
final exitCompanyProvider = Provider<void Function()?>((ref) => null);

final companyRootNavigationProvider = Provider<void Function(String)?>(
  (ref) => null,
);
