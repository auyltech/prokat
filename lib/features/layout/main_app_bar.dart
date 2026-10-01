import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/widgets/chat_header_tile.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/owner_fleet_groups_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_detail_title.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_fleet_title.dart';
import 'package:prokat/features/equipment/widgets/search_browse_title.dart';
import 'package:prokat/features/requests/widgets.dart/owner_requests_title.dart';
import 'package:prokat/features/layout/resolve_app_bar_title.dart';
import 'package:prokat/features/layout/section_root_routes.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';
import 'package:prokat/features/user/widgets/city_picker_trigger.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(ProkatAppBar.preferredHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? '';
    final routerState = GoRouterState.of(context);
    final currentPath = routerState.uri.path;
    final segments = routerState.uri.pathSegments;

    final isChatByIdScreen =
        segments.length >= 4 &&
        segments[1] == 'chat' &&
        segments[2] == 'direct' &&
        segments[3].isNotEmpty;
    final isSearchListScreen =
        segments.contains('search') && segments.contains('list');
    final isOwnerEquipmentDetailScreen =
        segments.length == 3 &&
        '/${segments[0]}/${segments[1]}' == AppRoutes.ownerEquipment &&
        segments[2] != AppRoutes.create &&
        segments[2] != AppRoutes.map;
    final isOwnerEquipmentList = currentPath == AppRoutes.ownerEquipment;
    final isOwnerRequestsScreen = currentPath == AppRoutes.ownerRequests;
    final isChatListScreen =
        currentPath == AppRoutes.clientChatList ||
        currentPath == AppRoutes.ownerChatList;
    final fleetGroups = isOwnerRequestsScreen || isOwnerEquipmentList
        ? ref.watch(ownerFleetGroupsProvider).valueOrNull
        : null;
    final requestGroups = isOwnerRequestsScreen ? fleetGroups : null;
    final ownerListGroups = isOwnerEquipmentList
        ? resolveOwnerFleetGroups(
            fetched: fleetGroups,
            items:
                ref.watch(ownerEquipmentProvider).valueOrNull?.items ??
                const [],
          )
        : null;
    final searchCatalog = isSearchListScreen
        ? ref.watch(catalogProvider)
        : null;
    final searchGroups = searchCatalog == null
        ? null
        : userVisibleCatalogGroups(searchCatalog.valueOrNull);
    final blendWithTabs =
        isChatListScreen ||
        (requestGroups != null && requestGroups.length > 1) ||
        (ownerListGroups != null && ownerListGroups.length > 1) ||
        (searchCatalog != null &&
            searchCatalog.hasValue &&
            searchGroups!.length > 1);
    final showBackButton = !isSectionRootPath(currentPath);

    final Widget title;
    final int titleMaxLines;
    if (isChatByIdScreen) {
      title = ChatHeaderTile(chatId: segments[3], currentUserId: currentUserId);
      titleMaxLines = 1;
    } else if (isOwnerEquipmentDetailScreen) {
      title = OwnerEquipmentDetailTitle(equipmentId: segments[2]);
      titleMaxLines = 1;
    } else if (isOwnerRequestsScreen) {
      title = const OwnerRequestsTitle();
      titleMaxLines = 1;
    } else if (isSearchListScreen) {
      title = const SearchBrowseTitle();
      titleMaxLines = 1;
    } else if (isOwnerEquipmentList) {
      title = const OwnerFleetTitle();
      titleMaxLines = 1;
    } else {
      title = Text(resolveAppBarTitle(currentPath, segments, l10n));
      titleMaxLines = currentPath == AppRoutes.becomeOwner ? 2 : 1;
    }

    final actions = <Widget>[];
    if (isSearchListScreen) {
      actions.add(const CityPickerTrigger());
    }

    if (currentPath == AppRoutes.clientOrders) {
      actions.add(
        AppIconButton(
          onTap: () => context.push(AppRoutes.clientOrdersHistory),
          icon: Icons.history,
          tooltip: l10n.orderHistory,
        ),
      );
    }

    if (currentPath == AppRoutes.clientRequests) {
      actions.add(
        AppIconButton(
          onTap: () => context.push(AppRoutes.clientRequestsCreate),
          icon: Icons.add_rounded,
          tooltip: l10n.createRequest,
        ),
      );
    }

    if (currentPath == AppRoutes.ownerEquipment) {
      actions.add(
        AppIconButton(
          onTap: () => context.push(AppRoutes.ownerEquipmentCreate),
          icon: Icons.add,
          tooltip: l10n.addEquipment,
        ),
      );
    }

    if (currentPath == AppRoutes.ownerBookings) {
      actions.add(
        AppIconButton(
          onTap: () => context.push(AppRoutes.ownerBookingsHistory),
          icon: Icons.history_toggle_off_rounded,
          tooltip: l10n.orderHistory,
        ),
      );
    }

    if (currentPath == AppRoutes.clientNotifications ||
        currentPath == AppRoutes.ownerNotifications) {
      actions.add(
        AppIconButton(
          onTap: () => ref.read(notificationProvider.notifier).markAllAsRead(),
          icon: Icons.done_all,
          tooltip: l10n.markAllAsRead,
        ),
      );
    } else if (![
      AppRoutes.login,
      AppRoutes.userAgreement,
      AppRoutes.privacyPolicy,
      AppRoutes.personalDataConsent,
    ].contains(currentPath)) {
      actions.add(const NotificationBadge());
    }

    return ProkatAppBar(
      title: title,
      titleMaxLines: titleMaxLines,
      blendWithTabs: blendWithTabs,
      actions: actions,
      onBack: showBackButton
          ? () => _handleBack(
              context,
              ref,
              currentPath: currentPath,
              isChatByIdScreen: isChatByIdScreen,
              chatId: isChatByIdScreen ? segments[3] : null,
            )
          : null,
    );
  }

  void _handleBack(
    BuildContext context,
    WidgetRef ref, {
    required String currentPath,
    required bool isChatByIdScreen,
    required String? chatId,
  }) {
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      final startup = ref.read(appStartupProvider).routeState;
      context.go(
        backFallbackPath(
          currentPath,
          isLoggedIn:
              startup == AppStartupRouteState.client ||
              startup == AppStartupRouteState.owner,
          isOwner: startup == AppStartupRouteState.owner,
        ),
      );
    }

    if (isChatByIdScreen && chatId != null) {
      unawaited(ref.read(chatSocketServiceProvider).leaveChat(chatId));
    }
  }
}
