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
        currentPath == AppRoutes.searchList ||
        currentPath == AppRoutes.clientRequests ||
        currentPath == AppRoutes.clientRequestsCreate ||
        (isChatDetailScreen &&
            currentPath.startsWith('${AppRoutes.clientChatList}/'));
    return ProkatFlowScope(
      palette: flow,
      enabled: useFlowTheme,
      child: Theme(
        data: useFlowTheme
            ? theme.copyWith(
                scaffoldBackgroundColor: flow.background,
                colorScheme: theme.colorScheme.copyWith(
                  primary: flow.filledPrimary,
                  onPrimary: Colors.white,
                  surface: flow.surface,
                  onSurface: flow.title,
                  outline: flow.border,
                ),
              )
            : theme,
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
