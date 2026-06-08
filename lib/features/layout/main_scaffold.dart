import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/layout/prokat_app_bar.dart';
import 'package:prokat/features/layout/prokat_navigation_bar.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  MainScaffold({super.key, required this.navigationShell});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // 1. Extract GoRouter location data
    final routerState = GoRouterState.of(context);
    final String currentPath = routerState.uri.path;

    // 2. Determine if the app bar should be hidden
    final bool hideAppBar = [
      AppRoutes.launch,
      AppRoutes.main,
    ].contains(currentPath);

    return Scaffold(
      key: _scaffoldKey,
      // 3. Pass null instead of a empty widget to properly reset the SafeArea
      appBar: hideAppBar ? null : const ProkatAppBar(),
      bottomNavigationBar: const ProkatNavigationBar(),
      body: navigationShell,
    );
  }
}
