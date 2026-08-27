class ApiRoutes {
  static const catalog = "/catalog";
  static const categories = "/categories";
  static const equipment = "/equipment";
  static const clientEquipment = "$equipment/client";
  static const guestEquipment = "$equipment/guest";
  static const ownerEquipment = "$equipment/owner";
  static const locations = "/locations";
  static const ownerLocations = "/locations/owner";
  // Client
  static const profile = "/user/profile";
  static const clientNotificationSettings =
      '/user/profile/settings/notifications';
  static const userCategory = "/user/profile/category";
  static const userAddress = "/user/profile/address";
  static const userCityRegion = "/user/profile/region";
  static const userProfileImage = "/user/profile/image";
  // Owner
  static const ownerProfile = "/owner/profile";
  static const ownerProfileImage = "/owner/profile/image";
  static const ownerNotificationSettings =
      "$ownerProfile/settings/notifications";
  static const balance = "/billing";
  static const transactions = "/billing/transactions";
  static const topUpBalance = "/billing";
  static const priceTiers = "/billing/pricetiers";
  static const volumeDiscount = "/billing/volumediscount";
  // Auth
  static const login = "/auth/login";
  static const register = "/auth/register";
  static const logout = "/auth/logout";
  //
  static const deleteAccount = "/user/profile/delete-account";
}
