import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/layout/prokat_app_bar.dart';
import 'package:prokat/features/layout/prokat_navigation_bar.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  MainScaffold({super.key, required this.navigationShell});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: ProkatAppBar(),
      bottomNavigationBar: const ProkatNavigationBar(),
      body: navigationShell,
    );
  }
}
