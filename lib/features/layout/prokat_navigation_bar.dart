import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _NavItem {
  final IconData icon;
  final String path;
  final String Function(AppLocalizations) label;
  const _NavItem({required this.icon, required this.path, required this.label});
}

final _ownerNavItems = [
  _NavItem(icon: Icons.home_rounded, path: AppRoutes.ownerDashboard, label: (l) => l.navHome),
  _NavItem(icon: Icons.local_shipping_rounded, path: AppRoutes.ownerEquiment, label: (l) => l.navMyFleet),
  _NavItem(icon: Icons.list_alt_rounded, path: AppRoutes.ownerBookings, label: (l) => l.navOrders),
  _NavItem(icon: Icons.chat_bubble_rounded, path: AppRoutes.ownerChat, label: (l) => l.navChats),
];

final _clientNavItems = [
  _NavItem(icon: Icons.home_rounded, path: AppRoutes.dashboard, label: (l) => l.navHome),
  _NavItem(icon: Icons.search_rounded, path: AppRoutes.searchList, label: (l) => l.navSearch),
  _NavItem(icon: Icons.add_box_rounded, path: AppRoutes.clientRequestsCreate, label: (l) => l.navCreate),
  _NavItem(icon: Icons.list_alt_rounded, path: AppRoutes.clientOrders, label: (l) => l.navOrders),
  _NavItem(icon: Icons.chat_bubble_rounded, path: AppRoutes.chat, label: (l) => l.navChats),
];

class ProkatNavigationBar extends ConsumerStatefulWidget {
  const ProkatNavigationBar({super.key});

  @override
  ConsumerState<ProkatNavigationBar> createState() => _ProkatNavigationBarState();
}

class _ProkatNavigationBarState extends ConsumerState<ProkatNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final startupState = ref.watch(appStartupProvider);

    if (authState.session == null) {
      return const SizedBox.shrink();
    }

    final navItems = switch (startupState) {
      AppStartupState.owner => _ownerNavItems,
      AppStartupState.client => _clientNavItems,
      _ => const <_NavItem>[],
    };

    if (navItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final String location = GoRouterState.of(context).uri.path;
    int currentIndex = navItems.indexWhere((item) => location.startsWith(item.path));

    final List<String> segments = GoRouterState.of(context).uri.pathSegments;
    bool isChatDetailScreen = false;
    if (segments.length >= 2) {
      if (segments[0] == 'chat' && segments[1] != 'list') isChatDetailScreen = true;
      if (segments.length >= 3 && segments[0] == 'owner' && segments[1] == 'chat') {
        isChatDetailScreen = true;
      }
    }

    if (isChatDetailScreen) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.hintColor,
        onTap: (index) => context.go(navItems[index].path),
        items: navItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon, size: 28),
                label: item.label(l10n),
              ),
            )
            .toList(),
      ),
    );
  }
}
