import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/l10n/app_localizations.dart';

String resolveAppBarTitle(
  String path,
  List<String> segments,
  AppLocalizations l10n,
) {
  if (path == AppRoutes.privacyPolicy) return l10n.privacyPolicy;
  if (path == AppRoutes.supportUs) return l10n.helpUsGrow;
  if (path == AppRoutes.contactSupport) return l10n.getInTouch;
  if (path == AppRoutes.termsConditions) return l10n.termsConditions;

  // Exact Client Route Matches
  // Search Equipment Screen
  if (path == AppRoutes.searchList) return l10n.search;
  // Create Order
  if (path.contains("equipment") && !path.contains("owner")) {
    return l10n.createOrder;
  }
  // Orders
  if (path == AppRoutes.clientOrders) return l10n.myOrders;
  if (path == AppRoutes.clientOrdersHistory) return l10n.orderHistory;

  // Requests
  if (path == AppRoutes.clientRequestsCreate) return l10n.newRequest;
  if (path == AppRoutes.clientRequests) return l10n.myRequests;
  if (path == AppRoutes.clientRequestsHistory) return l10n.requestsHistory;

  if (path == AppRoutes.clientChatList) return l10n.navChats;
  if (path == AppRoutes.clientChatSupport) return l10n.support;

  if (path == AppRoutes.favorites) return l10n.navFavorites;
  if (path == AppRoutes.clientNotifications) return l10n.notifications;

  if (path == AppRoutes.clientProfile) return l10n.myProfile;
  if (path == AppRoutes.clientSettings) return l10n.navSettings;

  if (path == AppRoutes.becomeOwner) return l10n.becomeOwner;
  if (path == AppRoutes.helpSupport) return l10n.helpCenter;

  if (path == AppRoutes.searchMap) return l10n.mapSearch;

  if (path == AppRoutes.clientAddresses) return l10n.myAddresses;
  if (path == AppRoutes.clientPinAddress) return l10n.selectAddress;
  if (path == AppRoutes.clientCreateAddress) return l10n.addAddress;

  if (path.startsWith('/owner')) {
    // Exact Owner Route Matches
    if (path == AppRoutes.ownerDashboard) return l10n.navDashboard;

    if (path == AppRoutes.ownerNotifications) return l10n.notifications;

    if (path == AppRoutes.ownerRequests) return l10n.rentalRequests;
    if (path.contains(AppRoutes.ownerRequests) && segments.length == 3) {
      return l10n.sendOffer;
    }

    if (path == AppRoutes.ownerBookings) return l10n.myOrders;
    if (path == AppRoutes.ownerBookingsHistory) return l10n.orderHistory;
    if (path.contains('orders') || path.contains('bookings')) {
      if (path.contains('history')) return l10n.orderHistory;
      return l10n.myOrders;
    }

    if (path == AppRoutes.ownerProfile) return l10n.myProfile;
    if (path == AppRoutes.ownerSettings) return l10n.navSettings;

    if (path == AppRoutes.ownerRegistration) return l10n.registration;

    if (path == AppRoutes.ownerEquipment) return l10n.myEquipment;
    if (path == AppRoutes.ownerEquipmentCreate) return l10n.addEquipment;
    // Fallback checks via segments/contains for variable param structures
    if (path.contains('equipment')) {
      if (path.contains('create')) return l10n.addEquipment;
      return l10n.equipmentDetails;
    }

    // Notes
    // handle edit address /owner/addresses/:id
    // handle view addresses on map /owner/addresses/map
    if (path.contains('address')) {
      if (path.contains('create')) return l10n.createAddress;
      if (path.contains('edit')) return l10n.editAddress;
      if (path.contains('pin')) return l10n.pinToMap;
      return l10n.addresses;
    }

    if (path == AppRoutes.ownerPaymentTopUp) {
      return l10n.topUpBalance;
    } else if (path == AppRoutes.ownerPayment) {
      return l10n.payments;
    }

    if (path.startsWith('/chat') || path.startsWith('/owner/chat')) {
      return l10n.navChats;
    }
  }

  // Fallback
  return '';
}
