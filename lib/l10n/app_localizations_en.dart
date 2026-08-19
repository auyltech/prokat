// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appLanguage => 'App Language';

  @override
  String offerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offers',
      one: '1 offer',
    );
    return '$_temp0';
  }

  @override
  String get activeRequestAlreadyExists =>
      'You already have an active request.';

  @override
  String get supportTicketSubmitted => 'Support ticket submitted successfully!';

  @override
  String get failedToSubmitTicket => 'Failed to submit ticket';

  @override
  String get getInTouch => 'Get in Touch';

  @override
  String get createOrder => 'Create Order';

  @override
  String get myProfile => 'My Profile';

  @override
  String get mapSearch => 'Map Search';

  @override
  String get myAddresses => 'My Addresses';

  @override
  String get rentalRequests => 'Rental Requests';

  @override
  String get registration => 'Registration';

  @override
  String get equipmentDetails => 'Equipment Details';

  @override
  String get createAddress => 'Create Address';

  @override
  String get editAddress => 'Edit Address';

  @override
  String get pinToMap => 'Pin to Map';

  @override
  String get addresses => 'Addresses';

  @override
  String get topUpBalance => 'Top Up Balance';

  @override
  String get payments => 'Payments';

  @override
  String get offerCreated => 'Offer Created';

  @override
  String get offerReceived => 'Offer Received';

  @override
  String get counterOfferSent => 'Counter Offer Sent';

  @override
  String get respondToCounterOffer => 'Respond to Counter Offer';

  @override
  String get orderHasBeenCancelled => 'Order has been cancelled';

  @override
  String get waitingOwnerResponse => 'Waiting Owner Response';

  @override
  String get waitingClientConfirmation => 'Waiting Client Confirmation';

  @override
  String get confirmWorkCompleted => 'Confirm Work Completed';

  @override
  String get orderCompleted => 'Order Completed';

  @override
  String get reviewSent => 'Review Sent';

  @override
  String get orderCreated => 'Order Created';

  @override
  String get workCompleted => 'Work Completed';

  @override
  String get selectRegistrationMethod =>
      'Select your preferred registration method';

  @override
  String get couldNotLoadCategories => 'Couldn\'t load categories';

  @override
  String get checkYourConnection => 'Please check your connection.';

  @override
  String get noServicesAvailableYet => 'No services available yet';

  @override
  String get checkBackLater => 'Check back later for new updates.';

  @override
  String get balanceUnavailable => 'Balance unavailable';

  @override
  String get accountBalance => 'Account Balance';

  @override
  String get notVerified => 'Not Verified';

  @override
  String get uploadProfileImage => 'Upload Profile Image';

  @override
  String get switchBackToClient => 'Switch back to client section dashboard';

  @override
  String get vehicleName => 'Vehicle Name';

  @override
  String get modelType => 'Model Type';

  @override
  String get noLocationSet => 'No location set';

  @override
  String get noPriceSet => 'No Price Set';

  @override
  String get hasPricesListed => 'Has prices listed';

  @override
  String get dateNotSet => 'Date not set';

  @override
  String get balanceLoadError => 'Could not load balance';

  @override
  String get priceEntryDeleted => 'Price entry deleted';

  @override
  String get failedToDeletePriceEntry => 'Failed to delete price entry';

  @override
  String get systemError => 'SYSTEM ERROR';

  @override
  String get equipmentDataNotLocated => 'EQUIPMENT DATA NOT LOCATED';

  @override
  String get backToFleet => 'BACK TO FLEET';

  @override
  String get howCanWeHelp => 'How can we help you?';

  @override
  String get supportFormDescription =>
      'Fill out the form below and our team will get back to you shortly.';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get fullNameRequiredLabel => 'Full Name *';

  @override
  String get fullNameValidation => 'Please enter your full name';

  @override
  String get emailOrPhoneRequired => 'Provide either an email or phone number';

  @override
  String get phoneRequiredIfEmailEmpty => 'Required if phone number is empty';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get inquiryDetails => 'Inquiry Details';

  @override
  String get inquiryTopicRequiredLabel => 'Inquiry Topic *';

  @override
  String get yourMessageRequiredLabel => 'Your Message *';

  @override
  String get messageValidation => 'Please enter your message';

  @override
  String get counterOffer => 'Counter offer';

  @override
  String get legalDocumentLoadError =>
      'Error loading document. Please try again later.';

  @override
  String get termsLoadError =>
      'Failed to load Terms & Conditions. Please try again later.';

  @override
  String get startupLoadingMode => 'Loading app mode...';

  @override
  String get startupRestoringSession => 'Restoring session...';

  @override
  String get startupRestoringOtp => 'Restoring OTP session...';

  @override
  String get startupRefreshingSession => 'Refreshing session...';

  @override
  String get startupLoadingProfile => 'Loading profile...';

  @override
  String get startupFinalizing => 'Finalizing...';

  @override
  String get done => 'Done';

  @override
  String get offerDetails => 'Offer Details';

  @override
  String get cancelOffer => 'Cancel Offer';

  @override
  String get invalidOrExpiredOtp => 'Invalid or expired OTP';

  @override
  String resendOtpIn(int seconds) {
    return 'Resend OTP in $seconds seconds';
  }

  @override
  String otpRetryIn(int seconds) {
    return 'You can request another code in $seconds seconds';
  }

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get equipmentRenting => 'Equipment Renting';

  @override
  String get getStartedWithProkat => 'Get Started with Prokat';

  @override
  String get guestSignInDescription =>
      'Sign in to browse equipment, contact owners directly, and place orders in a few taps.';

  @override
  String get equipmentSubmittedForReview => 'Equipment submitted for review';

  @override
  String get equipmentDeleted => 'Equipment deleted';

  @override
  String get failedToDeleteEquipment => 'Failed to delete equipment';

  @override
  String get moderatorReview => 'Moderator Review';

  @override
  String get resubmit => 'Resubmit';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get owner => 'Owner';

  @override
  String get specification => 'Specification';

  @override
  String get pleaseProvideRequiredInformation =>
      'Please provide required information';

  @override
  String failedToLoadMessage(String message) {
    return 'Failed to load: $message';
  }

  @override
  String get selectValue => 'Select';

  @override
  String noEquipmentForCategory(String category) {
    return 'There are no $category listed at the moment.';
  }

  @override
  String noEquipmentListedInCity(String category, String city) {
    return 'There are no $category listed in $city at the moment.';
  }

  @override
  String equipmentIsNow(String status) {
    return 'Equipment is now $status';
  }

  @override
  String failedToToggleEquipment(String status) {
    return 'Failed to set equipment $status';
  }

  @override
  String get requestReceived => 'Request Received';

  @override
  String get legalNoticePrefix => 'By continuing, you accept the ';

  @override
  String get userAgreement => 'User Agreement';

  @override
  String get legalNoticeAfterAgreement => ', acknowledge the ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get legalNoticeAfterPrivacy => ', and consent to the ';

  @override
  String get personalDataConsent =>
      'collection and processing of your personal data';

  @override
  String get legalNoticeSuffix => '.';

  @override
  String get ok => 'OK';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get initiateAccountDeletion => 'Initiate Account Deletion';

  @override
  String get failedToRequestAccountDeletion =>
      'Failed to request account deletion. Please try again.';

  @override
  String get accountDeletionScheduledBody =>
      'Your account is now safely scheduled for deletion.\n\nYou will be signed out immediately. Logging back in during the 14-day hold period will cancel the deletion request.';

  @override
  String get accountDeletionConfirmationBody =>
      'Your account will immediately enter Pending Deletion status.\n\nTo protect against accidental data loss, your data will be permanently deleted after a 14-day hold period.';

  @override
  String get permanentlyDeleteAccount => 'Permanently Delete Account';

  @override
  String get accountDeletionHoldDescription =>
      'This starts a 14-day hold period. You can cancel deletion by logging back in before it ends.';

  @override
  String get failedToLoadVersion => 'Failed to load version';

  @override
  String versionLabel(String version, String buildNumber) {
    return 'Version: $version ($buildNumber)';
  }

  @override
  String get markCompletedQuestion => 'Mark completed?';

  @override
  String get markCompleted => 'Mark completed';

  @override
  String get clientConfirmCompletion =>
      'The client will need to confirm completion.';

  @override
  String get confirmCompletionQuestion => 'Confirm completion?';

  @override
  String get confirmCompletionPrompt => 'Confirm the work is completed.';

  @override
  String get notYet => 'Not yet';

  @override
  String get errorLoadingBooking => 'Error loading booking';

  @override
  String get errorLoadingRequest => 'Error loading request';

  @override
  String get errorLoadingOffer => 'Error loading offer';

  @override
  String get failedToLoadNegotiation => 'Failed to load negotiation';

  @override
  String get failedToLoadChat => 'Failed to load chat';

  @override
  String get offer => 'Offer';

  @override
  String get support => 'Support';

  @override
  String get service => 'Service';

  @override
  String get deletePriceEntry => 'Delete Price Entry';

  @override
  String get deletePriceEntryConfirmation =>
      'Are you sure you want to delete this price entry?';

  @override
  String get loginRequired => 'Login is required';

  @override
  String get loginRequiredToViewEquipment =>
      'You need to login to view details and reserve equipment.';

  @override
  String get reviewOwner => 'Review owner';

  @override
  String get reviewClient => 'Review client';

  @override
  String get requestAccepted => 'Request Accepted';

  @override
  String get requestRejected => 'Request Rejected';

  @override
  String get requestPending => 'Request Pending';

  @override
  String get estimatedExhaustion => 'Est. exhaustion';

  @override
  String get enterValidPrice => 'Enter a valid price';

  @override
  String get requiredIfEmailEmpty => 'Required if email is empty';

  @override
  String get submitInquiry => 'Submit Inquiry';

  @override
  String get couldNotLoadServices => 'Could not load services';

  @override
  String get noServicesFound => 'No services found';

  @override
  String get noServicesAvailable =>
      'There are no services listed at the moment';

  @override
  String get applicationSettings => 'Application Settings';

  @override
  String get userGuides => 'User Guides';

  @override
  String get submitTopUpRequest => 'Submit Top Up Request';

  @override
  String get selectStars => 'Select stars';

  @override
  String get commentOptional => 'Comment (optional)';

  @override
  String get completeWork => 'Complete Work';

  @override
  String get submitReview => 'Submit Review';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get notFound => 'Not Found';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get notification => 'Notification';

  @override
  String get typeMessageHint => 'Type a message...';

  @override
  String get rejectPrice => 'Reject Price';

  @override
  String get acceptPrice => 'Accept Price';

  @override
  String get cancelPrice => 'Cancel Price';

  @override
  String get hideRequest => 'Hide Request';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get review => 'Review';

  @override
  String get saved => 'Saved';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get errorLoadingEquipment => 'Error Loading Equipment';

  @override
  String get priceMustBePositive => 'Price must be greater than zero';

  @override
  String get priceMaximumExceeded => 'Price cannot exceed 100,000';

  @override
  String get notSupportedYet => 'Not supported yet';

  @override
  String get errorLoadingProfile => 'Failed to load profile';

  @override
  String get tapToRetry => 'Tap to retry';

  @override
  String get announcements => 'Announcements';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get unknownEquipment => 'Unknown Equipment';

  @override
  String get pending => 'Pending';

  @override
  String get orderConfirmed => 'Order Confirmed';

  @override
  String get failedToConfirmOrder => 'Failed to confirm order';

  @override
  String get chatLocked => 'Chat locked';

  @override
  String get priceOffer => 'Price Offer';

  @override
  String offeredPrice(String price) {
    return 'Offered: $price';
  }

  @override
  String get topUpAdded => 'Top up added';

  @override
  String get failedToCompleteTopUp => 'Failed to complete top up';

  @override
  String get remainingTime => 'Remaining Time';

  @override
  String get bestValue => 'BEST VALUE';

  @override
  String activeRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active requests',
      one: '1 active request',
    );
    return '$_temp0';
  }

  @override
  String minutesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min read',
      one: '1 min read',
    );
    return '$_temp0';
  }

  @override
  String get pleaseSelectCategory => 'Please select category';

  @override
  String get pleaseSelectEquipment => 'Please select equipment';

  @override
  String get pleaseSelectPrice => 'Please select price';

  @override
  String get pleaseSelectLocation => 'Please select location';

  @override
  String get pleaseSelectDate => 'Please select date';

  @override
  String get pleaseSelectTime => 'Please select time';

  @override
  String get noRequestHistory => 'You don\'t have any requests in your history';

  @override
  String get noOrderHistoryDescription =>
      'You don\'t have any orders in your history';

  @override
  String get reviewSubmitted => 'Review Submitted';

  @override
  String get failedToSubmitReview => 'Failed to submit review';

  @override
  String get failedToCancelOrder => 'Failed to cancel order';

  @override
  String get failedToCancelRequest => 'Failed to cancel request';

  @override
  String get saveFailed => 'Failed to save';

  @override
  String get heroPlatformTag => 'KAZAKHSTAN\'S #1 RENTAL PLATFORM';

  @override
  String get heroTitle => 'Find & rent equipment\nin minutes';

  @override
  String get allLocations => 'All Locations';

  @override
  String get getStarted => 'Get Started';

  @override
  String get services => 'Services';

  @override
  String get seeAll => 'See all';

  @override
  String get popularRents => 'Popular rents';

  @override
  String get errorLoadingServices => 'Error loading services';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get topRated => 'Top rated';

  @override
  String get available => 'Available';

  @override
  String get perDay => '/ day';

  @override
  String get heavyEquipmentRentals => 'HEAVY EQUIPMENT RENTALS';

  @override
  String get initializingSystems => 'INITIALIZING SYSTEMS...';

  @override
  String get serverWarmingUp => 'Server is warming up, please wait...';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get send => 'Send';

  @override
  String get submit => 'Submit';

  @override
  String get upload => 'Upload';

  @override
  String get create => 'Create';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get manage => 'Manage';

  @override
  String get viewAll => 'View All';

  @override
  String get goBack => 'Go Back';

  @override
  String get search => 'Search';

  @override
  String get repeat => 'Repeat';

  @override
  String get crop => 'Crop';

  @override
  String get somethingWentWrong => 'Something went wrong!';

  @override
  String get loading => 'Loading...';

  @override
  String get noCategories => 'No categories available';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get username => 'Username';

  @override
  String get city => 'City';

  @override
  String get street => 'Street';

  @override
  String get address => 'Address';

  @override
  String get model => 'Model';

  @override
  String get capacity => 'Capacity';

  @override
  String get comments => 'Comments';

  @override
  String get message => 'Message';

  @override
  String get name => 'Name';

  @override
  String get fullName => 'Full Name';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get offeredRate => 'Offered rate';

  @override
  String get location => 'Location';

  @override
  String get dateAndTime => 'Date & time';

  @override
  String get priceKZT => 'Price (₸)';

  @override
  String get priceRateLabel => 'Price Rate';

  @override
  String get privateOwner => 'PRIVATE OWNER';

  @override
  String get loginSubtitle => 'Pick up where you left off';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get sendOtp => 'Send Code';

  @override
  String get verifying => 'Verifying...';

  @override
  String get verifyOtp => 'Verify Code';

  @override
  String get changePhoneNumber => 'Change Phone Number';

  @override
  String get registrationFailed => 'Registration failed. Try again.';

  @override
  String get otpSubtitle => 'Enter the 6-digit code sent to';

  @override
  String get creating => 'CREATING...';

  @override
  String get sendCode => 'SEND CODE';

  @override
  String get sending => 'SENDING...';

  @override
  String get pleaseEnterPhone => 'Please enter your phone number';

  @override
  String get validKazakhPhone =>
      'Enter a valid Kazakhstan phone (+7XXXXXXXXXX)';

  @override
  String get failedSendOtp => 'Failed to send OTP. Please try again.';

  @override
  String get pleaseEnterBothFields => 'Please enter both username and password';

  @override
  String get pleaseEnterOtp => 'Please enter the verification code';

  @override
  String get otpMustBeSixDigits => 'The OTP must be 6 digits';

  @override
  String get invalidExpiredOtp => 'Invalid or expired OTP';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinCommunity => 'Join the Prokat community today';

  @override
  String get registerWithPhone => 'Register with Phone instead';

  @override
  String get useEmailPassword => 'Use Email & Password';

  @override
  String get alreadyRegistered => 'Already Registered?';

  @override
  String get loginLink => 'Login';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String get sendRecoveryLink => 'SEND RECOVERY LINK';

  @override
  String get backToLogin => 'BACK TO LOGIN';

  @override
  String get resendLink => 'Resend Link';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get pleaseEnterEmail => 'Please enter your email address';

  @override
  String get pleaseEnterAllFields => 'Please fill in all registration fields';

  @override
  String get enterRegisteredEmail =>
      'Enter your registered email below to receive a password reset link.';

  @override
  String recoverySentTo(String email) {
    return 'We\'ve sent a recovery link to $email';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navMyFleet => 'My Fleet';

  @override
  String get navOrders => 'Orders';

  @override
  String get navChats => 'Chats';

  @override
  String get navSearch => 'Search';

  @override
  String get navCreate => 'Create';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navMap => 'Map';

  @override
  String get navMyRequests => 'My Requests';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navMyOrders => 'My Orders';

  @override
  String get navEquipment => 'Equipment';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navRequests => 'Requests';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get navLogin => 'Login';

  @override
  String get selectService => 'Select Service';

  @override
  String get myOrders => 'My Orders';

  @override
  String get orderHistory => 'Order History';

  @override
  String get loginToViewBookings => 'Login to create and view bookings';

  @override
  String get loadingOrders => 'Loading Orders...';

  @override
  String get errorLoadingOrders => 'Error Loading Orders';

  @override
  String get noBookingsFound => 'No bookings found';

  @override
  String get updateWorkStatus => 'Update Work Status';

  @override
  String get statusUpdated => 'Status updated';

  @override
  String get failedSaveStatus => 'Failed to save status';

  @override
  String get confirmOrder => 'Confirm Order';

  @override
  String get counter => 'Counter';

  @override
  String get acceptOrder => 'Accept Order';

  @override
  String get startWork => 'Start Work';

  @override
  String get orderCancelled => 'Order Cancelled';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get confirmCancellation => 'Confirm Cancellation';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get acceptOrderQuestion => 'Accept Order?';

  @override
  String get openIn2GIS => 'Open in 2GIS';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get noActiveOrders => 'No active orders';

  @override
  String get draftIncomplete => 'DRAFT INCOMPLETE';

  @override
  String get finishBookingRequest => 'Finish your booking request';

  @override
  String get resume => 'RESUME';

  @override
  String get rejectOrder => 'Reject Order';

  @override
  String get rejectOrderQuestion =>
      'Are you sure you want to reject this order?';

  @override
  String get cancelOrderQuestion =>
      'Are you sure you want to cancel this order?';

  @override
  String get acceptOrderConfirmation =>
      'Are you sure you want to accept this order?';

  @override
  String acceptBookingFor(String name) {
    return 'Accept booking for $name?';
  }

  @override
  String get yesReject => 'Yes, Reject';

  @override
  String get no => 'No';

  @override
  String get decline => 'Decline';

  @override
  String minutesLeft(int minutes) {
    return '$minutes min left';
  }

  @override
  String get volume => 'Volume';

  @override
  String get noOrderHistory => 'No order history yet';

  @override
  String get cancelReasonClientNotRespond => 'Client did not respond';

  @override
  String get cancelReasonEquipUnavailable => 'Equipment unavailable';

  @override
  String get cancelReasonPricingIssue => 'Pricing issue';

  @override
  String get cancelReasonSchedulingConflict => 'Scheduling conflict';

  @override
  String get cancelReasonDidNotShowUp => 'Did not show up';

  @override
  String get cancelReasonChangedMind => 'Changed my mind';

  @override
  String get cancelReasonEquipNotSuitable => 'Equipment not suitable';

  @override
  String get cancelReasonOther => 'Other';

  @override
  String get workStatusPending => 'Pending';

  @override
  String get workStatusOnMyWay => 'On my way';

  @override
  String get workStatusOnSite => 'On site';

  @override
  String get workStatusStartWork => 'Start work';

  @override
  String get workStatusPostpone => 'Postpone';

  @override
  String get workStatusStopWork => 'Stop work';

  @override
  String get workStatusCompleteWork => 'Complete work';

  @override
  String get workStatusCancelJob => 'Cancel job';

  @override
  String get myEquipment => 'My Equipment';

  @override
  String get addEquipment => 'Add Equipment';

  @override
  String get noEquipmentListed => 'No equipment listed yet';

  @override
  String get online => 'ONLINE';

  @override
  String get offline => 'OFFLINE';

  @override
  String get repair => 'REPAIR';

  @override
  String get couldNotAddEquipment => 'Could not add equipment';

  @override
  String get equipmentNameLabel => 'EQUIPMENT NAME';

  @override
  String get equipmentNameHint => 'e.g. Septic Truck';

  @override
  String get modelLabel => 'MODEL';

  @override
  String get modelHint => 'e.g. KAMAZ-65115';

  @override
  String get plateNumberLabel => 'PLATE NUMBER';

  @override
  String get plateNumberHint => 'e.g. 777 ABC 01';

  @override
  String get availableForRent => 'Available for rent';

  @override
  String get operatingStatus => 'Operating status';

  @override
  String get submitForReview => 'Submit for Review';

  @override
  String get submittedForReview => 'Equipment submitted for review';

  @override
  String get failedToSubmit => 'Failed to submit';

  @override
  String get equipmentUpdated => 'Equipment Updated';

  @override
  String get pleaseEnterValidValues => 'Please enter valid values';

  @override
  String get equipmentUpdatedSuccessfully => 'Equipment updated successfully';

  @override
  String get failedToUpdateEquipment => 'Failed to update equipment';

  @override
  String get editEquipment => 'Edit Equipment';

  @override
  String get ownerComment => 'Owner Comment';

  @override
  String get rentCondition => 'Rent Condition';

  @override
  String get fullLoadOnly => 'Full load only...';

  @override
  String get commentNotes => 'Comment / Notes';

  @override
  String get cropEquipmentPhoto => 'Crop equipment photo';

  @override
  String get deletePhotoQuestion => 'Delete photo?';

  @override
  String get deletePhotoConfirmation => 'This action cannot be undone.';

  @override
  String get failedAddPriceEntry => 'Failed to add price entry';

  @override
  String get failedUpdatePriceEntry => 'Failed to update price entry';

  @override
  String get failedSavePriceEntry => 'Failed to save price entry';

  @override
  String get couldNotSaveEquipment => 'Could not save equipment';

  @override
  String get viewAllLocations => 'View all locations';

  @override
  String get addAddressManually => 'Add address manually';

  @override
  String get setOnMap => 'Set on map';

  @override
  String get noPricesListed => 'No Prices Listed';

  @override
  String get bookEquipment => 'Book';

  @override
  String get requestEquipment => 'Request';

  @override
  String get perHour => '/ hour';

  @override
  String get perTrip => '/ trip';

  @override
  String get retryNow => 'Retry Now';

  @override
  String get selectCity => 'Select City';

  @override
  String get required => 'REQUIRED';

  @override
  String get equipmentAdded => 'Equipment Added';

  @override
  String get updateDetails => 'Update Details';

  @override
  String get status => 'Status';

  @override
  String get perM3 => '/ m³';

  @override
  String get myRequests => 'My Requests';

  @override
  String get createRequest => 'Create Request';

  @override
  String get loginToViewRequests => 'Login to create and view requests';

  @override
  String get errorLoadingRequests => 'Error loading requests';

  @override
  String get noActiveRequests => 'You don\'t have any active requests';

  @override
  String get createNewRequest => 'Create a new request';

  @override
  String get requiredCapacity => 'Required Capacity';

  @override
  String get capacityHint => '10 M3';

  @override
  String get offeredRateHint => 'Price you\'re willing to pay';

  @override
  String get additionalDetails => 'Additional details...';

  @override
  String get newRequestBadge => 'NEW REQUEST';

  @override
  String get offerSentBadge => 'OFFER SENT';

  @override
  String get cancelRequest => 'Cancel Request?';

  @override
  String get requestCancelled => 'Request cancelled';

  @override
  String get noChats => 'No Chats';

  @override
  String get deliverTo => 'DELIVER TO';

  @override
  String get houseBuilding => 'House / Building / Staircase';

  @override
  String get myHouseHint => 'My House';

  @override
  String get streetHint => 'Stapayeva 123';

  @override
  String get cityHint => 'Atyrau';

  @override
  String get saveLocation => 'Save Location';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get failedCreateAddress => 'Could not create address';

  @override
  String get failedSaveAddress => 'Failed to save address';

  @override
  String get noEquipmentLocations => 'No equipment locations yet';

  @override
  String get equipmentLocations => 'Equipment Locations';

  @override
  String get searchAddress => 'Search address';

  @override
  String get setDeliveryAddress => 'Set Delivery Address';

  @override
  String get setEquipmentLocation => 'Set Equipment Location';

  @override
  String get equipmentMap => 'Equipment Map';

  @override
  String get failedCreateLocation => 'Failed to create location';

  @override
  String get loginToViewFavorites => 'Login to add and view favorites';

  @override
  String get displayName => 'Display Name';

  @override
  String get supportUsTitle => 'Support Us';

  @override
  String get donateOrHelp => 'Donate or help us grow';

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get helpSupportTitle => 'Help & Support';

  @override
  String get preferences => 'PREFERENCES';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get bookingAlerts => 'Alerts for new bookings & requests';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get secureAccess => 'Secure access with FaceID/TouchID';

  @override
  String get supportSection => 'SUPPORT';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get accountSection => 'ACCOUNT';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get editPhone => 'Edit Phone';

  @override
  String get editName => 'Edit Name';

  @override
  String get setUsername => 'Set Username';

  @override
  String get ownerDashboard => 'Owner Dashboard';

  @override
  String get becomeOwner => 'Become an Owner';

  @override
  String get registrationStatus => 'Registration Status';

  @override
  String get appSettings => 'App Settings';

  @override
  String get paymentsBalance => 'Payments & Balance';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get save15Percent => 'Save 15%';

  @override
  String get topUpMinutes => 'Top Up Minutes';

  @override
  String get payWithKaspi => 'Pay with Kaspi.kz';

  @override
  String get submitManualRequest => 'Submit Manual Request (Offline Pay)';

  @override
  String get legalInformation => 'Legal Information';

  @override
  String get documents => 'Documents';

  @override
  String get idPassport => 'ID / Passport';

  @override
  String get proofOfAddress => 'Proof of Address';

  @override
  String get businessLicense => 'Business License (optional)';

  @override
  String get firstNameHint => 'Enter your first name';

  @override
  String get lastNameHint => 'Enter your last name';

  @override
  String get phoneHint => 'Enter your phone number';

  @override
  String get emailHint => 'Enter your email (optional)';

  @override
  String get cityInputHint => 'Enter your city';

  @override
  String get camera => 'Camera';

  @override
  String get photoGallery => 'Photo Gallery';

  @override
  String get cropProfilePicture => 'Crop Profile Picture';

  @override
  String get initializationError => 'INITIALIZATION ERROR';

  @override
  String get initializationErrorMessage =>
      'We couldn\'t load your session or connection was lost. Please check your network and try again.';

  @override
  String get retryConnection => 'RETRY CONNECTION';

  @override
  String get reconnecting => 'RECONNECTING...';

  @override
  String get information => 'Information';

  @override
  String get prices => 'Prices';

  @override
  String get allRatingOptionsListed => 'All Rating Options Listed';

  @override
  String get pleaseEnterValidPrice => 'Please enter a valid price';

  @override
  String get priceEntryAdded => 'Price entry added';

  @override
  String get priceEntrySaved => 'Price entry saved';

  @override
  String get editRate => 'Edit Rate';

  @override
  String get newRate => 'New Rate';

  @override
  String get add => 'Add';

  @override
  String get technicalSpecs => 'Technical Specs';

  @override
  String get pleaseFillMissingInfo => 'Please provide missing information';

  @override
  String get noSpecsConfigured => 'No specs configured yet';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get updateFailed => 'Update Failed';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get enterLocation => 'Enter Location';

  @override
  String get equipmentBaseLocation => 'Equipment base location';

  @override
  String get dangerZone => 'DANGER ZONE';

  @override
  String get deleteEquipmentWarning =>
      'Deleting this equipment will permanently remove it from your inventory, including all pricing and history.';

  @override
  String get deleteEquipment => 'Delete Equipment';

  @override
  String get deleteEquipmentQuestion => 'Delete Equipment?';

  @override
  String get deleteEquipmentConfirmation =>
      'This will remove the item from the marketplace and delete all its rental history.';

  @override
  String get failedToUploadPhoto => 'Failed to upload photo';

  @override
  String get failedToDeletePhoto => 'Failed to delete photo';

  @override
  String get failedToSetCoverPhoto => 'Failed to set cover photo';

  @override
  String get maxPhotosReached => 'Max 5 photos reached';

  @override
  String get noPhotosYet => 'No photos yet';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get noSavedLocations => 'No saved locations yet';

  @override
  String get createNewOnMap => 'Create new on map';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get setAsCover => 'Set as cover';

  @override
  String get deletePhoto => 'Delete photo';

  @override
  String get cancelRequestAction => 'Cancel Request';

  @override
  String get cancelRequestContent =>
      'Are you sure you want to cancel this request? This action cannot be undone.';

  @override
  String get newRequest => 'New Request';

  @override
  String get deliveryLocation => 'Delivery Location';

  @override
  String get equipmentSpecs => 'Equipment Specs';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectTime => 'Select Time';

  @override
  String get requestCreated => 'Request created';

  @override
  String get noRequestsAtMoment => 'No requests at the moment';

  @override
  String get viewBooking => 'View Booking';

  @override
  String get viewOffer => 'View Offer';

  @override
  String get sendOffer => 'Send Offer';

  @override
  String get offerUpdated => 'Offer Updated';

  @override
  String get selectEquipment => 'Select equipment';

  @override
  String get startDate => 'Start Date';

  @override
  String get startTime => 'Start Time';

  @override
  String get optionalNotesHint => 'Optional notes or terms...';

  @override
  String get pastRequests => 'PAST REQUESTS';

  @override
  String get requestsHistory => 'Requests History';

  @override
  String get activeRequestsTooltip => 'Active Requests';

  @override
  String get noHistoryFound => 'No history found';

  @override
  String get viewedBadge => 'VIEWED';

  @override
  String get acceptedBadge => 'ACCEPTED';

  @override
  String get hiddenBadge => 'HIDDEN';

  @override
  String get requestLabel => 'Request';

  @override
  String get addLocation => 'Add Location';

  @override
  String get addAddress => 'Add Address';

  @override
  String get addressCreated => 'Address created';

  @override
  String get selectAddress => 'SELECT ADDRESS';

  @override
  String get noRecentAddresses => 'No recent addresses';

  @override
  String get chooseOnMap => 'CHOOSE ON MAP';

  @override
  String get hardwareRestriction => 'HARDWARE RESTRICTION';

  @override
  String get mapMobileOnly => 'Map view is available on mobile devices only.';

  @override
  String get viewEquipmentList => 'View equipment list';

  @override
  String get saveAddress => 'Save Address';

  @override
  String get back => 'Back';

  @override
  String get backToEquipment => 'Back to equipment';

  @override
  String get selectCapacityModel => 'SELECT CAPACITY / MODEL';

  @override
  String get pricingRates => 'PRICING RATES';

  @override
  String get startBooking => 'START BOOKING';

  @override
  String get addDisplayName => 'Add Display Name';

  @override
  String get helpSupportSubtitle => 'Get help or contact support';

  @override
  String get ownerDashboardSubtitle => 'Manage your assets and earnings';

  @override
  String get becomeOwnerSubtitle => 'Start earning by listing your equipment';

  @override
  String get requestStatus => 'Request';

  @override
  String get submittedOn => 'Submitted on';

  @override
  String get nameUpdated => 'Name Updated';

  @override
  String get failedSaveName => 'Failed to save name';

  @override
  String get usernameCannotBeChanged => 'Username cannot be changed once set.';

  @override
  String get chooseUsername => 'Choose a username. This can only be set once.';

  @override
  String get logoutFailed => 'Logout failed';

  @override
  String get activeOrders => 'Active Orders';

  @override
  String get noOrdersYet => 'No Orders Yet';

  @override
  String get enterName => 'Enter name';

  @override
  String get zeroOrders => '0 orders';

  @override
  String get newOrderCount => 'new order';

  @override
  String get confirmedOrderCount => 'confirmed order';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get billingTiers => 'Billing Tiers';

  @override
  String get runningLow => 'Running low?';

  @override
  String get topUpViaKaspi => 'Top up minutes via Kaspi';

  @override
  String get usageTrend => 'Usage Trend';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get verifiedOwner => 'Verified Owner';

  @override
  String get appSettingsSubtitle => 'Notifications, Privacy, Theme';

  @override
  String get helpFaqsSubtitle => 'FAQs, Contact Support';

  @override
  String get fullyVerified => 'Account';

  @override
  String get activeEquipment => 'Active Equipment';

  @override
  String get dailyCost => 'Daily cost';

  @override
  String get ownerProfile => 'Owner Profile';

  @override
  String get selectPackage => 'Select Package';

  @override
  String get recentPayments => 'Recent Payments';

  @override
  String get completeRegistration => 'Complete your registration';

  @override
  String get submitDocumentsHint =>
      'Submit required documents to start listing equipment.';

  @override
  String get verificationInProgress => 'Verification in progress';

  @override
  String get reviewingDocuments => 'We are reviewing your documents.';

  @override
  String get youAreVerified => 'You\'re verified!';

  @override
  String get canListEquipment => 'You can now list and rent out equipment.';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get updateDocumentsHint =>
      'Please update your documents and try again.';

  @override
  String get submitForVerification => 'Submit for Verification';

  @override
  String get underReview => 'Under Review';

  @override
  String get viewListings => 'View Listings';

  @override
  String get resubmitDocuments => 'Resubmit Documents';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get requiredDoc => 'Required';

  @override
  String get becomeServiceProvider => 'Become a service provider';

  @override
  String get joinTeamHint =>
      'Join our team and offer your equipment or services to clients.';

  @override
  String get requestReviewedHint =>
      'Your request will be reviewed by the admin for further processing.';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get messageHint =>
      'Briefly describe the service or equipment you can provide.';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get phoneNumberRequired => 'Phone number is required';

  @override
  String get cityRequired => 'City is required';

  @override
  String get messageRequired => 'Please add a short message';

  @override
  String get submitRequest => 'Submit request';

  @override
  String get resubmitRequest => 'Resubmit request';

  @override
  String get updateRequest => 'Update request';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusAcceptedSubtitle =>
      'You are now approved as a service provider.';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusRejectedSubtitle =>
      'Please review the admin comment and update your request.';

  @override
  String get statusUnderReview => 'Under review';

  @override
  String get statusUnderReviewSubtitle =>
      'Your request has been submitted and is being reviewed.';

  @override
  String get adminComment => 'Admin comment';

  @override
  String get requestAcceptedInfo =>
      'Your request has been accepted. If you need to change your details, contact support.';

  @override
  String get noteDescribeHint =>
      'Note: please describe your service/equipment briefly so we can review your request faster.';

  @override
  String get requestSubmitted => 'Request submitted';

  @override
  String get requestUpdated => 'Request updated';

  @override
  String get notifications => 'Notifications';

  @override
  String get newBookingRequests => 'New booking requests';

  @override
  String get messages => 'Messages';

  @override
  String get reminders => 'Reminders';

  @override
  String get safetyAndRules => 'Safety & Rules';

  @override
  String get cancellationPolicy => 'Cancellation policy';

  @override
  String get moderate => 'Moderate';

  @override
  String get damagePolicy => 'Damage policy';

  @override
  String get standardCoverage => 'Standard coverage';

  @override
  String get deactivateAccount => 'Deactivate account';

  @override
  String get clientRequests => 'Client Requests';

  @override
  String get noNewRequests => 'No new requests at the moment';

  @override
  String get newRequestSingular => 'new request';

  @override
  String get newRequestsPlural => 'new requests';

  @override
  String get noOrders => 'No Orders';

  @override
  String get orderUnit => 'Order';

  @override
  String get ordersUnit => 'Orders';

  @override
  String get myFleet => 'My fleet';

  @override
  String get equipmentItemSingular => 'Item';

  @override
  String get equipmentItemsPlural => 'Items';

  @override
  String get noItemsTapToAdd => 'No items • Tap to add';

  @override
  String get noEquipmentFound => 'No equipment found';

  @override
  String get onlineStatus => 'Online';

  @override
  String get offlineStatus => 'Offline';

  @override
  String get minutesBalance => 'Minutes Balance';

  @override
  String get minutesUnit => 'Min';

  @override
  String get burnRate => 'Burn Rate';

  @override
  String get hello => 'Hello!';

  @override
  String get reviews => 'reviews';

  @override
  String get rentAnEquipment => 'Rent an equipment';

  @override
  String get findAndRent => 'Find & Rent';

  @override
  String get browseHeavyEquipment => 'Browse heavy equipment near you';

  @override
  String get poa => 'POA';

  @override
  String get loginToAddFavorites => 'Login to add and view favorites';

  @override
  String get noSavedMachinery => 'NO SAVED MACHINERY';

  @override
  String get exploreFleet => 'EXPLORE FLEET';

  @override
  String get unknownLocation => 'Unknown location';

  @override
  String get noPrice => 'No price';

  @override
  String get myFavorites => 'My Favorites';

  @override
  String get favoritesEmptyHint => 'Items you favorite will appear here';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get needMoreHelp => 'Need more help?';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get emailSupport => 'Email Support';

  @override
  String get usingProkat => 'Using Prokat';

  @override
  String get learnHowPlatformWorks => 'Learn how the platform works';

  @override
  String get paymentsAndPricing => 'Payments & Pricing';

  @override
  String get feesPayoutsBilling => 'Fees, payouts, and billing';

  @override
  String get safetyAndTrust => 'Safety & Trust';

  @override
  String get guidelinesAndPolicies => 'Guidelines and policies';

  @override
  String get accountHelp => 'Account Help';

  @override
  String get loginProfileSettings => 'Login, profile, and settings';

  @override
  String get liveChat => 'Live Chat';

  @override
  String get callUs => 'Call Us';

  @override
  String get faq1Q => 'How do I rent equipment?';

  @override
  String get faq1A =>
      'Browse available equipment, select your dates, and send a booking request to the owner.';

  @override
  String get faq2Q => 'How do I list my equipment?';

  @override
  String get faq2A =>
      'Go to your profile and tap \'Add Equipment\'. Fill in details, pricing, and location.';

  @override
  String get faq3Q => 'How do payments work?';

  @override
  String get faq3A =>
      'Payments are handled securely through the platform. You\'ll see the total before confirming.';

  @override
  String get faq4Q => 'Can I cancel a booking?';

  @override
  String get faq4A =>
      'Yes, depending on the owner\'s cancellation policy shown on the equipment page.';

  @override
  String get faq5Q => 'What if equipment is damaged?';

  @override
  String get faq5A =>
      'Report the issue through the app immediately. Our support team will assist you.';

  @override
  String get helpUsGrow => 'Help Us Grow';

  @override
  String get theSimpleStuff => 'The Simple Stuff';

  @override
  String get rateOnStore => 'Rate us on the Store';

  @override
  String get starReviewsHint => '5-star reviews help others find us.';

  @override
  String get rateNow => 'Rate Now';

  @override
  String get spreadTheWord => 'Spread the Word';

  @override
  String get shareAppHint => 'Share the app with a friend who needs gear.';

  @override
  String get shareApp => 'Share App';

  @override
  String get contributeToApp => 'Contribute to the App';

  @override
  String get betaTestFeedback => 'Beta Test & Feedback';

  @override
  String get reportBugsHint => 'Report bugs or suggest new rental features.';

  @override
  String get submitIdeas => 'Submit Ideas';

  @override
  String get joinOurTeam => 'Join our Team';

  @override
  String get lookingForDevelopers =>
      'We are looking for developers & ops help.';

  @override
  String get viewCareers => 'View Careers';

  @override
  String get fuelTheMission => 'Fuel the Mission';

  @override
  String get buyDevsACoffee => 'Buy the Devs a Coffee';

  @override
  String get tipToKeepServersHint => 'A small tip to keep the servers running.';

  @override
  String get donate => 'Donate';

  @override
  String get buildingTogether => 'We are building this together';

  @override
  String get missionStatement =>
      'Our mission is to make equipment accessible to everyone. Here is how you can help us get there.';

  @override
  String get legalStuff => 'The Legal Stuff';

  @override
  String get lastUpdated => 'Last Updated: May 2026';

  @override
  String get rentalEligibilityTitle => '1. Rental Eligibility';

  @override
  String get rentalEligibilitySummary =>
      'You must be 18+ and have a valid ID to rent heavy machinery.';

  @override
  String get rentalEligibilityContent =>
      'By using this app, you represent that you are at least 18 years of age and possess the legal authority to enter into this agreement. Certain high-value equipment may require additional verification or specialized licenses.';

  @override
  String get damageLiabilityTitle => '2. Damage & Liability';

  @override
  String get damageLiabilitySummary =>
      'You are responsible for the gear while you have it.';

  @override
  String get damageLiabilityContent =>
      'Equipment must be returned in the condition it was received. You accept full responsibility for any damage, loss, or theft. Ordinary wear and tear is accepted, but negligence is not covered.';

  @override
  String get lateReturnsTitle => '3. Late Returns & Fees';

  @override
  String get lateReturnsSummary =>
      'Return it on time or extra daily rates apply.';

  @override
  String get lateReturnsContent =>
      'Late returns disrupt other users. If equipment is not returned by the agreed deadline, you will be charged the daily rental rate for every 24-hour period until the item is returned.';

  @override
  String get cancellationsTitle => '4. Cancellations';

  @override
  String get cancellationsSummary =>
      'Full refund if cancelled 24 hours in advance.';

  @override
  String get cancellationsContent =>
      'Cancellations made within 24 hours of the rental start time may be subject to a 50% convenience fee. No-shows will be charged the full rental amount.';

  @override
  String get termsAcceptanceNotice =>
      'By continuing to use the Equipment Rental App, you acknowledge that you have read and agree to be bound by these terms.';

  @override
  String get couldNotLoadChats => 'Could not load chats';

  @override
  String get youHaveNoChats => 'You don\'t have any chats';

  @override
  String get error => 'Error';

  @override
  String get price => 'Price';

  @override
  String get book => 'Book';

  @override
  String get viewRequests => 'View Requests';

  @override
  String get couldNotLoadOrders => 'Could not load orders';

  @override
  String get currentOrdersWillAppearHere =>
      'Your current orders will appear here';

  @override
  String get requestedBy => 'Requested by';

  @override
  String get sendCounterOffer => 'Send Counter Offer';

  @override
  String get newPrice => 'New Price';

  @override
  String get noEquipmentAvailable => 'No equipment available';

  @override
  String get searchEquipment => 'Search equipment...';

  @override
  String get couldNotLoadEquipment => 'Couldn\'t load equipment';

  @override
  String get selectEquipmentLocation => 'Select Equipment Location';

  @override
  String get noEquipmentMatchingCategory =>
      'We couldn\'t find any items matching this category at the moment.';

  @override
  String get cancelOrderConfirmation =>
      'Are you sure you want to cancel this order?';

  @override
  String get loadEquipmentErrorHint =>
      'We ran into an issue loading the list. Please try again.';

  @override
  String get createBooking => 'Create Booking';

  @override
  String get loginToBook => 'Login to book this equipment';

  @override
  String get equipmentNotFound => 'Equipment not found';

  @override
  String get servicePlan => 'Service Plan';

  @override
  String get addressAndSchedule => 'Address & Schedule';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get noteToOperator => 'Note to Operator';

  @override
  String get siteAccessHint => 'Site access details, conditions...';

  @override
  String get clientBookingDetails => 'Client Booking Details';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get reserveNow => 'Reserve Now';

  @override
  String get postWhatAndGetOffers => 'Post what you need and get offers';

  @override
  String get bookingRequestLabel => 'BOOKING REQUEST';

  @override
  String get newOrder => 'New Order';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusRequestSent => 'Request Sent';

  @override
  String get statusOffersReceived => 'Offers Received';

  @override
  String get statusBookingCreated => 'Booking Created';

  @override
  String get statusExpired => 'Expired';

  @override
  String get unknownRenter => 'Unknown Renter';

  @override
  String get pendingDate => 'Pending Date';

  @override
  String get overdue => 'Overdue';

  @override
  String get details => 'Details';

  @override
  String get demandSurveyCardTitle => 'Other equipment?';

  @override
  String get demandSurveyCardSubtitle => 'Tell us what you need';

  @override
  String get demandSurveyQuestionTitle => 'What equipment do you need?';

  @override
  String get demandSurveyQuestionSubtitle =>
      'Select one or more options or describe another type.';

  @override
  String get demandSurveyCityLabel => 'City';

  @override
  String get demandSurveySelectCity => 'Select a city';

  @override
  String get demandSurveyOtherOption => 'Other equipment';

  @override
  String get demandSurveyOtherHint => 'Describe the equipment';

  @override
  String get demandSurveySubmit => 'Submit';

  @override
  String get demandSurveyThankYou => 'Thank you. Your response was saved.';

  @override
  String get demandSurveyLoadError => 'The survey is unavailable right now.';

  @override
  String get demandSurveySubmitError => 'Check the form and try again.';

  @override
  String get demandSurveyAlreadySubmitted => 'You have already responded.';

  @override
  String get demandSurveyInactive => 'This survey is no longer active.';

  @override
  String get aboutProkat => 'About Prokat';

  @override
  String get aboutProkatEyebrow => 'EQUIPMENT RENTAL MADE SIMPLE';

  @override
  String get aboutProkatIntro =>
      'Prokat connects people looking for equipment with trusted local owners and service providers. Search, compare and communicate directly in one simple platform.';

  @override
  String get aboutFeatureSearchTitle => 'Easy equipment search';

  @override
  String get aboutFeatureSearchDescription =>
      'Find suitable equipment and trusted local service providers.';

  @override
  String get aboutFeatureTrustedTitle => 'Trusted providers';

  @override
  String get aboutFeatureTrustedDescription =>
      'Equipment owners and service providers are reviewed before approval.';

  @override
  String get aboutFeatureRatingsTitle => 'Two-way ratings';

  @override
  String get aboutFeatureRatingsDescription =>
      'Clients and owners build trust through transparent reviews.';

  @override
  String get newToProkat => 'NEW TO PROKAT?';

  @override
  String get exploreHowItWorks => 'Explore How It Works';

  @override
  String get aboutProkatBannerSubtitle =>
      'Find or rent heavy equipment and trusted service providers instantly in one tap.';

  @override
  String get userConsent => 'User Consent';

  @override
  String get privacyPolicySubtitle => 'How we collect and use your data';

  @override
  String get userAgreementSubtitle => 'Rules for using the platform';

  @override
  String get personalDataSharingSubtitle => 'Sharing of personal data';

  @override
  String get applicationTheme => 'Application theme';

  @override
  String get themeChooseHint => 'Choose how Prokat should look on this device.';

  @override
  String get themeSystemDefault => 'System default';

  @override
  String get themeSystemDefaultSubtitle => 'Match your device appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightSubtitle => 'Always use the light appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkSubtitle => 'Always use the dark appearance';

  @override
  String get serviceAndSafetyNotices => 'Service and safety notices';

  @override
  String get serviceAndSafetyNoticesSubtitle =>
      'Account, security and important platform alerts';

  @override
  String get ownerServiceAndSafetyNoticesSubtitle =>
      'Security, account restrictions and urgent platform notices';

  @override
  String get requiredNoticesAlwaysAvailable =>
      'These notices are always available in the app.';

  @override
  String get checkingPermission => 'Checking permission';

  @override
  String get pushEnabled => 'Enabled';

  @override
  String get pushEnabledQuietly => 'Enabled quietly';

  @override
  String get pushBlocked => 'Blocked';

  @override
  String get pushNotEnabled => 'Not enabled';

  @override
  String get pushUnavailable => 'Unavailable';

  @override
  String get pushEnabledInDeviceSettings => 'Enabled in device settings';

  @override
  String get pushBlockedInDeviceSettings => 'Blocked in device settings';

  @override
  String get pushPermissionNotRequested => 'Permission not requested';

  @override
  String get pushPermissionUnavailable => 'Permission unavailable';

  @override
  String get failedToSaveNotificationPreferences =>
      'Failed to save notification preferences.';

  @override
  String get notifRentalRequestsAndOffers => 'Rental requests and offers';

  @override
  String get notifRentalRequestsAndOffersSubtitle =>
      'New offers, counteroffers and request updates';

  @override
  String get notifOrderUpdates => 'Order updates';

  @override
  String get notifOrderUpdatesSubtitle =>
      'Confirmations, cancellations and status changes';

  @override
  String get notifWorkProgress => 'Work progress';

  @override
  String get notifWorkProgressSubtitle =>
      'Owner on the way, arrived, started or completed';

  @override
  String get notifMessagesSubtitle => 'New chat and negotiation messages';

  @override
  String get notifRemindersAndReviews => 'Reminders and reviews';

  @override
  String get notifRemindersAndReviewsSubtitle =>
      'Upcoming rentals and review reminders';

  @override
  String get notifRequestsAndOffers => 'Requests and offers';

  @override
  String get notifRequestsAndOffersSubtitle =>
      'New rental requests, offer decisions and negotiations';

  @override
  String get notifOrdersAndWorkProgress => 'Orders and work progress';

  @override
  String get notifOrdersAndWorkProgressSubtitle =>
      'Confirmations, cancellations and work-status changes';

  @override
  String get notifOwnerMessagesSubtitle =>
      'New client and negotiation messages';

  @override
  String get notifEquipmentAndVerification => 'Equipment and verification';

  @override
  String get notifEquipmentAndVerificationSubtitle =>
      'Equipment moderation, documents and profile status';

  @override
  String get notifBalanceAlerts => 'Balance alerts';

  @override
  String get notifBalanceAlertsSubtitle =>
      'Low balance, top-up and payment-status alerts';

  @override
  String get noAddressSelected => 'No address selected';

  @override
  String get selectedAddress => 'Selected address';

  @override
  String get youHaveNoSavedAddresses => 'You have no saved addresses.';

  @override
  String get manageMyAddresses => 'Manage my addresses';

  @override
  String get addressPrivacy => 'Address privacy';

  @override
  String get addressPrivacyBody =>
      'Your selected address is shared only with the equipment owner during an active order when it is needed to fulfil the rental. It is not displayed publicly or shared with other users.';

  @override
  String get morePrivacyOptionsContactSupport =>
      'More privacy options? Contact support';

  @override
  String get businessPreferences => 'Business preferences';

  @override
  String get businessProfile => 'Business profile';

  @override
  String get manageMyEquipment => 'Manage my equipment';

  @override
  String get noEquipmentAdded => 'No equipment added';

  @override
  String fleetItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items in your fleet',
      one: '$count item in your fleet',
    );
    return '$_temp0';
  }

  @override
  String get organization => 'Organization';

  @override
  String get individualOwner => 'Individual owner';

  @override
  String get chatSection => 'Chat';

  @override
  String get chatContext => 'Context';

  @override
  String get participant => 'Participant';

  @override
  String get chatId => 'Chat ID';

  @override
  String get booking => 'Booking';

  @override
  String get notLinked => 'Not linked';

  @override
  String get clientRole => 'Client';

  @override
  String get priceOfferReceived => 'Price Offer Received';

  @override
  String get waitingClientResponse => 'Waiting client response';

  @override
  String get didntReceiveCodeResend => 'Didn\'t receive the code? Resend Now';

  @override
  String get youHaveNoActiveOrders => 'You don\'t have any active orders';

  @override
  String get youHaveNoNotifications => 'You don\'t have any notifications';

  @override
  String get unitCubicMeters => 'M3';

  @override
  String get currencyKzt => 'KZT';

  @override
  String get negotiationIdMissing => 'Negotiation id is missing';

  @override
  String get actionFailed => 'Action failed';

  @override
  String get pleaseSelectYourCity => 'Please select your city';

  @override
  String get connectionTimedOut =>
      'Connection timed out. The server may be warming up — please try again.';

  @override
  String get noConnectionCheckNetwork =>
      'No connection. Check your network and try again.';

  @override
  String get networkErrorTryAgain => 'Network error. Please try again.';

  @override
  String get somethingWentWrongTryAgain =>
      'Something went wrong. Please try again.';
}
