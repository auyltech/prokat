import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';

/// Snapshot of the current route, taken **before** accept. The request card
/// unmounts as soon as the list updates, so [BuildContext] is gone afterwards.
class TenderAcceptNavigation {
  TenderAcceptNavigation._({
    required this._router,
    required this._topPath,
    required this._backgroundPath,
    required this._topLocation,
  });

  final GoRouter _router;
  final String _topPath;
  final String _backgroundPath;
  final String _topLocation;

  factory TenderAcceptNavigation.capture(BuildContext context) {
    final router = GoRouter.of(context);
    final uri = GoRouterState.of(context).uri;
    return TenderAcceptNavigation._(
      router: router,
      topPath: uri.path,
      backgroundPath: router.routerDelegate.currentConfiguration.uri.path,
      topLocation: uri.toString(),
    );
  }

  /// After a successful accept from **Мои заявки**, switch to **Мои заказы**.
  ///
  /// Chat opened from that list stays on top; Back then lands on orders.
  void revealClientOrders() {
    if (!_isClientRequestsPath(_backgroundPath) &&
        !_isClientRequestsPath(_topPath)) {
      return;
    }

    final onChat = _topPath.startsWith('${AppRoutes.clientChatList}/direct/');
    if (onChat) {
      _router.go(AppRoutes.clientOrders);
      unawaited(_router.push(_topLocation));
      return;
    }

    _router.go(AppRoutes.clientOrders);
  }
}

bool _isClientRequestsPath(String path) {
  return path == AppRoutes.clientRequests ||
      path.startsWith('${AppRoutes.clientRequests}/');
}
