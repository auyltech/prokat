import 'package:prokat/core/router/app_routes.dart';

/// Bottom-nav destinations. These stay without a back button.
const sectionRootPaths = <String>{
  AppRoutes.searchList,
  AppRoutes.clientRequests,
  AppRoutes.clientOrders,
  AppRoutes.clientChatList,
  AppRoutes.clientProfile,
  AppRoutes.ownerProfile,
  AppRoutes.ownerRequests,
  AppRoutes.ownerEquipment,
  AppRoutes.ownerBookings,
  AppRoutes.ownerChatList,
};

bool isSectionRootPath(String path) => sectionRootPaths.contains(path);

/// Fallback destination when a nested screen cannot pop.
String sectionRootFor(String path) {
  if (path.startsWith(AppRoutes.search) ||
      path.startsWith(AppRoutes.equipment)) {
    return AppRoutes.searchList;
  }
  if (path.startsWith(AppRoutes.clientRequests)) {
    return AppRoutes.clientRequests;
  }
  if (path.startsWith(AppRoutes.clientOrders)) {
    return AppRoutes.clientOrders;
  }
  if (path.startsWith(AppRoutes.clientChatList)) {
    return AppRoutes.clientChatList;
  }
  if (path.startsWith(AppRoutes.ownerRequests)) {
    return AppRoutes.ownerRequests;
  }
  if (path.startsWith(AppRoutes.ownerEquipment)) {
    return AppRoutes.ownerEquipment;
  }
  if (path.startsWith(AppRoutes.ownerBookings)) {
    return AppRoutes.ownerBookings;
  }
  if (path.startsWith(AppRoutes.ownerChatList)) {
    return AppRoutes.ownerChatList;
  }
  if (path.startsWith(AppRoutes.clientMain)) {
    return AppRoutes.clientProfile;
  }
  if (path.startsWith(AppRoutes.ownerMain)) {
    return AppRoutes.ownerProfile;
  }
  return AppRoutes.main;
}

String backFallbackPath(
  String path, {
  required bool isLoggedIn,
  required bool isOwner,
}) {
  final root = sectionRootFor(path);
  if (root != AppRoutes.main || !isLoggedIn) {
    return root;
  }
  return isOwner ? AppRoutes.ownerProfile : AppRoutes.clientProfile;
}
