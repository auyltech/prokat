import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/widgets/owner_profile_form.dart';

class OwnerRegistrationScreen extends ConsumerStatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  ConsumerState<OwnerRegistrationScreen> createState() =>
      _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState
    extends ConsumerState<OwnerRegistrationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(ownerProfileProvider.notifier).refreshIfStale());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialProfile = ref.watch(ownerProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(ownerProfileProvider.notifier).refresh();
        },
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (initialProfile != null)
                    OwnerProfileForm(initialProfile: initialProfile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
