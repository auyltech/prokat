abstract final class AnalyticsEvents {
  static const signUp = 'sign_up';
  static const ownerApplicationStarted = 'owner_application_started';
  static const ownerApplicationSubmitted = 'owner_application_submitted';
  static const equipmentCreationStarted = 'equipment_creation_started';
  static const equipmentDraftCreated = 'equipment_draft_created';
  static const equipmentSubmitBlocked = 'equipment_submit_blocked';
  static const equipmentSubmittedForReview = 'equipment_submitted_for_review';
  static const share = 'share';
  static const shareLinkOpened = 'share_link_opened';
  static const storeLinkClicked = 'store_link_clicked';
  static const screenView = 'screen_view';
}

abstract final class AnalyticsParams {
  static const method = 'method';
  static const shareId = 'share_id';
  static const isResubmit = 'is_resubmit';
  static const isFirstEquipment = 'is_first_equipment';
  static const categoryId = 'category_id';
  static const catalogGroup = 'catalog_group';
  static const reason = 'reason';
  static const contentType = 'content_type';
  static const itemId = 'item_id';
  static const openVia = 'open_via';
  static const firstShareBootstrapRun = 'first_share_bootstrap_run';
  static const screenName = 'screen_name';
  static const screenClass = 'screen_class';
}

abstract final class AnalyticsValues {
  static const methodPhoneOtp = 'phone_otp';
  static const catalogGroupMachinery = 'machinery';
  static const catalogGroupEquipment = 'equipment';
  static const reasonPhotoMissing = 'photo_missing';
  static const reasonFieldsIncomplete = 'fields_incomplete';
  static const contentTypeEquipment = 'equipment';
  static const openViaAppLink = 'app_link';
  static const openViaInstallReferrer = 'install_referrer';
  static const openViaWebLanding = 'web_landing';
}

abstract final class AnalyticsUserProperties {
  static const userRole = 'user_role';
  static const roleClient = 'client';
  static const roleOwner = 'owner';
}
