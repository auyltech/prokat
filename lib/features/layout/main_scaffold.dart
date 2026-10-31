import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/layout/main_app_bar.dart';
import 'package:prokat/features/layout/main_navigation_bar.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final routerState = GoRouterState.of(context);
    final String currentPath = routerState.uri.path;

    final List<String> segments = GoRouterState.of(context).uri.pathSegments;

    bool isChatDetailScreen =
        (segments.length > 2 &&
        segments[1] == 'chat' &&
        segments[2] == 'direct');

    final bool isPinMapScreen =
        currentPath == AppRoutes.clientPinAddress ||
        currentPath == AppRoutes.ownerAddressMap;

    final isOwnerEquipmentDetail =
        segments.length == 3 &&
        currentPath.startsWith('${AppRoutes.ownerEquipment}/') &&
        segments.last != 'create' &&
        segments.last != 'map';

    final bool hideAppBar =
        [
          AppRoutes.launch,
          AppRoutes.main,
          AppRoutes.login,
          AppRoutes.about,
          AppRoutes.clientProfile,
          AppRoutes.ownerProfile,
        ].contains(currentPath) ||
        currentPath == '/search/companies';

    final flow = ProkatFlowPalette.of(context);
    final useFlowTheme =
        currentPath == AppRoutes.contactSupport ||
        currentPath == AppRoutes.supportUs ||
        currentPath == AppRoutes.about ||
        currentPath == AppRoutes.main ||
        currentPath == AppRoutes.clientPinAddress ||
        currentPath == AppRoutes.ownerAddressMap ||
        currentPath == AppRoutes.clientCreateAddress ||
        currentPath == AppRoutes.ownerAddressCreate ||
        currentPath == AppRoutes.favorites ||
        currentPath == AppRoutes.clientNotifications ||
        currentPath == AppRoutes.ownerNotifications ||
        currentPath == AppRoutes.ownerCreateOffer ||
        currentPath == AppRoutes.ownerPayment ||
        currentPath == AppRoutes.ownerPaymentTopUp ||
        currentPath == AppRoutes.ownerPaymentHistory ||
        currentPath == AppRoutes.clientSettings ||
        currentPath == AppRoutes.ownerSettings ||
        currentPath == AppRoutes.clientDocuments ||
        currentPath == AppRoutes.ownerDocuments ||
        currentPath == AppRoutes.becomeOwner ||
        currentPath == AppRoutes.ownerRegistration ||
        currentPath == AppRoutes.clientBlockedUsers ||
        currentPath == AppRoutes.ownerBlockedUsers ||
        currentPath == AppRoutes.helpSupport ||
        currentPath == AppRoutes.searchList ||
        currentPath == AppRoutes.clientRequests ||
        currentPath == AppRoutes.clientRequestsCreate ||
        currentPath == AppRoutes.clientChatList ||
        currentPath == AppRoutes.ownerChatList ||
        currentPath == AppRoutes.clientOrders ||
        currentPath == AppRoutes.clientOrdersHistory ||
        currentPath == AppRoutes.ownerBookings ||
        currentPath == AppRoutes.ownerBookingsHistory ||
        currentPath == AppRoutes.ownerEquipment ||
        currentPath == AppRoutes.ownerEquipmentCreate ||
        isOwnerEquipmentDetail ||
        currentPath == AppRoutes.clientProfile ||
        currentPath == AppRoutes.ownerProfile ||
        currentPath == AppRoutes.ownerRequests ||
        (isChatDetailScreen &&
            currentPath.startsWith('${AppRoutes.clientChatList}/'));
    return ProkatFlowScope(
      palette: flow,
      enabled: useFlowTheme,
      child: Theme(
        data: useFlowTheme ? flow.themeFor(theme) : theme,
        child: Scaffold(
          backgroundColor: useFlowTheme
              ? flow.background
              : theme.scaffoldBackgroundColor,
          resizeToAvoidBottomInset: !isPinMapScreen,
          appBar: hideAppBar ? null : const MainAppBar(),
          bottomNavigationBar: isChatDetailScreen || isPinMapScreen
              ? null
              : const MainNavigationBar(),
          body: navigationShell,
        ),
      ),
    );
  }
}
