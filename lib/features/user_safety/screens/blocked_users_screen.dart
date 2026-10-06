import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/features/user_safety/models/blocked_user.dart';
import 'package:prokat/features/user_safety/state/user_safety_providers.dart';
import 'package:prokat/features/user_safety/widgets/block_user_flow.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  final _scroll = ScrollController();
  final Set<String> _unblocking = {};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < AppDimens.s32$xxl * 4) {
      unawaited(ref.read(blockedUsersProvider.notifier).loadMore());
    }
  }

  Future<void> _unblock(BlockedUser item) async {
    if (_unblocking.contains(item.userId)) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _unblocking.add(item.userId));
    await unblockUserWithToast(l10n, ref, userId: item.userId);
    if (mounted) setState(() => _unblocking.remove(item.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background.main,
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(blockedUsersProvider);
    final state = async.valueOrNull;

    if (state == null) {
      if (async.hasError) {
        return EmptyStateTile(
          icon: LucideIcons.circleAlert,
          title: l10n.somethingWentWrong,
          actionButton: AppOutlinedButton(
            title: l10n.retry,
            isExpanded: false,
            onTap: () => ref.invalidate(blockedUsersProvider),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(blockedUsersProvider.notifier).refresh(),
      child: state.items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyStateTile(
                  icon: LucideIcons.userCheck,
                  title: l10n.blockedUsersEmpty,
                ),
              ],
            )
          : ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimens.s16$base),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDimens.s12$md),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final item = state.items[index];
                return AppCard(
                  key: ValueKey('blocked-user-${item.userId}'),
                  child: Row(
                    spacing: AppDimens.s12$md,
                    children: [
                      Expanded(child: UserInfoTile(user: item.user)),
                      AppOutlinedButton(
                        key: ValueKey('unblock-${item.userId}'),
                        title: l10n.unblockUserAction,
                        isExpanded: false,
                        isLoading: _unblocking.contains(item.userId),
                        onTap: () => _unblock(item),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
