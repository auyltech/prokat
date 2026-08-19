import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
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

    final hideAppBar =
        currentPath == AppRoutes.launch ||
        currentPath == AppRoutes.main ||
        currentPath == AppRoutes.login;

    // Don't show on launch, main landing page
    if (hideAppBar) {
      return const SizedBox.shrink();
    }

    final isOwnerScreen = segments.isNotEmpty ? segments[0] == "owner" : false;

    // 2. Structural Segment Evaluations
    // Checks path segments explicitly match /client/chat/direct/:id or /owner/chat/direct/:id
    final bool isChatByIdScreen =
        segments.length >= 4 &&
        segments[1] == "chat" &&
        segments[2] == "direct" &&
        segments[3].isNotEmpty;

    // Safely evaluates path components targeting nested paths like client/search/list
    final bool isSearchListScreen =
        segments.contains('search') && segments.contains('list');

    // 3. Resolve title element
    Widget? titleWidget;
    String? titleString;

    // Replaced relative string evaluation against segments with full currentPath matching
    final showBackButton =
        currentPath == AppRoutes.clientOrdersHistory ||
        currentPath == AppRoutes.clientRequestsHistory ||
        currentPath == AppRoutes.ownerBookingsHistory ||
        currentPath == AppRoutes.ownerEquipmentCreate ||
        currentPath == AppRoutes.ownerCreateOffer ||
        currentPath == AppRoutes.clientChatSupport ||
        [
          AppRoutes.ownerPayment,
          AppRoutes.ownerPaymentTopUp,
          AppRoutes.userAgreement,
          AppRoutes.privacyPolicy,
          AppRoutes.personalDataConsent,
          AppRoutes.helpSupport,
          AppRoutes.clientDocuments,
        ].contains(currentPath) ||
        isChatByIdScreen;

    if (isChatByIdScreen) {
      // Safely extract chat ID now that length boundary >= 4 is guaranteed
      final chatId = segments[3];

      titleWidget = ChatHeaderTile(
        chatId: chatId,
        currentUserId: currentUserId,
        isOwner: isOwnerScreen,
      );
    } else {
      titleString = resolveAppBarTitle(currentPath, segments, l10n);
      titleWidget = Text(
        titleString,
        style: theme.textTheme.titleLarge?.copyWith(
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
          onPressed: () => context.push(AppRoutes.clientOrdersHistory),
          icon: const Icon(Icons.history, color: Colors.grey, size: 24),
          tooltip: l10n.orderHistory,
        ),
      );
    }

    if (currentPath == AppRoutes.clientRequests) {
      actionWidgets.add(
        IconButton(
          onPressed: () => context.push(AppRoutes.clientRequestsCreate),
          icon: const Icon(Icons.add_rounded, color: Colors.grey, size: 24),
          tooltip: l10n.createRequest,
        ),
      );
    }

    if (currentPath == AppRoutes.ownerEquipment) {
      actionWidgets.add(
        IconButton(
          onPressed: () => context.push(AppRoutes.ownerEquipmentCreate),
          icon: const Icon(Icons.add, color: Colors.grey, size: 24),
          tooltip: l10n.addEquipment,
        ),
      );
    }

    if (currentPath == AppRoutes.ownerBookings) {
      actionWidgets.add(
        IconButton(
          onPressed: () => context.push(AppRoutes.ownerBookingsHistory),
          icon: const Icon(
            Icons.history_toggle_off_rounded,
            color: Colors.grey,
            size: 24,
          ),
          tooltip: l10n.orderHistory,
        ),
      );
    }

    if (currentPath == AppRoutes.clientNotifications ||
        currentPath == AppRoutes.ownerNotifications) {
      actionWidgets.add(
        IconButton(
          onPressed: () =>
              ref.read(notificationProvider.notifier).markAllAsRead(),
          icon: const Icon(Icons.done_all),
          tooltip: l10n.markAllAsRead,
        ),
      );
    } else if ([
      AppRoutes.login,
      AppRoutes.userAgreement,
      AppRoutes.privacyPolicy,
      AppRoutes.personalDataConsent,
    ].contains(currentPath)) {
      // Don't show notifications on login
    } else {
      actionWidgets.add(NotificationBadge());
    }

    return AppBar(
      elevation: 5,
      backgroundColor: theme.cardColor,
      automaticallyImplyLeading: showBackButton,
      iconTheme: IconThemeData(
        color: isOwnerScreen ? AppColors.teal700 : theme.colorScheme.primary,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.black12, height: 1.0),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () async {
                if (GoRouter.of(context).canPop()) {
                  context.pop();
                } else if (currentPath == AppRoutes.login) {
                  context.go(AppRoutes.main);
                }

                // Fixed identical branch logic and index range exception
                if (isChatByIdScreen) {
                  final chatId = segments[3];
                  ref.read(chatSocketServiceProvider).leaveChat(chatId);
                }
              },
            )
          : null,
      title: titleWidget,
      centerTitle: false,
      actions: actionWidgets,
      actionsPadding: const EdgeInsets.only(right: 16.0),
    );
  }
}
