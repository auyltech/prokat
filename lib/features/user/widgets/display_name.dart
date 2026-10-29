import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/edit_name_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class DisplayName extends ConsumerWidget {
  const DisplayName({super.key});

  void _openEditSheet(BuildContext context, String currentName) {
    unawaited(EditNameSheet.show(context: context, initialName: currentName));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(clientProfileProvider);
    final savedName = (state.userProfile?.displayName ?? '').trim();
    final name = savedName.isNotEmpty ? savedName : l10n.myProfile;
    final flow = ProkatFlowScope.maybeOf(context);
    final nameAction = GestureDetector(
      onTap: () => _openEditSheet(context, savedName),
      child: Text(
        name,
        textAlign: flow == null ? null : TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [if (flow == null) nameAction else Flexible(child: nameAction)],
    );
  }
}
