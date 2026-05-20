import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @heroPlatformTag.
  ///
  /// In en, this message translates to:
  /// **'KAZAKHSTAN\'S #1 RENTAL PLATFORM'**
  String get heroPlatformTag;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Find & rent equipment\nin minutes'**
  String get heroTitle;

  /// No description provided for @allLocations.
  ///
  /// In en, this message translates to:
  /// **'All Locations'**
  String get allLocations;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @popularRents.
  ///
  /// In en, this message translates to:
  /// **'Popular rents'**
  String get popularRents;

  /// No description provided for @errorLoadingServices.
  ///
  /// In en, this message translates to:
  /// **'Error loading services'**
  String get errorLoadingServices;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get topRated;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'/ day'**
  String get perDay;

  /// No description provided for @heavyEquipmentRentals.
  ///
  /// In en, this message translates to:
  /// **'HEAVY EQUIPMENT RENTALS'**
  String get heavyEquipmentRentals;

  /// No description provided for @initializingSystems.
  ///
  /// In en, this message translates to:
  /// **'INITIALIZING SYSTEMS...'**
  String get initializingSystems;

  /// No description provided for @serverWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'Server is warming up, please wait...'**
  String get serverWarmingUp;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong!'**
  String get somethingWentWrong;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategories;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @offeredRate.
  ///
  /// In en, this message translates to:
  /// **'Offered rate'**
  String get offeredRate;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get dateAndTime;

  /// No description provided for @priceKZT.
  ///
  /// In en, this message translates to:
  /// **'Price (₸)'**
  String get priceKZT;

  /// No description provided for @priceRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Price Rate'**
  String get priceRateLabel;

  /// No description provided for @privateOwner.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE OWNER'**
  String get privateOwner;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup where you left off'**
  String get loginSubtitle;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendOtp;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyOtp;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Phone Number'**
  String get changePhoneNumber;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Try again.'**
  String get registrationFailed;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to'**
  String get otpSubtitle;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'CREATING...'**
  String get creating;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'SEND CODE'**
  String get sendCode;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'SENDING...'**
  String get sending;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @validKazakhPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Kazakhstan phone (+7XXXXXXXXXX)'**
  String get validKazakhPhone;

  /// No description provided for @failedSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP. Please try again.'**
  String get failedSendOtp;

  /// No description provided for @pleaseEnterBothFields.
  ///
  /// In en, this message translates to:
  /// **'Please enter both username and password'**
  String get pleaseEnterBothFields;

  /// No description provided for @pleaseEnterOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get pleaseEnterOtp;

  /// No description provided for @otpMustBeSixDigits.
  ///
  /// In en, this message translates to:
  /// **'The OTP must be 6 digits'**
  String get otpMustBeSixDigits;

  /// No description provided for @invalidExpiredOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired OTP'**
  String get invalidExpiredOtp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the Prokat community today'**
  String get joinCommunity;

  /// No description provided for @registerWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Register with Phone instead'**
  String get registerWithPhone;

  /// No description provided for @useEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Use Email & Password'**
  String get useEmailPassword;

  /// No description provided for @alreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Already Registered?'**
  String get alreadyRegistered;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLink;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @sendRecoveryLink.
  ///
  /// In en, this message translates to:
  /// **'SEND RECOVERY LINK'**
  String get sendRecoveryLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'BACK TO LOGIN'**
  String get backToLogin;

  /// No description provided for @resendLink.
  ///
  /// In en, this message translates to:
  /// **'Resend Link'**
  String get resendLink;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all registration fields'**
  String get pleaseEnterAllFields;

  /// No description provided for @enterRegisteredEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email below to receive a password reset link.'**
  String get enterRegisteredEmail;

  /// No description provided for @recoverySentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a recovery link to {email}'**
  String recoverySentTo(String email);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyFleet.
  ///
  /// In en, this message translates to:
  /// **'My Fleet'**
  String get navMyFleet;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get navCreate;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get navMyRequests;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get navMyOrders;

  /// No description provided for @navEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get navEquipment;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get navRequests;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get navLogin;

  /// No description provided for @selectService.
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get selectService;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @loginToViewBookings.
  ///
  /// In en, this message translates to:
  /// **'Login to create and view bookings'**
  String get loginToViewBookings;

  /// No description provided for @loadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Loading Orders...'**
  String get loadingOrders;

  /// No description provided for @errorLoadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Orders'**
  String get errorLoadingOrders;

  /// No description provided for @noBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get noBookingsFound;

  /// No description provided for @updateWorkStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Work Status'**
  String get updateWorkStatus;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get statusUpdated;

  /// No description provided for @failedSaveStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to save status'**
  String get failedSaveStatus;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @counter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get counter;

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrder;

  /// No description provided for @startWork.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get startWork;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order Cancelled'**
  String get orderCancelled;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @confirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get confirmCancellation;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @acceptOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Accept Order?'**
  String get acceptOrderQuestion;

  /// No description provided for @openIn2GIS.
  ///
  /// In en, this message translates to:
  /// **'Open in 2GIS'**
  String get openIn2GIS;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @noActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'No active orders'**
  String get noActiveOrders;

  /// No description provided for @draftIncomplete.
  ///
  /// In en, this message translates to:
  /// **'DRAFT INCOMPLETE'**
  String get draftIncomplete;

  /// No description provided for @finishBookingRequest.
  ///
  /// In en, this message translates to:
  /// **'Finish your booking request'**
  String get finishBookingRequest;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get resume;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @rejectOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this order?'**
  String get rejectOrderQuestion;

  /// No description provided for @cancelOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get cancelOrderQuestion;

  /// No description provided for @acceptOrderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this order?'**
  String get acceptOrderConfirmation;

  /// No description provided for @acceptBookingFor.
  ///
  /// In en, this message translates to:
  /// **'Accept booking for {name}?'**
  String acceptBookingFor(String name);

  /// No description provided for @yesReject.
  ///
  /// In en, this message translates to:
  /// **'Yes, Reject'**
  String get yesReject;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String minutesLeft(int minutes);

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @noOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'No order history yet'**
  String get noOrderHistory;

  /// No description provided for @cancelReasonClientNotRespond.
  ///
  /// In en, this message translates to:
  /// **'Client did not respond'**
  String get cancelReasonClientNotRespond;

  /// No description provided for @cancelReasonEquipUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Equipment unavailable'**
  String get cancelReasonEquipUnavailable;

  /// No description provided for @cancelReasonPricingIssue.
  ///
  /// In en, this message translates to:
  /// **'Pricing issue'**
  String get cancelReasonPricingIssue;

  /// No description provided for @cancelReasonSchedulingConflict.
  ///
  /// In en, this message translates to:
  /// **'Scheduling conflict'**
  String get cancelReasonSchedulingConflict;

  /// No description provided for @cancelReasonDidNotShowUp.
  ///
  /// In en, this message translates to:
  /// **'Did not show up'**
  String get cancelReasonDidNotShowUp;

  /// No description provided for @cancelReasonChangedMind.
  ///
  /// In en, this message translates to:
  /// **'Changed my mind'**
  String get cancelReasonChangedMind;

  /// No description provided for @cancelReasonEquipNotSuitable.
  ///
  /// In en, this message translates to:
  /// **'Equipment not suitable'**
  String get cancelReasonEquipNotSuitable;

  /// No description provided for @cancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cancelReasonOther;

  /// No description provided for @workStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get workStatusPending;

  /// No description provided for @workStatusOnMyWay.
  ///
  /// In en, this message translates to:
  /// **'On my way'**
  String get workStatusOnMyWay;

  /// No description provided for @workStatusOnSite.
  ///
  /// In en, this message translates to:
  /// **'On site'**
  String get workStatusOnSite;

  /// No description provided for @workStatusStartWork.
  ///
  /// In en, this message translates to:
  /// **'Start work'**
  String get workStatusStartWork;

  /// No description provided for @workStatusPostpone.
  ///
  /// In en, this message translates to:
  /// **'Postpone'**
  String get workStatusPostpone;

  /// No description provided for @workStatusStopWork.
  ///
  /// In en, this message translates to:
  /// **'Stop work'**
  String get workStatusStopWork;

  /// No description provided for @workStatusCompleteWork.
  ///
  /// In en, this message translates to:
  /// **'Complete work'**
  String get workStatusCompleteWork;

  /// No description provided for @workStatusCancelJob.
  ///
  /// In en, this message translates to:
  /// **'Cancel job'**
  String get workStatusCancelJob;

  /// No description provided for @myEquipment.
  ///
  /// In en, this message translates to:
  /// **'My Equipment'**
  String get myEquipment;

  /// No description provided for @addEquipment.
  ///
  /// In en, this message translates to:
  /// **'Add Equipment'**
  String get addEquipment;

  /// No description provided for @noEquipmentListed.
  ///
  /// In en, this message translates to:
  /// **'No equipment listed yet'**
  String get noEquipmentListed;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get offline;

  /// No description provided for @repair.
  ///
  /// In en, this message translates to:
  /// **'REPAIR'**
  String get repair;

  /// No description provided for @couldNotAddEquipment.
  ///
  /// In en, this message translates to:
  /// **'Could not add equipment'**
  String get couldNotAddEquipment;

  /// No description provided for @equipmentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'EQUIPMENT NAME'**
  String get equipmentNameLabel;

  /// No description provided for @equipmentNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Septic Truck'**
  String get equipmentNameHint;

  /// No description provided for @modelLabel.
  ///
  /// In en, this message translates to:
  /// **'MODEL'**
  String get modelLabel;

  /// No description provided for @modelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. KAMAZ-65115'**
  String get modelHint;

  /// No description provided for @plateNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'PLATE NUMBER'**
  String get plateNumberLabel;

  /// No description provided for @plateNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 777 ABC 01'**
  String get plateNumberHint;

  /// No description provided for @availableForRent.
  ///
  /// In en, this message translates to:
  /// **'Available for rent'**
  String get availableForRent;

  /// No description provided for @operatingStatus.
  ///
  /// In en, this message translates to:
  /// **'Operating status'**
  String get operatingStatus;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get submitForReview;

  /// No description provided for @submittedForReview.
  ///
  /// In en, this message translates to:
  /// **'Equipment submitted for review'**
  String get submittedForReview;

  /// No description provided for @failedToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit'**
  String get failedToSubmit;

  /// No description provided for @equipmentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Equipment Updated'**
  String get equipmentUpdated;

  /// No description provided for @pleaseEnterValidValues.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid values'**
  String get pleaseEnterValidValues;

  /// No description provided for @equipmentUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Equipment updated successfully'**
  String get equipmentUpdatedSuccessfully;

  /// No description provided for @failedToUpdateEquipment.
  ///
  /// In en, this message translates to:
  /// **'Failed to update equipment'**
  String get failedToUpdateEquipment;

  /// No description provided for @editEquipment.
  ///
  /// In en, this message translates to:
  /// **'Edit Equipment'**
  String get editEquipment;

  /// No description provided for @ownerComment.
  ///
  /// In en, this message translates to:
  /// **'Owner Comment'**
  String get ownerComment;

  /// No description provided for @rentCondition.
  ///
  /// In en, this message translates to:
  /// **'Rent Condition'**
  String get rentCondition;

  /// No description provided for @fullLoadOnly.
  ///
  /// In en, this message translates to:
  /// **'Full load only...'**
  String get fullLoadOnly;

  /// No description provided for @commentNotes.
  ///
  /// In en, this message translates to:
  /// **'Comment / Notes'**
  String get commentNotes;

  /// No description provided for @cropEquipmentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Crop equipment photo'**
  String get cropEquipmentPhoto;

  /// No description provided for @deletePhotoQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete photo?'**
  String get deletePhotoQuestion;

  /// No description provided for @deletePhotoConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deletePhotoConfirmation;

  /// No description provided for @failedAddPriceEntry.
  ///
  /// In en, this message translates to:
  /// **'Failed to add price entry'**
  String get failedAddPriceEntry;

  /// No description provided for @failedUpdatePriceEntry.
  ///
  /// In en, this message translates to:
  /// **'Failed to update price entry'**
  String get failedUpdatePriceEntry;

  /// No description provided for @failedSavePriceEntry.
  ///
  /// In en, this message translates to:
  /// **'Failed to save price entry'**
  String get failedSavePriceEntry;

  /// No description provided for @couldNotSaveEquipment.
  ///
  /// In en, this message translates to:
  /// **'Could not save equipment'**
  String get couldNotSaveEquipment;

  /// No description provided for @viewAllLocations.
  ///
  /// In en, this message translates to:
  /// **'View all locations'**
  String get viewAllLocations;

  /// No description provided for @addAddressManually.
  ///
  /// In en, this message translates to:
  /// **'Add address manually'**
  String get addAddressManually;

  /// No description provided for @setOnMap.
  ///
  /// In en, this message translates to:
  /// **'Set on map'**
  String get setOnMap;

  /// No description provided for @noPricesListed.
  ///
  /// In en, this message translates to:
  /// **'No Prices Listed'**
  String get noPricesListed;

  /// No description provided for @bookEquipment.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get bookEquipment;

  /// No description provided for @requestEquipment.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestEquipment;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'/ hour'**
  String get perHour;

  /// No description provided for @perTrip.
  ///
  /// In en, this message translates to:
  /// **'/ trip'**
  String get perTrip;

  /// No description provided for @retryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry Now'**
  String get retryNow;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'REQUIRED'**
  String get required;

  /// No description provided for @equipmentAdded.
  ///
  /// In en, this message translates to:
  /// **'Equipment Added'**
  String get equipmentAdded;

  /// No description provided for @updateDetails.
  ///
  /// In en, this message translates to:
  /// **'Update Details'**
  String get updateDetails;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @perM3.
  ///
  /// In en, this message translates to:
  /// **'/ m³'**
  String get perM3;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @createRequest.
  ///
  /// In en, this message translates to:
  /// **'Create Request'**
  String get createRequest;

  /// No description provided for @loginToViewRequests.
  ///
  /// In en, this message translates to:
  /// **'Login to create and view requests'**
  String get loginToViewRequests;

  /// No description provided for @errorLoadingRequests.
  ///
  /// In en, this message translates to:
  /// **'Error loading requests'**
  String get errorLoadingRequests;

  /// No description provided for @noActiveRequests.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any active requests'**
  String get noActiveRequests;

  /// No description provided for @createNewRequest.
  ///
  /// In en, this message translates to:
  /// **'Create a new request'**
  String get createNewRequest;

  /// No description provided for @requiredCapacity.
  ///
  /// In en, this message translates to:
  /// **'Required Capacity'**
  String get requiredCapacity;

  /// No description provided for @capacityHint.
  ///
  /// In en, this message translates to:
  /// **'10 M3'**
  String get capacityHint;

  /// No description provided for @offeredRateHint.
  ///
  /// In en, this message translates to:
  /// **'Price you\'re willing to pay'**
  String get offeredRateHint;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional details...'**
  String get additionalDetails;

  /// No description provided for @newRequestBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW REQUEST'**
  String get newRequestBadge;

  /// No description provided for @offerSentBadge.
  ///
  /// In en, this message translates to:
  /// **'OFFER SENT'**
  String get offerSentBadge;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request?'**
  String get cancelRequest;

  /// No description provided for @requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get requestCancelled;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'No Chats'**
  String get noChats;

  /// No description provided for @deliverTo.
  ///
  /// In en, this message translates to:
  /// **'DELIVER TO'**
  String get deliverTo;

  /// No description provided for @houseBuilding.
  ///
  /// In en, this message translates to:
  /// **'House / Building / Staircase'**
  String get houseBuilding;

  /// No description provided for @myHouseHint.
  ///
  /// In en, this message translates to:
  /// **'My House'**
  String get myHouseHint;

  /// No description provided for @streetHint.
  ///
  /// In en, this message translates to:
  /// **'Stapayeva 123'**
  String get streetHint;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'Atyrau'**
  String get cityHint;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get saveLocation;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @failedCreateAddress.
  ///
  /// In en, this message translates to:
  /// **'Could not create address'**
  String get failedCreateAddress;

  /// No description provided for @failedSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Failed to save address'**
  String get failedSaveAddress;

  /// No description provided for @noEquipmentLocations.
  ///
  /// In en, this message translates to:
  /// **'No equipment locations yet'**
  String get noEquipmentLocations;

  /// No description provided for @equipmentLocations.
  ///
  /// In en, this message translates to:
  /// **'Equipment Locations'**
  String get equipmentLocations;

  /// No description provided for @searchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search address'**
  String get searchAddress;

  /// No description provided for @setDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Set Delivery Address'**
  String get setDeliveryAddress;

  /// No description provided for @setEquipmentLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Equipment Location'**
  String get setEquipmentLocation;

  /// No description provided for @equipmentMap.
  ///
  /// In en, this message translates to:
  /// **'Equipment Map'**
  String get equipmentMap;

  /// No description provided for @failedCreateLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to create location'**
  String get failedCreateLocation;

  /// No description provided for @loginToViewFavorites.
  ///
  /// In en, this message translates to:
  /// **'Login to add and view favorites'**
  String get loginToViewFavorites;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @supportUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Us'**
  String get supportUsTitle;

  /// No description provided for @donateOrHelp.
  ///
  /// In en, this message translates to:
  /// **'Donate or help us grow'**
  String get donateOrHelp;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @helpSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportTitle;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferences;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @bookingAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts for new bookings & requests'**
  String get bookingAlerts;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @secureAccess.
  ///
  /// In en, this message translates to:
  /// **'Secure access with FaceID/TouchID'**
  String get secureAccess;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get supportSection;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountSection;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @editPhone.
  ///
  /// In en, this message translates to:
  /// **'Edit Phone'**
  String get editPhone;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @setUsername.
  ///
  /// In en, this message translates to:
  /// **'Set Username'**
  String get setUsername;

  /// No description provided for @ownerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Owner Dashboard'**
  String get ownerDashboard;

  /// No description provided for @becomeOwner.
  ///
  /// In en, this message translates to:
  /// **'Become an Owner'**
  String get becomeOwner;

  /// No description provided for @registrationStatus.
  ///
  /// In en, this message translates to:
  /// **'Registration Status'**
  String get registrationStatus;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @paymentsBalance.
  ///
  /// In en, this message translates to:
  /// **'Payments & Balance'**
  String get paymentsBalance;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @save15Percent.
  ///
  /// In en, this message translates to:
  /// **'Save 15%'**
  String get save15Percent;

  /// No description provided for @topUpMinutes.
  ///
  /// In en, this message translates to:
  /// **'Top Up Minutes'**
  String get topUpMinutes;

  /// No description provided for @payWithKaspi.
  ///
  /// In en, this message translates to:
  /// **'Pay with Kaspi.kz'**
  String get payWithKaspi;

  /// No description provided for @submitManualRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Manual Request (Offline Pay)'**
  String get submitManualRequest;

  /// No description provided for @legalInformation.
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legalInformation;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @idPassport.
  ///
  /// In en, this message translates to:
  /// **'ID / Passport'**
  String get idPassport;

  /// No description provided for @proofOfAddress.
  ///
  /// In en, this message translates to:
  /// **'Proof of Address'**
  String get proofOfAddress;

  /// No description provided for @businessLicense.
  ///
  /// In en, this message translates to:
  /// **'Business License (optional)'**
  String get businessLicense;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get firstNameHint;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get lastNameHint;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneHint;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email (optional)'**
  String get emailHint;

  /// No description provided for @cityInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your city'**
  String get cityInputHint;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo Gallery'**
  String get photoGallery;

  /// No description provided for @cropProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Crop Profile Picture'**
  String get cropProfilePicture;

  /// No description provided for @initializationError.
  ///
  /// In en, this message translates to:
  /// **'INITIALIZATION ERROR'**
  String get initializationError;

  /// No description provided for @initializationErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your session or connection was lost. Please check your network and try again.'**
  String get initializationErrorMessage;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'RETRY CONNECTION'**
  String get retryConnection;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'RECONNECTING...'**
  String get reconnecting;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @prices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get prices;

  /// No description provided for @allRatingOptionsListed.
  ///
  /// In en, this message translates to:
  /// **'All Rating Options Listed'**
  String get allRatingOptionsListed;

  /// No description provided for @pleaseEnterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get pleaseEnterValidPrice;

  /// No description provided for @priceEntryAdded.
  ///
  /// In en, this message translates to:
  /// **'Price entry added'**
  String get priceEntryAdded;

  /// No description provided for @priceEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Price entry saved'**
  String get priceEntrySaved;

  /// No description provided for @editRate.
  ///
  /// In en, this message translates to:
  /// **'Edit Rate'**
  String get editRate;

  /// No description provided for @newRate.
  ///
  /// In en, this message translates to:
  /// **'New Rate'**
  String get newRate;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @technicalSpecs.
  ///
  /// In en, this message translates to:
  /// **'Technical Specs'**
  String get technicalSpecs;

  /// No description provided for @pleaseFillMissingInfo.
  ///
  /// In en, this message translates to:
  /// **'Please provide missing information'**
  String get pleaseFillMissingInfo;

  /// No description provided for @noSpecsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No specs configured yet'**
  String get noSpecsConfigured;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update Failed'**
  String get updateFailed;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @enterLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter Location'**
  String get enterLocation;

  /// No description provided for @equipmentBaseLocation.
  ///
  /// In en, this message translates to:
  /// **'Equipment base location'**
  String get equipmentBaseLocation;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get dangerZone;

  /// No description provided for @deleteEquipmentWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting this equipment will permanently remove it from your inventory, including all pricing and history.'**
  String get deleteEquipmentWarning;

  /// No description provided for @deleteEquipment.
  ///
  /// In en, this message translates to:
  /// **'Delete Equipment'**
  String get deleteEquipment;

  /// No description provided for @deleteEquipmentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Equipment?'**
  String get deleteEquipmentQuestion;

  /// No description provided for @deleteEquipmentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will remove the item from the marketplace and delete all its rental history.'**
  String get deleteEquipmentConfirmation;

  /// No description provided for @failedToUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo'**
  String get failedToUploadPhoto;

  /// No description provided for @failedToDeletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete photo'**
  String get failedToDeletePhoto;

  /// No description provided for @failedToSetCoverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to set cover photo'**
  String get failedToSetCoverPhoto;

  /// No description provided for @maxPhotosReached.
  ///
  /// In en, this message translates to:
  /// **'Max 5 photos reached'**
  String get maxPhotosReached;

  /// No description provided for @noPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get noPhotosYet;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @noSavedLocations.
  ///
  /// In en, this message translates to:
  /// **'No saved locations yet'**
  String get noSavedLocations;

  /// No description provided for @createNewOnMap.
  ///
  /// In en, this message translates to:
  /// **'Create new on map'**
  String get createNewOnMap;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @setAsCover.
  ///
  /// In en, this message translates to:
  /// **'Set as cover'**
  String get setAsCover;

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get deletePhoto;

  /// No description provided for @cancelRequestAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequestAction;

  /// No description provided for @cancelRequestContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this request? This action cannot be undone.'**
  String get cancelRequestContent;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get newRequest;

  /// No description provided for @deliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocation;

  /// No description provided for @equipmentSpecs.
  ///
  /// In en, this message translates to:
  /// **'Equipment Specs'**
  String get equipmentSpecs;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @requestCreated.
  ///
  /// In en, this message translates to:
  /// **'Request created'**
  String get requestCreated;

  /// No description provided for @noRequestsAtMoment.
  ///
  /// In en, this message translates to:
  /// **'No requests at the moment'**
  String get noRequestsAtMoment;

  /// No description provided for @viewBooking.
  ///
  /// In en, this message translates to:
  /// **'View Booking'**
  String get viewBooking;

  /// No description provided for @viewOffer.
  ///
  /// In en, this message translates to:
  /// **'View Offer'**
  String get viewOffer;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send Offer'**
  String get sendOffer;

  /// No description provided for @offerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Offer Updated'**
  String get offerUpdated;

  /// No description provided for @selectEquipment.
  ///
  /// In en, this message translates to:
  /// **'Select equipment'**
  String get selectEquipment;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @optionalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes or terms...'**
  String get optionalNotesHint;

  /// No description provided for @pastRequests.
  ///
  /// In en, this message translates to:
  /// **'PAST REQUESTS'**
  String get pastRequests;

  /// No description provided for @requestsHistory.
  ///
  /// In en, this message translates to:
  /// **'Requests History'**
  String get requestsHistory;

  /// No description provided for @activeRequestsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Active Requests'**
  String get activeRequestsTooltip;

  /// No description provided for @noHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No history found'**
  String get noHistoryFound;

  /// No description provided for @viewedBadge.
  ///
  /// In en, this message translates to:
  /// **'VIEWED'**
  String get viewedBadge;

  /// No description provided for @acceptedBadge.
  ///
  /// In en, this message translates to:
  /// **'ACCEPTED'**
  String get acceptedBadge;

  /// No description provided for @hiddenBadge.
  ///
  /// In en, this message translates to:
  /// **'HIDDEN'**
  String get hiddenBadge;

  /// No description provided for @requestLabel.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestLabel;

  /// No description provided for @addLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get addLocation;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @addressCreated.
  ///
  /// In en, this message translates to:
  /// **'Address created'**
  String get addressCreated;

  /// No description provided for @selectAddress.
  ///
  /// In en, this message translates to:
  /// **'SELECT ADDRESS'**
  String get selectAddress;

  /// No description provided for @noRecentAddresses.
  ///
  /// In en, this message translates to:
  /// **'No recent addresses'**
  String get noRecentAddresses;

  /// No description provided for @chooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE ON MAP'**
  String get chooseOnMap;

  /// No description provided for @hardwareRestriction.
  ///
  /// In en, this message translates to:
  /// **'HARDWARE RESTRICTION'**
  String get hardwareRestriction;

  /// No description provided for @mapMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Map view is available on mobile devices only.'**
  String get mapMobileOnly;

  /// No description provided for @viewEquipmentList.
  ///
  /// In en, this message translates to:
  /// **'View equipment list'**
  String get viewEquipmentList;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddress;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backToEquipment.
  ///
  /// In en, this message translates to:
  /// **'Back to equipment'**
  String get backToEquipment;

  /// No description provided for @selectCapacityModel.
  ///
  /// In en, this message translates to:
  /// **'SELECT CAPACITY / MODEL'**
  String get selectCapacityModel;

  /// No description provided for @pricingRates.
  ///
  /// In en, this message translates to:
  /// **'PRICING RATES'**
  String get pricingRates;

  /// No description provided for @startBooking.
  ///
  /// In en, this message translates to:
  /// **'START BOOKING'**
  String get startBooking;

  /// No description provided for @addDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Add Display Name'**
  String get addDisplayName;

  /// No description provided for @helpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help or contact support'**
  String get helpSupportSubtitle;

  /// No description provided for @ownerDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your assets and earnings'**
  String get ownerDashboardSubtitle;

  /// No description provided for @becomeOwnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start earning by listing your equipment'**
  String get becomeOwnerSubtitle;

  /// No description provided for @requestStatus.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestStatus;

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted on'**
  String get submittedOn;

  /// No description provided for @nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name Updated'**
  String get nameUpdated;

  /// No description provided for @failedSaveName.
  ///
  /// In en, this message translates to:
  /// **'Failed to save name'**
  String get failedSaveName;

  /// No description provided for @usernameCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Username cannot be changed once set.'**
  String get usernameCannotBeChanged;

  /// No description provided for @chooseUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username. This can only be set once.'**
  String get chooseUsername;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @activeOrders.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get activeOrders;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No Orders Yet'**
  String get noOrdersYet;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @zeroOrders.
  ///
  /// In en, this message translates to:
  /// **'0 orders'**
  String get zeroOrders;

  /// No description provided for @newOrderCount.
  ///
  /// In en, this message translates to:
  /// **'new order'**
  String get newOrderCount;

  /// No description provided for @confirmedOrderCount.
  ///
  /// In en, this message translates to:
  /// **'confirmed order'**
  String get confirmedOrderCount;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @billingTiers.
  ///
  /// In en, this message translates to:
  /// **'Billing Tiers'**
  String get billingTiers;

  /// No description provided for @runningLow.
  ///
  /// In en, this message translates to:
  /// **'Running low?'**
  String get runningLow;

  /// No description provided for @topUpViaKaspi.
  ///
  /// In en, this message translates to:
  /// **'Top up minutes via Kaspi'**
  String get topUpViaKaspi;

  /// No description provided for @usageTrend.
  ///
  /// In en, this message translates to:
  /// **'Usage Trend'**
  String get usageTrend;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @verifiedOwner.
  ///
  /// In en, this message translates to:
  /// **'Verified Owner'**
  String get verifiedOwner;

  /// No description provided for @appSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications, Privacy, Theme'**
  String get appSettingsSubtitle;

  /// No description provided for @helpFaqsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs, Contact Support'**
  String get helpFaqsSubtitle;

  /// No description provided for @fullyVerified.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get fullyVerified;

  /// No description provided for @activeEquipment.
  ///
  /// In en, this message translates to:
  /// **'Active Equipment'**
  String get activeEquipment;

  /// No description provided for @dailyCost.
  ///
  /// In en, this message translates to:
  /// **'Daily cost'**
  String get dailyCost;

  /// No description provided for @ownerProfile.
  ///
  /// In en, this message translates to:
  /// **'Owner Profile'**
  String get ownerProfile;

  /// No description provided for @selectPackage.
  ///
  /// In en, this message translates to:
  /// **'Select Package'**
  String get selectPackage;

  /// No description provided for @recentPayments.
  ///
  /// In en, this message translates to:
  /// **'Recent Payments'**
  String get recentPayments;

  /// No description provided for @completeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete your registration'**
  String get completeRegistration;

  /// No description provided for @submitDocumentsHint.
  ///
  /// In en, this message translates to:
  /// **'Submit required documents to start listing equipment.'**
  String get submitDocumentsHint;

  /// No description provided for @verificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Verification in progress'**
  String get verificationInProgress;

  /// No description provided for @reviewingDocuments.
  ///
  /// In en, this message translates to:
  /// **'We are reviewing your documents.'**
  String get reviewingDocuments;

  /// No description provided for @youAreVerified.
  ///
  /// In en, this message translates to:
  /// **'You\'re verified!'**
  String get youAreVerified;

  /// No description provided for @canListEquipment.
  ///
  /// In en, this message translates to:
  /// **'You can now list and rent out equipment.'**
  String get canListEquipment;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @updateDocumentsHint.
  ///
  /// In en, this message translates to:
  /// **'Please update your documents and try again.'**
  String get updateDocumentsHint;

  /// No description provided for @submitForVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitForVerification;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @viewListings.
  ///
  /// In en, this message translates to:
  /// **'View Listings'**
  String get viewListings;

  /// No description provided for @resubmitDocuments.
  ///
  /// In en, this message translates to:
  /// **'Resubmit Documents'**
  String get resubmitDocuments;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @requiredDoc.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredDoc;

  /// No description provided for @becomeServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Become a service provider'**
  String get becomeServiceProvider;

  /// No description provided for @joinTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Join our team and offer your equipment or services to clients.'**
  String get joinTeamHint;

  /// No description provided for @requestReviewedHint.
  ///
  /// In en, this message translates to:
  /// **'Your request will be reviewed by the admin for further processing.'**
  String get requestReviewedHint;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe the service or equipment you can provide.'**
  String get messageHint;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityRequired;

  /// No description provided for @messageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add a short message'**
  String get messageRequired;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get submitRequest;

  /// No description provided for @resubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Resubmit request'**
  String get resubmitRequest;

  /// No description provided for @updateRequest.
  ///
  /// In en, this message translates to:
  /// **'Update request'**
  String get updateRequest;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusAcceptedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You are now approved as a service provider.'**
  String get statusAcceptedSubtitle;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please review the admin comment and update your request.'**
  String get statusRejectedSubtitle;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get statusUnderReview;

  /// No description provided for @statusUnderReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your request has been submitted and is being reviewed.'**
  String get statusUnderReviewSubtitle;

  /// No description provided for @adminComment.
  ///
  /// In en, this message translates to:
  /// **'Admin comment'**
  String get adminComment;

  /// No description provided for @requestAcceptedInfo.
  ///
  /// In en, this message translates to:
  /// **'Your request has been accepted. If you need to change your details, contact support.'**
  String get requestAcceptedInfo;

  /// No description provided for @noteDescribeHint.
  ///
  /// In en, this message translates to:
  /// **'Note: please describe your service/equipment briefly so we can review your request faster.'**
  String get noteDescribeHint;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get requestSubmitted;

  /// No description provided for @requestUpdated.
  ///
  /// In en, this message translates to:
  /// **'Request updated'**
  String get requestUpdated;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @newBookingRequests.
  ///
  /// In en, this message translates to:
  /// **'New booking requests'**
  String get newBookingRequests;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @safetyAndRules.
  ///
  /// In en, this message translates to:
  /// **'Safety & Rules'**
  String get safetyAndRules;

  /// No description provided for @cancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get cancellationPolicy;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @damagePolicy.
  ///
  /// In en, this message translates to:
  /// **'Damage policy'**
  String get damagePolicy;

  /// No description provided for @standardCoverage.
  ///
  /// In en, this message translates to:
  /// **'Standard coverage'**
  String get standardCoverage;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get deactivateAccount;

  /// No description provided for @clientRequests.
  ///
  /// In en, this message translates to:
  /// **'Client Requests'**
  String get clientRequests;

  /// No description provided for @noNewRequests.
  ///
  /// In en, this message translates to:
  /// **'No new requests at the moment'**
  String get noNewRequests;

  /// No description provided for @newRequestSingular.
  ///
  /// In en, this message translates to:
  /// **'new request'**
  String get newRequestSingular;

  /// No description provided for @newRequestsPlural.
  ///
  /// In en, this message translates to:
  /// **'new requests'**
  String get newRequestsPlural;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No Orders'**
  String get noOrders;

  /// No description provided for @orderUnit.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderUnit;

  /// No description provided for @ordersUnit.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersUnit;

  /// No description provided for @myFleet.
  ///
  /// In en, this message translates to:
  /// **'My fleet'**
  String get myFleet;

  /// No description provided for @equipmentItemSingular.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get equipmentItemSingular;

  /// No description provided for @equipmentItemsPlural.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get equipmentItemsPlural;

  /// No description provided for @noItemsTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'No items • Tap to add'**
  String get noItemsTapToAdd;

  /// No description provided for @noEquipmentFound.
  ///
  /// In en, this message translates to:
  /// **'No equipment found'**
  String get noEquipmentFound;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineStatus;

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineStatus;

  /// No description provided for @minutesBalance.
  ///
  /// In en, this message translates to:
  /// **'Minutes Balance'**
  String get minutesBalance;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minutesUnit;

  /// No description provided for @burnRate.
  ///
  /// In en, this message translates to:
  /// **'Burn Rate'**
  String get burnRate;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get hello;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviews;

  /// No description provided for @rentAnEquipment.
  ///
  /// In en, this message translates to:
  /// **'Rent an equipment'**
  String get rentAnEquipment;

  /// No description provided for @findAndRent.
  ///
  /// In en, this message translates to:
  /// **'Find & Rent'**
  String get findAndRent;

  /// No description provided for @browseHeavyEquipment.
  ///
  /// In en, this message translates to:
  /// **'Browse heavy equipment near you'**
  String get browseHeavyEquipment;

  /// No description provided for @poa.
  ///
  /// In en, this message translates to:
  /// **'POA'**
  String get poa;

  /// No description provided for @loginToAddFavorites.
  ///
  /// In en, this message translates to:
  /// **'Login to add and view favorites'**
  String get loginToAddFavorites;

  /// No description provided for @noSavedMachinery.
  ///
  /// In en, this message translates to:
  /// **'NO SAVED MACHINERY'**
  String get noSavedMachinery;

  /// No description provided for @exploreFleet.
  ///
  /// In en, this message translates to:
  /// **'EXPLORE FLEET'**
  String get exploreFleet;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get unknownLocation;

  /// No description provided for @noPrice.
  ///
  /// In en, this message translates to:
  /// **'No price'**
  String get noPrice;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @favoritesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Items you favorite will appear here'**
  String get favoritesEmptyHint;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @needMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Need more help?'**
  String get needMoreHelp;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @usingProkat.
  ///
  /// In en, this message translates to:
  /// **'Using Prokat'**
  String get usingProkat;

  /// No description provided for @learnHowPlatformWorks.
  ///
  /// In en, this message translates to:
  /// **'Learn how the platform works'**
  String get learnHowPlatformWorks;

  /// No description provided for @paymentsAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Payments & Pricing'**
  String get paymentsAndPricing;

  /// No description provided for @feesPayoutsBilling.
  ///
  /// In en, this message translates to:
  /// **'Fees, payouts, and billing'**
  String get feesPayoutsBilling;

  /// No description provided for @safetyAndTrust.
  ///
  /// In en, this message translates to:
  /// **'Safety & Trust'**
  String get safetyAndTrust;

  /// No description provided for @guidelinesAndPolicies.
  ///
  /// In en, this message translates to:
  /// **'Guidelines and policies'**
  String get guidelinesAndPolicies;

  /// No description provided for @accountHelp.
  ///
  /// In en, this message translates to:
  /// **'Account Help'**
  String get accountHelp;

  /// No description provided for @loginProfileSettings.
  ///
  /// In en, this message translates to:
  /// **'Login, profile, and settings'**
  String get loginProfileSettings;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @faq1Q.
  ///
  /// In en, this message translates to:
  /// **'How do I rent equipment?'**
  String get faq1Q;

  /// No description provided for @faq1A.
  ///
  /// In en, this message translates to:
  /// **'Browse available equipment, select your dates, and send a booking request to the owner.'**
  String get faq1A;

  /// No description provided for @faq2Q.
  ///
  /// In en, this message translates to:
  /// **'How do I list my equipment?'**
  String get faq2Q;

  /// No description provided for @faq2A.
  ///
  /// In en, this message translates to:
  /// **'Go to your profile and tap \'Add Equipment\'. Fill in details, pricing, and location.'**
  String get faq2A;

  /// No description provided for @faq3Q.
  ///
  /// In en, this message translates to:
  /// **'How do payments work?'**
  String get faq3Q;

  /// No description provided for @faq3A.
  ///
  /// In en, this message translates to:
  /// **'Payments are handled securely through the platform. You\'ll see the total before confirming.'**
  String get faq3A;

  /// No description provided for @faq4Q.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel a booking?'**
  String get faq4Q;

  /// No description provided for @faq4A.
  ///
  /// In en, this message translates to:
  /// **'Yes, depending on the owner\'s cancellation policy shown on the equipment page.'**
  String get faq4A;

  /// No description provided for @faq5Q.
  ///
  /// In en, this message translates to:
  /// **'What if equipment is damaged?'**
  String get faq5Q;

  /// No description provided for @faq5A.
  ///
  /// In en, this message translates to:
  /// **'Report the issue through the app immediately. Our support team will assist you.'**
  String get faq5A;

  /// No description provided for @helpUsGrow.
  ///
  /// In en, this message translates to:
  /// **'Help Us Grow'**
  String get helpUsGrow;

  /// No description provided for @theSimpleStuff.
  ///
  /// In en, this message translates to:
  /// **'The Simple Stuff'**
  String get theSimpleStuff;

  /// No description provided for @rateOnStore.
  ///
  /// In en, this message translates to:
  /// **'Rate us on the Store'**
  String get rateOnStore;

  /// No description provided for @starReviewsHint.
  ///
  /// In en, this message translates to:
  /// **'5-star reviews help others find us.'**
  String get starReviewsHint;

  /// No description provided for @rateNow.
  ///
  /// In en, this message translates to:
  /// **'Rate Now'**
  String get rateNow;

  /// No description provided for @spreadTheWord.
  ///
  /// In en, this message translates to:
  /// **'Spread the Word'**
  String get spreadTheWord;

  /// No description provided for @shareAppHint.
  ///
  /// In en, this message translates to:
  /// **'Share the app with a friend who needs gear.'**
  String get shareAppHint;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @contributeToApp.
  ///
  /// In en, this message translates to:
  /// **'Contribute to the App'**
  String get contributeToApp;

  /// No description provided for @betaTestFeedback.
  ///
  /// In en, this message translates to:
  /// **'Beta Test & Feedback'**
  String get betaTestFeedback;

  /// No description provided for @reportBugsHint.
  ///
  /// In en, this message translates to:
  /// **'Report bugs or suggest new rental features.'**
  String get reportBugsHint;

  /// No description provided for @submitIdeas.
  ///
  /// In en, this message translates to:
  /// **'Submit Ideas'**
  String get submitIdeas;

  /// No description provided for @joinOurTeam.
  ///
  /// In en, this message translates to:
  /// **'Join our Team'**
  String get joinOurTeam;

  /// No description provided for @lookingForDevelopers.
  ///
  /// In en, this message translates to:
  /// **'We are looking for developers & ops help.'**
  String get lookingForDevelopers;

  /// No description provided for @viewCareers.
  ///
  /// In en, this message translates to:
  /// **'View Careers'**
  String get viewCareers;

  /// No description provided for @fuelTheMission.
  ///
  /// In en, this message translates to:
  /// **'Fuel the Mission'**
  String get fuelTheMission;

  /// No description provided for @buyDevsACoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy the Devs a Coffee'**
  String get buyDevsACoffee;

  /// No description provided for @tipToKeepServersHint.
  ///
  /// In en, this message translates to:
  /// **'A small tip to keep the servers running.'**
  String get tipToKeepServersHint;

  /// No description provided for @donate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// No description provided for @buildingTogether.
  ///
  /// In en, this message translates to:
  /// **'We are building this together'**
  String get buildingTogether;

  /// No description provided for @missionStatement.
  ///
  /// In en, this message translates to:
  /// **'Our mission is to make equipment accessible to everyone. Here is how you can help us get there.'**
  String get missionStatement;

  /// No description provided for @legalStuff.
  ///
  /// In en, this message translates to:
  /// **'The Legal Stuff'**
  String get legalStuff;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated: May 2026'**
  String get lastUpdated;

  /// No description provided for @rentalEligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Rental Eligibility'**
  String get rentalEligibilityTitle;

  /// No description provided for @rentalEligibilitySummary.
  ///
  /// In en, this message translates to:
  /// **'You must be 18+ and have a valid ID to rent heavy machinery.'**
  String get rentalEligibilitySummary;

  /// No description provided for @rentalEligibilityContent.
  ///
  /// In en, this message translates to:
  /// **'By using this app, you represent that you are at least 18 years of age and possess the legal authority to enter into this agreement. Certain high-value equipment may require additional verification or specialized licenses.'**
  String get rentalEligibilityContent;

  /// No description provided for @damageLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Damage & Liability'**
  String get damageLiabilityTitle;

  /// No description provided for @damageLiabilitySummary.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for the gear while you have it.'**
  String get damageLiabilitySummary;

  /// No description provided for @damageLiabilityContent.
  ///
  /// In en, this message translates to:
  /// **'Equipment must be returned in the condition it was received. You accept full responsibility for any damage, loss, or theft. Ordinary wear and tear is accepted, but negligence is not covered.'**
  String get damageLiabilityContent;

  /// No description provided for @lateReturnsTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Late Returns & Fees'**
  String get lateReturnsTitle;

  /// No description provided for @lateReturnsSummary.
  ///
  /// In en, this message translates to:
  /// **'Return it on time or extra daily rates apply.'**
  String get lateReturnsSummary;

  /// No description provided for @lateReturnsContent.
  ///
  /// In en, this message translates to:
  /// **'Late returns disrupt other users. If equipment is not returned by the agreed deadline, you will be charged the daily rental rate for every 24-hour period until the item is returned.'**
  String get lateReturnsContent;

  /// No description provided for @cancellationsTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Cancellations'**
  String get cancellationsTitle;

  /// No description provided for @cancellationsSummary.
  ///
  /// In en, this message translates to:
  /// **'Full refund if cancelled 24 hours in advance.'**
  String get cancellationsSummary;

  /// No description provided for @cancellationsContent.
  ///
  /// In en, this message translates to:
  /// **'Cancellations made within 24 hours of the rental start time may be subject to a 50% convenience fee. No-shows will be charged the full rental amount.'**
  String get cancellationsContent;

  /// No description provided for @termsAcceptanceNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing to use the Equipment Rental App, you acknowledge that you have read and agree to be bound by these terms.'**
  String get termsAcceptanceNotice;

  /// No description provided for @couldNotLoadChats.
  ///
  /// In en, this message translates to:
  /// **'Could not load chats'**
  String get couldNotLoadChats;

  /// No description provided for @youHaveNoChats.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any chats'**
  String get youHaveNoChats;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @viewRequests.
  ///
  /// In en, this message translates to:
  /// **'View Requests'**
  String get viewRequests;

  /// No description provided for @couldNotLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Could not load orders'**
  String get couldNotLoadOrders;

  /// No description provided for @currentOrdersWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your current orders will appear here'**
  String get currentOrdersWillAppearHere;

  /// No description provided for @requestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by'**
  String get requestedBy;

  /// No description provided for @sendCounterOffer.
  ///
  /// In en, this message translates to:
  /// **'Send Counter Offer'**
  String get sendCounterOffer;

  /// No description provided for @newPrice.
  ///
  /// In en, this message translates to:
  /// **'New Price'**
  String get newPrice;

  /// No description provided for @noEquipmentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No equipment available'**
  String get noEquipmentAvailable;

  /// No description provided for @searchEquipment.
  ///
  /// In en, this message translates to:
  /// **'Search equipment...'**
  String get searchEquipment;

  /// No description provided for @couldNotLoadEquipment.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load equipment'**
  String get couldNotLoadEquipment;

  /// No description provided for @selectEquipmentLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Equipment Location'**
  String get selectEquipmentLocation;

  /// No description provided for @noEquipmentMatchingCategory.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any items matching this category at the moment.'**
  String get noEquipmentMatchingCategory;

  /// No description provided for @cancelOrderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get cancelOrderConfirmation;

  /// No description provided for @loadEquipmentErrorHint.
  ///
  /// In en, this message translates to:
  /// **'We ran into an issue loading the list. Please try again.'**
  String get loadEquipmentErrorHint;

  /// No description provided for @createBooking.
  ///
  /// In en, this message translates to:
  /// **'Create Booking'**
  String get createBooking;

  /// No description provided for @loginToBook.
  ///
  /// In en, this message translates to:
  /// **'Login to book this equipment'**
  String get loginToBook;

  /// No description provided for @equipmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Equipment not found'**
  String get equipmentNotFound;

  /// No description provided for @servicePlan.
  ///
  /// In en, this message translates to:
  /// **'Service Plan'**
  String get servicePlan;

  /// No description provided for @addressAndSchedule.
  ///
  /// In en, this message translates to:
  /// **'Address & Schedule'**
  String get addressAndSchedule;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @noteToOperator.
  ///
  /// In en, this message translates to:
  /// **'Note to Operator'**
  String get noteToOperator;

  /// No description provided for @siteAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Site access details, conditions...'**
  String get siteAccessHint;

  /// No description provided for @clientBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Client Booking Details'**
  String get clientBookingDetails;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @reserveNow.
  ///
  /// In en, this message translates to:
  /// **'Reserve Now'**
  String get reserveNow;

  /// No description provided for @postWhatAndGetOffers.
  ///
  /// In en, this message translates to:
  /// **'Post what you need and get offers'**
  String get postWhatAndGetOffers;

  /// No description provided for @bookingRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'BOOKING REQUEST'**
  String get bookingRequestLabel;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrder;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get statusRequestSent;

  /// No description provided for @statusOffersReceived.
  ///
  /// In en, this message translates to:
  /// **'Offers Received'**
  String get statusOffersReceived;

  /// No description provided for @statusBookingCreated.
  ///
  /// In en, this message translates to:
  /// **'Booking Created'**
  String get statusBookingCreated;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
