class AppRoutes {
  // Public
  static const String launch = '/';
  static const String error = '/error';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String unAuthorized = '/unauthorized';

  // Guest Screens
  static const String main = '/main'; // Landing page with limited information
  static const String helpSupport = '/help';

  // User Screens
  static const String clientMain =
      '/client'; // TODO: move all client pages under /client

  static const String dashboard = '/dashboard';
  static const String categories = '/categories';

  static const String searchList = '/search/list';
  static const String searchMap = '/search/map';

  static const String equipmentId = '/equipment/:id';
  static const String booking = '/equipment/:id/book';

  static const String clientRequests = '/requests';
  static const String clientRequestsCreate = '$clientRequests/create';
  static const String clientRequestsHistory = '$clientRequests/history';

  static const String clientOrders = '/orders';
  static const String clientOrdersHistory = '/history';
  static const String favorites = '/favorites';

  static const String chat = '/chat';

  static const String profile = '/profile';
  static const String settings = '/settings';

  static const String addresses = '/addresses';
  static const String createAddress = '/create';
  static const String pinToMap = '/map';

  static const String clientCreateAddress = '$addresses$createAddress';
  static const String clientPinAddress = '$addresses$pinToMap';

  static const String becomeOwner = '/become-owner';

  // Owner Screens

  // prefixed with /owner
  static const String ownerDashboard = '/owner/dashboard';

  // Owner Equipment
  static const String ownerEquiment = '/owner/equipment';
  // Sub paths for router
  static const String createEquipment = '/create';
  static const String editEquipment = '/:id';
  static const String equipmentMap = '/map'; // TODO: Screen Not implemented
  // Full path for components
  static const String ownerEquimentCreate = '$ownerEquiment$createEquipment';
  static const String ownerEquimentId = '$ownerEquiment$editEquipment';
  static const String ownerEquimentMap = '$ownerEquiment$equipmentMap';

  // Owner Addresses
  static const String ownerAddresses = '/owner/addresses';
  // Sub paths for router
  static const String editAddress = '/edit';

  // Full path for components
  static const String ownerAddressCreate = '$ownerAddresses$createAddress';
  static const String ownerAddressEdit = '$ownerAddresses$editAddress';
  static const String ownerAddressMap = '$ownerAddresses$pinToMap';

  // Owner Requests
  static const String ownerRequests = '/owner/requests';

  // Owner Bookings
  static const String ownerBookings = '/owner/bookings';
  // Sub paths for router
  static const String bookingHistory = '/history';
  // Full path for components
  static const String ownerBookingsHistory = '$ownerBookings$bookingHistory';

  static const String ownerProfile = '/owner/profile';
  static const String ownerSettings = '/owner/settings';

  static const String ownerPayment = '/owner/payment';
  // Sub paths for router
  static const String topUp = '/topUp';
  // Full path for components
  static const String ownerPaymentTopUp = '$ownerPayment$topUp';

  static const String ownerRegistration = '/owner/registration';

  // Owner Chats
  static const String ownerChat = '/owner/chat'; // List of chats
  // Sub paths for router
  static const String chatDetail = ':id';
  static const String chatInfo = 'info';

  // Notifications
  static const String notifications = '/notifications';
  static const String ownerNotifications = '/owner/notifications';
}
