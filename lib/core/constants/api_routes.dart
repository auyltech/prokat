class ApiRoutes {
  static const categories = "/categories";
  static const equipment = "/equipment";
  static const clientEquipment = "$equipment/client";
  static const guestEquipment = "$equipment/guest";
  static const ownerEquipment = "$equipment/owner";
  static const locations = "/locations";
  static const ownerLocations = "/locations/owner";
  // User
  static const profile = "/user/profile";
  static const username = "/user/profile/username";
  static const userCategory = "/user/profile/category";
  static const userAddress = "/user/profile/address";
  static const userCityRegion = "/user/profile/region";
  static const userProfileImage = "/user/profile/image";
  // Owner
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
