import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/chat_header_tile.dart';
import 'package:prokat/features/layout/resolve_app_bar_title.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';
import 'package:prokat/features/user/widgets/city_picker_trigger.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ProkatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ProkatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Get current User
    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";

    // 1. Extract GoRouter location data
    final routerState = GoRouterState.of(context);
    final String currentPath = routerState.uri.path;
    final List<String> segments = routerState.uri.pathSegments;

    // Don't show on launch, main landing page
    if (currentPath == AppRoutes.launch || currentPath == AppRoutes.main) {
      return const SizedBox.shrink();
    }

    final isOwnerScreen = segments[0] == "owner";

    // 2. Fallback checking for back button stack presence
    final bool canPop = GoRouter.of(context).canPop();

    // Check specific layout scenarios
    final bool isChatDetailScreen =
        (segments.length >= 2 && segments[0] == "chat") ||
        (segments.length >= 3 && segments[1] == "chat");

    final bool isSearchListScreen =
        segments.length >= 2 &&
        segments[0] == 'search' &&
        segments[1] == 'list';

    // 3. Resolve title element
    // Custom Chat tile overrides the uniform title string block
    Widget? titleWidget;
    String? titleString;

    if (isChatDetailScreen) {
      // Safely extract chat ID from segments based on route depth
      // final chatId = segments.contains('owner') ? segments[3] : segments[1];
      titleWidget = ChatHeaderTile(
        currentUserId: currentUserId,
        isOwner: isOwnerScreen,
      );
    } else {
      titleString = resolveAppBarTitle(currentPath, segments, l10n);
      titleWidget = Text(
        titleString,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // 4. Resolve dynamic action elements
    final List<Widget> actionWidgets = [];
    if (isSearchListScreen) {
      actionWidgets.add(const CityPickerTrigger());
      actionWidgets.add(const SizedBox(width: 8));
    }

    final bool isOrdersScreen = currentPath == AppRoutes.clientOrders;
    if (isOrdersScreen) {
      actionWidgets.add(
        IconButton(
          onPressed: () => context.push(
            "${AppRoutes.clientOrders}${AppRoutes.clientOrdersHistory}",
          ),
          icon: Icon(
            Icons.history,
            color: theme.colorScheme.onPrimary,
            size: 24,
          ),
          tooltip: l10n.orderHistory,
        ),
      );
    }

    if (currentPath == AppRoutes.clientRequests) {
      actionWidgets.add(
        IconButton(
          onPressed: () => context.push(AppRoutes.clientRequestsCreate),
          icon: Icon(
            Icons.add_rounded,
            color: theme.colorScheme.onPrimary,
            size: 24,
          ),
          tooltip: l10n.createRequest,
        ),
      );
    }

    // on owner equipment list screen
    if (currentPath == AppRoutes.ownerEquiment) {
      actionWidgets.add(
        IconButton(
          onPressed: () => context.push(AppRoutes.ownerEquimentCreate),
          icon: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 24),
          tooltip: l10n.addEquipment,
        ),
      );
    }

    if (currentPath == AppRoutes.ownerBookings) {
      actionWidgets.add(
        IconButton(
          onPressed: () => context.push(AppRoutes.ownerBookingsHistory),
          icon: Icon(
            Icons.history_toggle_off_rounded,
            color: theme.colorScheme.onPrimary,
            size: 24,
          ),
          tooltip: l10n.orderHistory,
        ),
      );
    }

    if (currentPath == AppRoutes.notifications ||
        currentPath == AppRoutes.ownerNotifications) {
      actionWidgets.add(
        IconButton(
          onPressed: () =>
              ref.read(notificationProvider.notifier).markAllAsRead(),
          icon: const Icon(Icons.done_all),
          tooltip: 'Mark all as read',
        ),
      );
    } else {
      // Always present Notification badge matching structural theme contract
      actionWidgets.add(NotificationBadge());
    }

    return AppBar(
      elevation: 0,
      backgroundColor: isOwnerScreen ? AppColors.teal700 : theme.primaryColor,
      automaticallyImplyLeading: canPop,
      iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () async {
                context.pop();

                if (isChatDetailScreen) {
                  await ref.read(chatProvider.notifier).leaveCurrentChat();
                }
              },
            )
          : null,
      title: titleWidget,
      // titleSpacing: 0,
      centerTitle: false,
      actions: actionWidgets,
      actionsPadding: EdgeInsets.only(right: 16.0),
    );
  }
}
