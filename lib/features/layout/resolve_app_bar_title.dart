import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/l10n/app_localizations.dart';

String resolveAppBarTitle(
  String path,
  List<String> segments,
  AppLocalizations l10n,
) {
  // Exact Client Route Matches
  if (path == AppRoutes.favorites) return 'Favorites';
  if (path == AppRoutes.notifications) return 'Notifications';

  if (path == AppRoutes.profile) return "My Profile";
  if (path == AppRoutes.settings) return 'Settings';
  if (path == AppRoutes.becomeOwner) return 'Become an Owner';
  if (path == AppRoutes.helpSupport) return l10n.helpSupportTitle;
  if (path == '/support-us') return l10n.helpUsGrow;
  if (path == '/terms') return l10n.termsConditions;
  if (path == AppRoutes.categories) return 'Categories';
  if (path == AppRoutes.searchMap) return 'Map Search';
  if (path == AppRoutes.addresses) return 'My Addresses';
  if (path == AppRoutes.searchMap) return 'Map Search';
  if (path == AppRoutes.clientRequests) return l10n.myRequests;
  if (path == AppRoutes.clientRequestsCreate) return l10n.newRequest;

  if (path.contains("equipment") && !path.contains("owner")) {
    return l10n.createBooking;
  }

  if (path.contains('owner')) {
    // Exact Owner Route Matches
    if (path == AppRoutes.ownerDashboard) return 'Dashboard';
    if (path == AppRoutes.ownerNotifications) return 'Notifications';
    if (path == AppRoutes.ownerRequests) return 'Rental Requests';
    if (path == AppRoutes.ownerProfile) return "My Profile";
    if (path == AppRoutes.ownerSettings) return l10n.navSettings;
    if (path == AppRoutes.ownerRegistration) return "Registration";
    if (path == AppRoutes.ownerEquiment) return l10n.myEquipment;
    if (path == AppRoutes.ownerEquimentCreate) return l10n.addEquipment;
    if (path == AppRoutes.ownerBookings) return l10n.myOrders;
    if (path == AppRoutes.ownerBookingsHistory) return l10n.orderHistory;

    if (path.contains(AppRoutes.ownerRequests) && segments.length == 3) {
      return "Send offer";
    }

    // Fallback checks via segments/contains for variable param structures
    if (path.contains('equipment')) {
      if (path.contains('create')) return 'Add Equipment';

      return "Equipment Details";
    }

    if (path.contains('orders') || path.contains('bookings')) {
      if (path.contains('history')) return l10n.orderHistory;
      return l10n.myOrders;
    }

    if (path.contains('address')) {
      if (path.contains('create')) return 'Create Address';
      if (path.contains('edit')) return 'Edit Address';
      if (path.contains('pin')) return 'Pin to Map';
      return 'Addresses';
    }

    if (path.contains('payment')) {
      if (path.contains('top-up')) return 'Top Up Balance';
      return 'Payments';
    }

    if (path.startsWith('/chat') || path.startsWith('/owner/chat')) {
      return l10n.navChats;
    }

    if (segments.isNotEmpty && segments[0] == 'search') {
      return l10n.navSearch;
    }
  }

  // Fallback
  return 'Prokat';
}
