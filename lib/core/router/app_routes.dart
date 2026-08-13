class AppRoutes {
  // Nested route segments
  static const String create = 'create';
  static const String id = ':id';
  static const String history = 'history';
  static const String map = 'map';
  static const String topUp = 'top-up';
  static const String info = 'info';
  static const String directChat = 'direct';
  static const String supportChat = 'support';
  static const String sendOffer = 'send-offer';

  // Public
  static const String launch = '/';
  static const String error = '/error';

  // Auth
  static const String login = '/login';
  static const String register = '/register'; // Not-used
  static const String forgotPassword = '/forgot-password'; // Not-used

  // Guest Screens
  static const String main = '/main'; // Landing page with limited information
  static const String about = '/about';
  static const String helpSupport = '/help';
  static const String contactSupport = '/contact';
  static const String supportUs = '/support-us';
  static const String equipmentDemand = '/equipment-demand/:campaignId';
  static String equipmentDemandPath(String campaignId) =>
      '/equipment-demand/$campaignId';

  static const String userAgreement = '/user-agreement';
  static const String privacyPolicy = '/privacy-policy';
  static const String personalDataConsent = '/personal-data-consent';

  // Client Screens
  static const String clientMain = '/client';

  // Segment
  static const String search = '$clientMain/search';
  // Equipment Search Screen
  static const String searchList = '$clientMain/search/list';
  static const String searchMap = '$clientMain/search/$map'; // Not used

  // Segment used to build the create booking path
  static const String equipment = '$clientMain/equipment';
  static const String book = 'book';
  // Full create booking route
  static const String createBooking = '$clientMain/equipment/$id/$book';

  static const String clientRequests = '$clientMain/requests';
  static const String clientRequestsCreate = '$clientRequests/$create';
  static const String clientRequestsHistory = '$clientRequests/$history';

  static const String clientOrders = '$clientMain/orders';
  static const String clientOrdersHistory = '$clientOrders/$history';

  static const String favorites = '$clientMain/favorites';

  static const String clientChatList = '$clientMain/chat';
  static const String clientChatSupport = '$clientMain/chat/support';

  static const String clientProfile = '$clientMain/profile';
  static const String clientSettings = '$clientMain/settings';
  // Notifications
  static const String clientNotifications = '$clientMain/notifications';

  static const String clientAddresses = '$clientMain/addresses';
  // Full paths
  static const String clientCreateAddress = '$clientAddresses/create';
  static const String clientPinAddress = '$clientAddresses/map';

  static const String becomeOwner = '$clientMain/become-owner';

  // Owner Screens
  static const String ownerMain = '/owner';

  // prefixed with /owner
  static const String ownerDashboard = '$ownerMain/dashboard'; // Not used

  // Owner Equipment
  static const String ownerEquipment = '$ownerMain/equipment';

  // Full path for components
  static const String ownerEquipmentCreate = '$ownerEquipment/$create';
  static const String ownerEquipmentId = '$ownerEquipment/$id';
  static const String ownerEquipmentMap = '$ownerEquipment/$map'; // Not used

  // Owner Addresses
  static const String ownerAddresses = '$ownerMain/addresses';
  // Full path for components
  static const String ownerAddressCreate = '$ownerAddresses/$create';
  static const String ownerAddressEdit = '$ownerAddresses/$id';
  static const String ownerAddressMap = '$ownerAddresses/$map';

  // Owner Requests
  static const String ownerRequests = '$ownerMain/requests';
  static const String ownerCreateOffer = '$ownerRequests/$sendOffer';

  // Owner Bookings
  static const String ownerBookings = '$ownerMain/bookings';
  // Full path for components
  static const String ownerBookingsHistory = '$ownerBookings/$history';

  static const String ownerProfile = '$ownerMain/profile';
  static const String ownerSettings = '$ownerMain/settings';

  static const String ownerPayment = '$ownerMain/payment';
  static const String ownerPaymentTopUp = '$ownerPayment/$topUp';

  static const String ownerRegistration = '$ownerMain/registration';

  // Owner Chats
  static const String ownerChatList = '$ownerMain/chat'; // List of chats

  // Notifications
  static const String ownerNotifications = '$ownerMain/notifications';
}
