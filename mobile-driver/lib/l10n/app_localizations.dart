import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_ig.dart';
import 'app_localizations_pcm.dart';
import 'app_localizations_yo.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ha'),
    Locale('ig'),
    Locale('pcm'),
    Locale('yo'),
  ];

  /// D-01–D-03 driver auth branding
  ///
  /// In en, this message translates to:
  /// **'Drive with Along'**
  String get driverBrandingLine;

  /// D-02 heading
  ///
  /// In en, this message translates to:
  /// **'Drive with Along'**
  String get phoneEntryTitle;

  /// D-02 body
  ///
  /// In en, this message translates to:
  /// **'We text a code to this number so your day stays yours.'**
  String get phoneEntrySubtitle;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @legalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get legalPrefix;

  /// No description provided for @termsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsLink;

  /// No description provided for @legalMiddle.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get legalMiddle;

  /// No description provided for @privacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyLink;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String otpTitle(String phone);

  /// No description provided for @wrongNumber.
  ///
  /// In en, this message translates to:
  /// **'Wrong number?'**
  String get wrongNumber;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendCountdown(int seconds);

  /// No description provided for @errorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Nigerian number'**
  String get errorInvalidPhone;

  /// No description provided for @errorWrongOtp.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code — try again'**
  String get errorWrongOtp;

  /// No description provided for @errorExpiredOtp.
  ///
  /// In en, this message translates to:
  /// **'Code expired — request a new one'**
  String get errorExpiredOtp;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s'**
  String errorRateLimited(int seconds);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorAuthNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This build is not connected to Along. Rebuild the staging APK with env/staging.json.'**
  String get errorAuthNotConfigured;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the fields and try again.'**
  String get errorValidation;

  /// No description provided for @errorPlateConflict.
  ///
  /// In en, this message translates to:
  /// **'This plate is already registered.'**
  String get errorPlateConflict;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself'**
  String get profileSubtitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameHint;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender (optional)'**
  String get genderLabel;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderOther;

  /// No description provided for @photoOptional.
  ///
  /// In en, this message translates to:
  /// **'Add photo (optional)'**
  String get photoOptional;

  /// No description provided for @vehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle'**
  String get vehicleTitle;

  /// No description provided for @vehicleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How will you drive on Along?'**
  String get vehicleSubtitle;

  /// No description provided for @plateLabel.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get plateLabel;

  /// No description provided for @plateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ABC-123-XY'**
  String get plateHint;

  /// No description provided for @seatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seatsLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colorLabel;

  /// No description provided for @makeModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Make & model'**
  String get makeModelLabel;

  /// No description provided for @ownerQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is this your vehicle?'**
  String get ownerQuestion;

  /// No description provided for @ownerYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, it\'s mine'**
  String get ownerYes;

  /// No description provided for @ownerNo.
  ///
  /// In en, this message translates to:
  /// **'No, someone else owns it'**
  String get ownerNo;

  /// No description provided for @ownerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get ownerNameLabel;

  /// No description provided for @ownerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner phone'**
  String get ownerPhoneLabel;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your documents'**
  String get documentsTitle;

  /// No description provided for @documentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload each document to start driving'**
  String get documentsSubtitle;

  /// No description provided for @docStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get docStatusNotStarted;

  /// No description provided for @docStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get docStatusPending;

  /// No description provided for @docStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get docStatusApproved;

  /// No description provided for @docStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get docStatusRejected;

  /// No description provided for @saveAndContinueLater.
  ///
  /// In en, this message translates to:
  /// **'Save and continue later'**
  String get saveAndContinueLater;

  /// No description provided for @captureTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture {document}'**
  String captureTitle(String document);

  /// No description provided for @captureGuide.
  ///
  /// In en, this message translates to:
  /// **'Fit the document inside the frame'**
  String get captureGuide;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retakePhoto;

  /// No description provided for @submitDocument.
  ///
  /// In en, this message translates to:
  /// **'Submit document'**
  String get submitDocument;

  /// No description provided for @ocrReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review extracted details'**
  String get ocrReviewTitle;

  /// No description provided for @ocrReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm each field before submitting'**
  String get ocrReviewSubtitle;

  /// No description provided for @ocrSuggestedValue.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {value}'**
  String ocrSuggestedValue(String value);

  /// No description provided for @ocrConfirmField.
  ///
  /// In en, this message translates to:
  /// **'Use this value'**
  String get ocrConfirmField;

  /// No description provided for @ocrFieldConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get ocrFieldConfirmed;

  /// No description provided for @ocrNoAutoFillNote.
  ///
  /// In en, this message translates to:
  /// **'ID numbers are never filled automatically — tap confirm for each field.'**
  String get ocrNoAutoFillNote;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification in progress'**
  String get pendingTitle;

  /// No description provided for @pendingHero.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing your documents'**
  String get pendingHero;

  /// No description provided for @pendingExpectedGeneric.
  ///
  /// In en, this message translates to:
  /// **'This usually takes 1–3 business days'**
  String get pendingExpectedGeneric;

  /// No description provided for @pendingExpectedHours.
  ///
  /// In en, this message translates to:
  /// **'Expected within {hours} hours'**
  String pendingExpectedHours(int hours);

  /// No description provided for @pendingWhatNext.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when you\'re approved. You can set up your route while you wait.'**
  String get pendingWhatNext;

  /// No description provided for @setupRouteCta.
  ///
  /// In en, this message translates to:
  /// **'Set up your route while you wait'**
  String get setupRouteCta;

  /// No description provided for @routesListTitle.
  ///
  /// In en, this message translates to:
  /// **'Your routes'**
  String get routesListTitle;

  /// No description provided for @routesAddRoute.
  ///
  /// In en, this message translates to:
  /// **'Add route'**
  String get routesAddRoute;

  /// No description provided for @routesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your route in a few taps'**
  String get routesEmptyTitle;

  /// No description provided for @routesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Publish your stops and prices so riders can find you on your usual path.'**
  String get routesEmptyBody;

  /// No description provided for @routeSuggestedCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested route'**
  String get routeSuggestedCardTitle;

  /// No description provided for @routeSuggestedCardBody.
  ///
  /// In en, this message translates to:
  /// **'We detected a usual {mode} path with {stopCount} stops.'**
  String routeSuggestedCardBody(String mode, int stopCount);

  /// No description provided for @routeSuggestedCardCta.
  ///
  /// In en, this message translates to:
  /// **'Tap to review and publish'**
  String get routeSuggestedCardCta;

  /// No description provided for @routeUnnamedProfile.
  ///
  /// In en, this message translates to:
  /// **'{mode} route'**
  String routeUnnamedProfile(String mode);

  /// No description provided for @routeStopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String routeStopsCount(int count);

  /// No description provided for @routeLoadSurchargeLabel.
  ///
  /// In en, this message translates to:
  /// **'Load surcharge: {amount}'**
  String routeLoadSurchargeLabel(String amount);

  /// No description provided for @routeLoadSurchargeOptional.
  ///
  /// In en, this message translates to:
  /// **'Load surcharge (optional)'**
  String get routeLoadSurchargeOptional;

  /// No description provided for @routeLoadSurchargeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50'**
  String get routeLoadSurchargeHint;

  /// No description provided for @routeFastSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Route setup'**
  String get routeFastSetupTitle;

  /// No description provided for @routeFastSetupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is this your route?'**
  String get routeFastSetupQuestion;

  /// No description provided for @routeFastSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} stops detected from your usual path'**
  String routeFastSetupSubtitle(int count);

  /// No description provided for @routeYesPublish.
  ///
  /// In en, this message translates to:
  /// **'Yes, publish'**
  String get routeYesPublish;

  /// No description provided for @routeEditPrices.
  ///
  /// In en, this message translates to:
  /// **'Edit prices'**
  String get routeEditPrices;

  /// No description provided for @routeDrawManually.
  ///
  /// In en, this message translates to:
  /// **'No, draw manually'**
  String get routeDrawManually;

  /// No description provided for @routeDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw your route'**
  String get routeDrawTitle;

  /// No description provided for @routeDrawHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to add stops'**
  String get routeDrawHint;

  /// No description provided for @routeDrawEmptyStops.
  ///
  /// In en, this message translates to:
  /// **'Add at least two stops on the map'**
  String get routeDrawEmptyStops;

  /// No description provided for @routePublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get routePublish;

  /// No description provided for @routePriceToEnd.
  ///
  /// In en, this message translates to:
  /// **'To end: {amount}'**
  String routePriceToEnd(String amount);

  /// No description provided for @routeSnapMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched: {name} ✓'**
  String routeSnapMatched(String name);

  /// No description provided for @routeSnapNewStopHint.
  ///
  /// In en, this message translates to:
  /// **'New stop — name?'**
  String get routeSnapNewStopHint;

  /// No description provided for @routeSnapPending.
  ///
  /// In en, this message translates to:
  /// **'Snapping…'**
  String get routeSnapPending;

  /// No description provided for @routePriceKeypadTitle.
  ///
  /// In en, this message translates to:
  /// **'Set price to end'**
  String get routePriceKeypadTitle;

  /// No description provided for @routePriceKeypadSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get routePriceKeypadSet;

  /// No description provided for @routePriceErrorNonMonotone.
  ///
  /// In en, this message translates to:
  /// **'Prices must not increase toward the destination.'**
  String get routePriceErrorNonMonotone;

  /// No description provided for @routePriceErrorLastNotZero.
  ///
  /// In en, this message translates to:
  /// **'Last stop must be ₦0.'**
  String get routePriceErrorLastNotZero;

  /// No description provided for @routePriceErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add at least one priced stop.'**
  String get routePriceErrorEmpty;

  /// No description provided for @routeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load routes.'**
  String get routeLoadError;

  /// No description provided for @routePublishError.
  ///
  /// In en, this message translates to:
  /// **'Could not publish route. Try again.'**
  String get routePublishError;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get navRoutes;

  /// No description provided for @navEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get navEarnings;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @earningsStubBody.
  ///
  /// In en, this message translates to:
  /// **'Earnings and balance coming in Phase 4.'**
  String get earningsStubBody;

  /// No description provided for @accountStubBody.
  ///
  /// In en, this message translates to:
  /// **'Account settings coming soon.'**
  String get accountStubBody;

  /// No description provided for @homeUnverifiedBanner.
  ///
  /// In en, this message translates to:
  /// **'Complete verification to go online.'**
  String get homeUnverifiedBanner;

  /// No description provided for @homeBatteryGuardBanner.
  ///
  /// In en, this message translates to:
  /// **'Battery low — location updates slowed to save power.'**
  String get homeBatteryGuardBanner;

  /// No description provided for @homeLedgerBlockedBanner.
  ///
  /// In en, this message translates to:
  /// **'Matching paused — settle your balance to go online.'**
  String get homeLedgerBlockedBanner;

  /// No description provided for @homeSelectPark.
  ///
  /// In en, this message translates to:
  /// **'At: select park ▾'**
  String get homeSelectPark;

  /// No description provided for @homeAtPark.
  ///
  /// In en, this message translates to:
  /// **'At: {parkName} ▾'**
  String homeAtPark(String parkName);

  /// No description provided for @homeDirectionOnRoute.
  ///
  /// In en, this message translates to:
  /// **'Direction: on my route ▾'**
  String get homeDirectionOnRoute;

  /// No description provided for @homeDirectionNone.
  ///
  /// In en, this message translates to:
  /// **'Direction: none ▾'**
  String get homeDirectionNone;

  /// No description provided for @homeErrorSelectPark.
  ///
  /// In en, this message translates to:
  /// **'Choose a park before going online at park.'**
  String get homeErrorSelectPark;

  /// No description provided for @homeErrorLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable location to go online.'**
  String get homeErrorLocation;

  /// No description provided for @homeParkPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby parks'**
  String get homeParkPickerTitle;

  /// No description provided for @homeParkPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No parks within range.'**
  String get homeParkPickerEmpty;

  /// No description provided for @homeParkDistance.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String homeParkDistance(int meters);

  /// No description provided for @homeParkSomewhereElse.
  ///
  /// In en, this message translates to:
  /// **'I\'m somewhere else'**
  String get homeParkSomewhereElse;

  /// No description provided for @incomingRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get incomingRequestTitle;

  /// No description provided for @incomingRequestCountdown.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String incomingRequestCountdown(int seconds);

  /// No description provided for @incomingRequestRiderLine.
  ///
  /// In en, this message translates to:
  /// **'{name} · {rating} · {trips} trips'**
  String incomingRequestRiderLine(String name, String rating, int trips);

  /// No description provided for @incomingRequestPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get incomingRequestPickup;

  /// No description provided for @incomingRequestRoamingPickup.
  ///
  /// In en, this message translates to:
  /// **'Rider location'**
  String get incomingRequestRoamingPickup;

  /// No description provided for @incomingRequestRoamingPickupMeta.
  ///
  /// In en, this message translates to:
  /// **'Cell hail — meet at pin'**
  String get incomingRequestRoamingPickupMeta;

  /// No description provided for @incomingRequestCascade.
  ///
  /// In en, this message translates to:
  /// **'Retry {attempt} of {max}'**
  String incomingRequestCascade(int attempt, int max);

  /// No description provided for @incomingRequestDropoff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get incomingRequestDropoff;

  /// No description provided for @incomingRequestPickupMeta.
  ///
  /// In en, this message translates to:
  /// **'{distance} m · {eta} min'**
  String incomingRequestPickupMeta(int distance, int eta);

  /// No description provided for @incomingRequestFareLine.
  ///
  /// In en, this message translates to:
  /// **'Rider pays {amount} · {tierLabel}'**
  String incomingRequestFareLine(String amount, String tierLabel);

  /// No description provided for @incomingRequestAlongFee.
  ///
  /// In en, this message translates to:
  /// **'Along fee {amount} · {percent}%, added at drop-off'**
  String incomingRequestAlongFee(String amount, String percent);

  /// No description provided for @incomingRequestLoadDefault.
  ///
  /// In en, this message translates to:
  /// **'Passenger flagged load'**
  String get incomingRequestLoadDefault;

  /// No description provided for @incomingRequestLoadDetail.
  ///
  /// In en, this message translates to:
  /// **'{size} load — {note}'**
  String incomingRequestLoadDetail(String size, String note);

  /// No description provided for @incomingRequestWomenOnly.
  ///
  /// In en, this message translates to:
  /// **'Women-only match'**
  String get incomingRequestWomenOnly;

  /// No description provided for @incomingRequestApproachBandUnder2.
  ///
  /// In en, this message translates to:
  /// **'under 2 min'**
  String get incomingRequestApproachBandUnder2;

  /// No description provided for @incomingRequestApproachBandM2_5.
  ///
  /// In en, this message translates to:
  /// **'2–5 min'**
  String get incomingRequestApproachBandM2_5;

  /// No description provided for @incomingRequestApproachBandOver5.
  ///
  /// In en, this message translates to:
  /// **'5+ min'**
  String get incomingRequestApproachBandOver5;

  /// No description provided for @incomingRequestAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get incomingRequestAccept;

  /// No description provided for @incomingRequestDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get incomingRequestDecline;

  /// No description provided for @declineReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you declining?'**
  String get declineReasonTitle;

  /// No description provided for @declineReasonNoRoomForLoad.
  ///
  /// In en, this message translates to:
  /// **'No room for load'**
  String get declineReasonNoRoomForLoad;

  /// No description provided for @declineReasonTooFar.
  ///
  /// In en, this message translates to:
  /// **'Too far'**
  String get declineReasonTooFar;

  /// No description provided for @declineReasonEndingShift.
  ///
  /// In en, this message translates to:
  /// **'Ending shift'**
  String get declineReasonEndingShift;

  /// No description provided for @declineReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get declineReasonOther;

  /// No description provided for @fareTierStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard fare'**
  String get fareTierStandard;

  /// No description provided for @fareTierCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community fare'**
  String get fareTierCommunity;

  /// No description provided for @fareTierProfile.
  ///
  /// In en, this message translates to:
  /// **'Driver price'**
  String get fareTierProfile;

  /// No description provided for @fareTierEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate — agree price'**
  String get fareTierEstimate;

  /// No description provided for @pricingRiderOffer.
  ///
  /// In en, this message translates to:
  /// **'Rider offered {amount}'**
  String pricingRiderOffer(String amount);

  /// No description provided for @pricingLapsed.
  ///
  /// In en, this message translates to:
  /// **'No agreement — rider may choose another vehicle'**
  String get pricingLapsed;

  /// No description provided for @pricingOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Vehicle has passed — negotiation closed'**
  String get pricingOutOfRange;

  /// No description provided for @pricingDeclined.
  ///
  /// In en, this message translates to:
  /// **'You declined this fare'**
  String get pricingDeclined;

  /// No description provided for @pricingDismiss.
  ///
  /// In en, this message translates to:
  /// **'Back to map'**
  String get pricingDismiss;

  /// No description provided for @manifestTitle.
  ///
  /// In en, this message translates to:
  /// **'Active trips'**
  String get manifestTitle;

  /// No description provided for @manifestEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accepted riders yet'**
  String get manifestEmpty;

  /// No description provided for @manifestBoarding.
  ///
  /// In en, this message translates to:
  /// **'Boarding: {stage}'**
  String manifestBoarding(String stage);

  /// No description provided for @manifestStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String manifestStatus(String status);

  /// No description provided for @manifestMarkBoarded.
  ///
  /// In en, this message translates to:
  /// **'Boarded'**
  String get manifestMarkBoarded;

  /// No description provided for @manifestOpen.
  ///
  /// In en, this message translates to:
  /// **'Active trips ({count})'**
  String manifestOpen(int count);

  /// No description provided for @activeTripStart.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get activeTripStart;

  /// No description provided for @activeTripComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete trip'**
  String get activeTripComplete;

  /// No description provided for @activeTripBoardAlight.
  ///
  /// In en, this message translates to:
  /// **'{board} → {alight}'**
  String activeTripBoardAlight(String board, String alight);

  /// No description provided for @activeTripWalkEta.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min walk'**
  String activeTripWalkEta(int minutes);

  /// No description provided for @activeTripStalledCaption.
  ///
  /// In en, this message translates to:
  /// **'not moving closer'**
  String get activeTripStalledCaption;

  /// No description provided for @activeTripRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get activeTripRelease;

  /// No description provided for @activeTripReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get activeTripReport;

  /// No description provided for @sosTeamAlerted.
  ///
  /// In en, this message translates to:
  /// **'Ready to call 112'**
  String get sosTeamAlerted;

  /// No description provided for @sosSharingDetails.
  ///
  /// In en, this message translates to:
  /// **'Share your live location with your contacts'**
  String get sosSharingDetails;

  /// No description provided for @sosCallEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String sosCallEmergency(String number);

  /// No description provided for @sosHoldToCancel.
  ///
  /// In en, this message translates to:
  /// **'Hold to cancel'**
  String get sosHoldToCancel;

  /// No description provided for @sosRaising.
  ///
  /// In en, this message translates to:
  /// **'Opening the 112 call…'**
  String get sosRaising;

  /// No description provided for @sosRaiseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the 112 call'**
  String get sosRaiseFailed;

  /// No description provided for @sosRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get sosRetry;

  /// No description provided for @reportIncidentTitle.
  ///
  /// In en, this message translates to:
  /// **'Report incident'**
  String get reportIncidentTitle;

  /// No description provided for @reportIncidentCategoryHeading.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get reportIncidentCategoryHeading;

  /// No description provided for @reportIncidentDescriptionHeading.
  ///
  /// In en, this message translates to:
  /// **'Tell us more'**
  String get reportIncidentDescriptionHeading;

  /// No description provided for @reportIncidentDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened (optional details help)'**
  String get reportIncidentDescriptionHint;

  /// No description provided for @reportIncidentAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get reportIncidentAttachPhoto;

  /// No description provided for @reportIncidentPhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'Photo attached (stub)'**
  String get reportIncidentPhotoAttached;

  /// No description provided for @reportIncidentSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportIncidentSubmit;

  /// No description provided for @reportIncidentPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get reportIncidentPickCategory;

  /// No description provided for @reportIncidentDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a short description'**
  String get reportIncidentDescriptionRequired;

  /// No description provided for @reportIncidentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report saved on this phone'**
  String get reportIncidentSubmitted;

  /// No description provided for @incidentCategorySafety.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get incidentCategorySafety;

  /// No description provided for @incidentCategoryFareDispute.
  ///
  /// In en, this message translates to:
  /// **'Fare dispute'**
  String get incidentCategoryFareDispute;

  /// No description provided for @incidentCategoryVehicleQuality.
  ///
  /// In en, this message translates to:
  /// **'Vehicle quality'**
  String get incidentCategoryVehicleQuality;

  /// No description provided for @incidentCategoryDriverBehavior.
  ///
  /// In en, this message translates to:
  /// **'Driver behavior'**
  String get incidentCategoryDriverBehavior;

  /// No description provided for @incidentCategoryLostItem.
  ///
  /// In en, this message translates to:
  /// **'Lost item'**
  String get incidentCategoryLostItem;

  /// No description provided for @incidentCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get incidentCategoryOther;

  /// No description provided for @accountProfileHeading.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get accountProfileHeading;

  /// No description provided for @accountProfileUnknown.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get accountProfileUnknown;

  /// No description provided for @accountVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get accountVerified;

  /// No description provided for @accountUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get accountUnverified;

  /// No description provided for @accountVehicleHeading.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE'**
  String get accountVehicleHeading;

  /// No description provided for @accountVehicleActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Active vehicle'**
  String get accountVehicleActiveHint;

  /// No description provided for @accountVehicleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add your vehicle'**
  String get accountVehicleEmpty;

  /// No description provided for @accountVehicleSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Contact support to switch active vehicle'**
  String get accountVehicleSwitchHint;

  /// No description provided for @accountDocumentsHeading.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENTS'**
  String get accountDocumentsHeading;

  /// No description provided for @accountDocumentsAllApproved.
  ///
  /// In en, this message translates to:
  /// **'All documents approved'**
  String get accountDocumentsAllApproved;

  /// No description provided for @accountDocumentsPending.
  ///
  /// In en, this message translates to:
  /// **'Documents pending review'**
  String get accountDocumentsPending;

  /// No description provided for @accountDocumentsNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Some documents need attention'**
  String get accountDocumentsNeedsAttention;

  /// No description provided for @accountDocumentsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Documents incomplete'**
  String get accountDocumentsIncomplete;

  /// No description provided for @accountDocumentsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Document status unavailable'**
  String get accountDocumentsUnknown;

  /// No description provided for @accountPayoutHeading.
  ///
  /// In en, this message translates to:
  /// **'PAYOUT'**
  String get accountPayoutHeading;

  /// No description provided for @accountPayoutBank.
  ///
  /// In en, this message translates to:
  /// **'Payout bank'**
  String get accountPayoutBank;

  /// No description provided for @accountPayoutConfigured.
  ///
  /// In en, this message translates to:
  /// **'Bank ending {last4}'**
  String accountPayoutConfigured(String last4);

  /// No description provided for @accountPayoutNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Set up your payout bank'**
  String get accountPayoutNotConfigured;

  /// No description provided for @accountPreferencesHeading.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get accountPreferencesHeading;

  /// D-24 city switcher label
  ///
  /// In en, this message translates to:
  /// **'Operating city'**
  String get accountCityLabel;

  /// D-24 city switcher hint
  ///
  /// In en, this message translates to:
  /// **'Map, parks, and demand use this city'**
  String get accountCityHint;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @accountLanguageValue.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get accountLanguageValue;

  /// No description provided for @accountSafetyHeading.
  ///
  /// In en, this message translates to:
  /// **'SAFETY'**
  String get accountSafetyHeading;

  /// No description provided for @accountSafetyHowSos.
  ///
  /// In en, this message translates to:
  /// **'How SOS works'**
  String get accountSafetyHowSos;

  /// No description provided for @accountSafetyHowSosBody.
  ///
  /// In en, this message translates to:
  /// **'Hold SOS to call 112 and share your location with contacts'**
  String get accountSafetyHowSosBody;

  /// No description provided for @accountHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get accountHelp;

  /// No description provided for @accountLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get accountLegal;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @homeLedgerBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Matching paused'**
  String get homeLedgerBlockedTitle;

  /// No description provided for @homeLedgerBlockedBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String homeLedgerBlockedBalance(String amount);

  /// No description provided for @homeLedgerBlockedThreshold.
  ///
  /// In en, this message translates to:
  /// **'Block limit {amount}'**
  String homeLedgerBlockedThreshold(String amount);

  /// No description provided for @settleCta.
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get settleCta;

  /// No description provided for @settleTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle balance'**
  String get settleTitle;

  /// No description provided for @settleCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance: {amount}'**
  String settleCurrentBalance(String amount);

  /// No description provided for @settleAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to pay'**
  String get settleAmountLabel;

  /// No description provided for @settleChannelBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get settleChannelBank;

  /// No description provided for @settleChannelUssd.
  ///
  /// In en, this message translates to:
  /// **'USSD'**
  String get settleChannelUssd;

  /// No description provided for @settleChannelCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get settleChannelCard;

  /// No description provided for @settleChannelAgent.
  ///
  /// In en, this message translates to:
  /// **'Pay an agent'**
  String get settleChannelAgent;

  /// No description provided for @settleAgentCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your agent code'**
  String get settleAgentCodeTitle;

  /// No description provided for @settleAgentExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {time}'**
  String settleAgentExpires(String time);

  /// No description provided for @settleNearbyAgentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby agents'**
  String get settleNearbyAgentsTitle;

  /// No description provided for @settleNearbyAgentDistance.
  ///
  /// In en, this message translates to:
  /// **'{distance} m away'**
  String settleNearbyAgentDistance(int distance);

  /// No description provided for @settleDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get settleDone;

  /// No description provided for @earningsLedgerSection.
  ///
  /// In en, this message translates to:
  /// **'Balance activity'**
  String get earningsLedgerSection;

  /// No description provided for @earningsTripsSection.
  ///
  /// In en, this message translates to:
  /// **'TRIPS'**
  String get earningsTripsSection;

  /// No description provided for @earningsLedgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ledger entries yet'**
  String get earningsLedgerEmpty;

  /// No description provided for @earningsTripsCaption.
  ///
  /// In en, this message translates to:
  /// **'Cash you collected directly — not part of your Along balance'**
  String get earningsTripsCaption;

  /// No description provided for @earningsTripsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed cash trips today'**
  String get earningsTripsEmpty;

  /// No description provided for @earningsTripsTodaySummary.
  ///
  /// In en, this message translates to:
  /// **'{count} trips today · {amount} collected'**
  String earningsTripsTodaySummary(int count, String amount);

  /// No description provided for @standingLink.
  ///
  /// In en, this message translates to:
  /// **'Standing'**
  String get standingLink;

  /// No description provided for @standingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your standing'**
  String get standingTitle;

  /// No description provided for @standingBalanceAt.
  ///
  /// In en, this message translates to:
  /// **'Balance at transition: {amount}'**
  String standingBalanceAt(String amount);

  /// No description provided for @standingBlockThreshold.
  ///
  /// In en, this message translates to:
  /// **'Matching pauses if you owe more than {amount}'**
  String standingBlockThreshold(String amount);

  /// No description provided for @standingGraceDeadline.
  ///
  /// In en, this message translates to:
  /// **'Grace deadline: {date}'**
  String standingGraceDeadline(String date);

  /// No description provided for @standingRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Settle above the warn threshold to restore good standing'**
  String get standingRestoreHint;

  /// No description provided for @standingHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get standingHistoryTitle;

  /// No description provided for @standingHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No standing changes yet'**
  String get standingHistoryEmpty;

  /// No description provided for @guarantorLink.
  ///
  /// In en, this message translates to:
  /// **'Add a guarantor'**
  String get guarantorLink;

  /// No description provided for @guarantorTitle.
  ///
  /// In en, this message translates to:
  /// **'Guarantor'**
  String get guarantorTitle;

  /// No description provided for @guarantorExplainer.
  ///
  /// In en, this message translates to:
  /// **'Your guarantor is notified if your balance stays unsettled after the grace period. Nothing is ever deducted from them.'**
  String get guarantorExplainer;

  /// No description provided for @guarantorTypeDriver.
  ///
  /// In en, this message translates to:
  /// **'Fellow driver'**
  String get guarantorTypeDriver;

  /// No description provided for @guarantorTypeOwner.
  ///
  /// In en, this message translates to:
  /// **'Vehicle owner'**
  String get guarantorTypeOwner;

  /// No description provided for @guarantorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get guarantorNameLabel;

  /// No description provided for @guarantorPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get guarantorPhoneLabel;

  /// No description provided for @guarantorSubmit.
  ///
  /// In en, this message translates to:
  /// **'Add guarantor'**
  String get guarantorSubmit;

  /// No description provided for @guarantorSuccess.
  ///
  /// In en, this message translates to:
  /// **'Guarantor added — they will receive an acknowledgement link'**
  String get guarantorSuccess;

  /// No description provided for @extendTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Extend trip'**
  String get extendTripTitle;

  /// No description provided for @extendTripSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Where to now?'**
  String get extendTripSearchHint;

  /// No description provided for @extendTripDestination.
  ///
  /// In en, this message translates to:
  /// **'Continuing to {destination}'**
  String extendTripDestination(String destination);

  /// No description provided for @extendTripPropose.
  ///
  /// In en, this message translates to:
  /// **'Propose to rider'**
  String get extendTripPropose;

  /// No description provided for @incomingExtensionTitle.
  ///
  /// In en, this message translates to:
  /// **'Extension request'**
  String get incomingExtensionTitle;

  /// No description provided for @incomingExtensionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get incomingExtensionDecline;

  /// No description provided for @incomingExtensionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get incomingExtensionAccept;

  /// No description provided for @incomingRiderExtensionBody.
  ///
  /// In en, this message translates to:
  /// **'Rider proposes continuing to {destination} for +{delta}'**
  String incomingRiderExtensionBody(String destination, String delta);

  /// No description provided for @tripCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip complete'**
  String get tripCompleteTitle;

  /// No description provided for @tripCompleteFareLine.
  ///
  /// In en, this message translates to:
  /// **'Fare {amount} — rider pays you in cash'**
  String tripCompleteFareLine(String amount);

  /// No description provided for @tripCompleteAlongFeeLine.
  ///
  /// In en, this message translates to:
  /// **'Along fee {amount} — posted to your balance'**
  String tripCompleteAlongFeeLine(String amount);

  /// No description provided for @tripCompleteNewBalance.
  ///
  /// In en, this message translates to:
  /// **'New balance {amount}'**
  String tripCompleteNewBalance(String amount);

  /// No description provided for @tripCompleteCashQuestion.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash received?'**
  String get tripCompleteCashQuestion;

  /// No description provided for @tripCompleteYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get tripCompleteYes;

  /// No description provided for @tripCompleteDifferent.
  ///
  /// In en, this message translates to:
  /// **'Different amount'**
  String get tripCompleteDifferent;

  /// No description provided for @tripCompleteDifferentPrompt.
  ///
  /// In en, this message translates to:
  /// **'How much did you receive?'**
  String get tripCompleteDifferentPrompt;

  /// No description provided for @tripCompleteRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate your rider'**
  String get tripCompleteRateTitle;

  /// No description provided for @tripCompleteDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tripCompleteDone;

  /// No description provided for @requestPayment.
  ///
  /// In en, this message translates to:
  /// **'Request payment'**
  String get requestPayment;

  /// No description provided for @tripCompleteDigitalLine.
  ///
  /// In en, this message translates to:
  /// **'Paid digitally · {amount} sent to your bank'**
  String tripCompleteDigitalLine(String amount);

  /// No description provided for @tripCompleteDigitalFeeLine.
  ///
  /// In en, this message translates to:
  /// **'Along fee {amount} already deducted'**
  String tripCompleteDigitalFeeLine(String amount);

  /// No description provided for @myQrTitle.
  ///
  /// In en, this message translates to:
  /// **'My QR code'**
  String get myQrTitle;

  /// No description provided for @myQrAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your code for digital payments'**
  String get myQrAccountSubtitle;

  /// No description provided for @myQrDigitalDisabledBanner.
  ///
  /// In en, this message translates to:
  /// **'Digital payments are not live yet — your QR is for setup and testing only.'**
  String get myQrDigitalDisabledBanner;

  /// No description provided for @myQrPayoutPrompt.
  ///
  /// In en, this message translates to:
  /// **'Set up payout bank'**
  String get myQrPayoutPrompt;

  /// No description provided for @myQrPayoutHint.
  ///
  /// In en, this message translates to:
  /// **'Add your bank account so riders can pay you digitally. Along never holds your money.'**
  String get myQrPayoutHint;

  /// No description provided for @myQrSetupPayout.
  ///
  /// In en, this message translates to:
  /// **'Set up payout bank'**
  String get myQrSetupPayout;

  /// No description provided for @myQrPayoutComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Payout setup opens from Account once digital payments go live.'**
  String get myQrPayoutComingSoon;

  /// No description provided for @myQrShare.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get myQrShare;

  /// No description provided for @myQrOrderSticker.
  ///
  /// In en, this message translates to:
  /// **'Order printed sticker'**
  String get myQrOrderSticker;

  /// No description provided for @myQrStickerStatus.
  ///
  /// In en, this message translates to:
  /// **'Sticker request: {status}'**
  String myQrStickerStatus(String status);

  /// No description provided for @myQrVerifySticker.
  ///
  /// In en, this message translates to:
  /// **'Verify my sticker'**
  String get myQrVerifySticker;

  /// No description provided for @myQrVerifyMatch.
  ///
  /// In en, this message translates to:
  /// **'Sticker matches your code and plate'**
  String get myQrVerifyMatch;

  /// No description provided for @myQrVerifyMismatch.
  ///
  /// In en, this message translates to:
  /// **'This sticker does not match your account'**
  String get myQrVerifyMismatch;

  /// No description provided for @myQrVerifyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a valid Along QR code'**
  String get myQrVerifyInvalid;

  /// No description provided for @myQrVerifyTimeout.
  ///
  /// In en, this message translates to:
  /// **'Scan timed out — try again'**
  String get myQrVerifyTimeout;

  /// No description provided for @myQrPauseDigital.
  ///
  /// In en, this message translates to:
  /// **'Pause digital payments'**
  String get myQrPauseDigital;

  /// No description provided for @myQrPauseDigitalHint.
  ///
  /// In en, this message translates to:
  /// **'Riders will see cash only while paused'**
  String get myQrPauseDigitalHint;

  /// No description provided for @myQrPausedBanner.
  ///
  /// In en, this message translates to:
  /// **'Digital payments are paused — riders see cash only'**
  String get myQrPausedBanner;

  /// No description provided for @myQrRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate code'**
  String get myQrRotate;

  /// No description provided for @myQrRotateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Rotate QR code?'**
  String get myQrRotateConfirmTitle;

  /// No description provided for @myQrRotateConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your current stickers will stop working. Ops will need to print new ones.'**
  String get myQrRotateConfirmBody;

  /// No description provided for @myQrRotateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get myQrRotateCancel;

  /// No description provided for @myQrRotateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get myQrRotateConfirm;

  /// No description provided for @paymentRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment request'**
  String get paymentRequestTitle;

  /// No description provided for @paymentRequestForRider.
  ///
  /// In en, this message translates to:
  /// **'For {riderName}'**
  String paymentRequestForRider(String riderName);

  /// No description provided for @paymentRequestCountdown.
  ///
  /// In en, this message translates to:
  /// **'Expires in {seconds}s'**
  String paymentRequestCountdown(int seconds);

  /// No description provided for @paymentRequestWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment…'**
  String get paymentRequestWaiting;

  /// No description provided for @paymentRequestPaidLine.
  ///
  /// In en, this message translates to:
  /// **'Paid {amount} ✓'**
  String paymentRequestPaidLine(String amount);

  /// No description provided for @paymentRequestBankLine.
  ///
  /// In en, this message translates to:
  /// **'{amount} to your bank'**
  String paymentRequestBankLine(String amount);

  /// No description provided for @paymentRequestDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get paymentRequestDone;

  /// No description provided for @paymentRequestExpired.
  ///
  /// In en, this message translates to:
  /// **'This QR has expired — create a new one'**
  String get paymentRequestExpired;

  /// No description provided for @paymentRequestDigitalDisabled.
  ///
  /// In en, this message translates to:
  /// **'Digital payments are not enabled yet'**
  String get paymentRequestDigitalDisabled;

  /// No description provided for @paymentRequestTokenError.
  ///
  /// In en, this message translates to:
  /// **'Could not verify payment QR — try again'**
  String get paymentRequestTokenError;

  /// No description provided for @earningsDigitalSection.
  ///
  /// In en, this message translates to:
  /// **'Digital payments'**
  String get earningsDigitalSection;

  /// No description provided for @earningsDigitalCaption.
  ///
  /// In en, this message translates to:
  /// **'Paid straight to your bank — not part of your Along balance'**
  String get earningsDigitalCaption;

  /// No description provided for @earningsDigitalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No digital payments yet'**
  String get earningsDigitalEmpty;

  /// No description provided for @earningsDigitalRow.
  ///
  /// In en, this message translates to:
  /// **'Digital · {source}'**
  String earningsDigitalRow(String source);

  /// No description provided for @sosQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. Call 112 when you are back online.'**
  String get sosQueued;

  /// No description provided for @sosLiveLink.
  ///
  /// In en, this message translates to:
  /// **'Copy live location link'**
  String get sosLiveLink;

  /// No description provided for @sosLiveLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Live location link copied'**
  String get sosLiveLinkCopied;

  /// No description provided for @sosContactsHeading.
  ///
  /// In en, this message translates to:
  /// **'Tell someone you trust'**
  String get sosContactsHeading;

  /// No description provided for @sosContactWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp {name}'**
  String sosContactWhatsapp(String name);

  /// No description provided for @sosContactSms.
  ///
  /// In en, this message translates to:
  /// **'Text {name}'**
  String sosContactSms(String name);

  /// No description provided for @emergencyContactsHeading.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY CONTACTS'**
  String get emergencyContactsHeading;

  /// No description provided for @emergencyContactsHint.
  ///
  /// In en, this message translates to:
  /// **'We notify these people if you raise SOS. Up to 5. WhatsApp or a text opens on your phone.'**
  String get emergencyContactsHint;

  /// No description provided for @emergencyContactsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No emergency contacts yet'**
  String get emergencyContactsEmpty;

  /// No description provided for @emergencyContactName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get emergencyContactName;

  /// No description provided for @emergencyContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get emergencyContactPhone;

  /// No description provided for @emergencyContactAdd.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get emergencyContactAdd;

  /// No description provided for @emergencyContactRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String emergencyContactRemove(String name);

  /// No description provided for @emergencyContactInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Use a phone number like +2348012345678'**
  String get emergencyContactInvalidPhone;

  /// No description provided for @emergencyContactLimit.
  ///
  /// In en, this message translates to:
  /// **'You can save up to 5 contacts'**
  String get emergencyContactLimit;

  /// No description provided for @emergencyContactSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save that contact'**
  String get emergencyContactSaveFailed;

  /// No description provided for @buildMyDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Build my day'**
  String get buildMyDayTitle;

  /// No description provided for @buildMyDayStart.
  ///
  /// In en, this message translates to:
  /// **'Save and use this day'**
  String get buildMyDayStart;

  /// No description provided for @buildMyDayCorridor.
  ///
  /// In en, this message translates to:
  /// **'Corridor'**
  String get buildMyDayCorridor;

  /// No description provided for @saveLayout.
  ///
  /// In en, this message translates to:
  /// **'Save layout'**
  String get saveLayout;

  /// No description provided for @layoutName.
  ///
  /// In en, this message translates to:
  /// **'Layout name'**
  String get layoutName;

  /// No description provided for @addRow.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get addRow;

  /// No description provided for @addSeat.
  ///
  /// In en, this message translates to:
  /// **'Add seat'**
  String get addSeat;

  /// No description provided for @removeRow.
  ///
  /// In en, this message translates to:
  /// **'Remove row'**
  String get removeRow;

  /// No description provided for @overCapacityNote.
  ///
  /// In en, this message translates to:
  /// **'This is over the usual seat count. It is saved and flagged for review.'**
  String get overCapacityNote;

  /// No description provided for @seatMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat map'**
  String get seatMapTitle;

  /// No description provided for @seatFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get seatFull;

  /// No description provided for @seatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get seatEmpty;

  /// No description provided for @seatFree.
  ///
  /// In en, this message translates to:
  /// **'free'**
  String get seatFree;

  /// No description provided for @seatOccupied.
  ///
  /// In en, this message translates to:
  /// **'occupied'**
  String get seatOccupied;

  /// No description provided for @seatHeld.
  ///
  /// In en, this message translates to:
  /// **'held'**
  String get seatHeld;

  /// No description provided for @seatBlocked.
  ///
  /// In en, this message translates to:
  /// **'blocked'**
  String get seatBlocked;

  /// No description provided for @seatDriver.
  ///
  /// In en, this message translates to:
  /// **'driver'**
  String get seatDriver;

  /// No description provided for @rideRulesHeading.
  ///
  /// In en, this message translates to:
  /// **'Ride rules'**
  String get rideRulesHeading;

  /// No description provided for @customRuleHint.
  ///
  /// In en, this message translates to:
  /// **'Rule title'**
  String get customRuleHint;

  /// No description provided for @customRuleBody.
  ///
  /// In en, this message translates to:
  /// **'What riders should know'**
  String get customRuleBody;

  /// No description provided for @customRuleSave.
  ///
  /// In en, this message translates to:
  /// **'Add my rule'**
  String get customRuleSave;

  /// No description provided for @holdMinutes.
  ///
  /// In en, this message translates to:
  /// **'Hold minutes'**
  String get holdMinutes;

  /// No description provided for @capMax.
  ///
  /// In en, this message translates to:
  /// **'Seat cap'**
  String get capMax;

  /// No description provided for @deleteRule.
  ///
  /// In en, this message translates to:
  /// **'Remove rule'**
  String get deleteRule;

  /// No description provided for @dayNeedsCorridor.
  ///
  /// In en, this message translates to:
  /// **'Choose a corridor'**
  String get dayNeedsCorridor;

  /// No description provided for @seatStale.
  ///
  /// In en, this message translates to:
  /// **'Seat map is more than a minute old'**
  String get seatStale;

  /// No description provided for @shiftStart.
  ///
  /// In en, this message translates to:
  /// **'Shift starts'**
  String get shiftStart;

  /// No description provided for @shiftEnd.
  ///
  /// In en, this message translates to:
  /// **'Shift ends'**
  String get shiftEnd;

  /// No description provided for @homeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home-bound stop'**
  String get homeLabel;

  /// No description provided for @walkExtension.
  ///
  /// In en, this message translates to:
  /// **'Extra hold minutes for a walking rider'**
  String get walkExtension;

  /// No description provided for @seatLuggage.
  ///
  /// In en, this message translates to:
  /// **'luggage'**
  String get seatLuggage;

  /// No description provided for @voiceCommandHint.
  ///
  /// In en, this message translates to:
  /// **'Say accept, full, or seat back left free'**
  String get voiceCommandHint;

  /// No description provided for @conductorOpen.
  ///
  /// In en, this message translates to:
  /// **'Conductor code'**
  String get conductorOpen;

  /// No description provided for @conductorTitle.
  ///
  /// In en, this message translates to:
  /// **'Conductor'**
  String get conductorTitle;

  /// No description provided for @conductorCode.
  ///
  /// In en, this message translates to:
  /// **'Code from the driver'**
  String get conductorCode;

  /// No description provided for @conductorJoin.
  ///
  /// In en, this message translates to:
  /// **'Open the seat map'**
  String get conductorJoin;

  /// No description provided for @ghostSeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Still taken after the drop?'**
  String get ghostSeatTitle;

  /// No description provided for @ghostSeatFree.
  ///
  /// In en, this message translates to:
  /// **'Free it'**
  String get ghostSeatFree;

  /// No description provided for @freeSeatCount.
  ///
  /// In en, this message translates to:
  /// **'{count} free'**
  String freeSeatCount(int count);

  /// No description provided for @restTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restTitle;

  /// No description provided for @restDriveMinutes.
  ///
  /// In en, this message translates to:
  /// **'Drive minutes before a rest'**
  String get restDriveMinutes;

  /// No description provided for @restMinutes.
  ///
  /// In en, this message translates to:
  /// **'Rest minutes'**
  String get restMinutes;

  /// No description provided for @restSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get restSave;

  /// No description provided for @restStart.
  ///
  /// In en, this message translates to:
  /// **'Start rest'**
  String get restStart;

  /// No description provided for @restFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish rest'**
  String get restFinish;

  /// No description provided for @restPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority dispatch until your rest window ends'**
  String get restPriority;

  /// No description provided for @marketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get marketplaceTitle;

  /// No description provided for @marketplaceGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get marketplaceGoal;

  /// No description provided for @marketplaceEarned.
  ///
  /// In en, this message translates to:
  /// **'Already earned'**
  String get marketplaceEarned;

  /// No description provided for @marketplaceTypical.
  ///
  /// In en, this message translates to:
  /// **'Usual seat fare'**
  String get marketplaceTypical;

  /// No description provided for @marketplaceSeats.
  ///
  /// In en, this message translates to:
  /// **'{count} seats to go'**
  String marketplaceSeats(int count);

  /// No description provided for @marketplaceGoalMet.
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get marketplaceGoalMet;

  /// No description provided for @marketplaceSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get marketplaceSave;

  /// No description provided for @marketplaceCorridor.
  ///
  /// In en, this message translates to:
  /// **'Corridor you watch'**
  String get marketplaceCorridor;

  /// No description provided for @marketplaceRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get marketplaceRequests;

  /// No description provided for @marketplaceAddCorridor.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get marketplaceAddCorridor;

  /// No description provided for @marketplaceTip.
  ///
  /// In en, this message translates to:
  /// **'Queue toward {corridor}'**
  String marketplaceTip(String corridor);

  /// No description provided for @marketplaceFuel.
  ///
  /// In en, this message translates to:
  /// **'Price per litre'**
  String get marketplaceFuel;

  /// No description provided for @marketplaceFuelLabel.
  ///
  /// In en, this message translates to:
  /// **'Pump'**
  String get marketplaceFuelLabel;

  /// No description provided for @marketplaceFuelSave.
  ///
  /// In en, this message translates to:
  /// **'Save price'**
  String get marketplaceFuelSave;

  /// No description provided for @marketplaceEventName.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get marketplaceEventName;

  /// No description provided for @marketplaceEventHours.
  ///
  /// In en, this message translates to:
  /// **'Hours the point stays open'**
  String get marketplaceEventHours;

  /// No description provided for @marketplaceEventSave.
  ///
  /// In en, this message translates to:
  /// **'Open the point'**
  String get marketplaceEventSave;

  /// In-app trip chat button; {name} is the other party's name
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String activeTripMessageRider(String name);

  /// Trip chat button when the rider's name is unknown
  ///
  /// In en, this message translates to:
  /// **'Message rider'**
  String get activeTripMessageRiderUnknown;

  /// No description provided for @tripEtaCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get tripEtaCalculating;

  /// No description provided for @tripEtaPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup {label}'**
  String tripEtaPickup(String label);

  /// No description provided for @drivePhasePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get drivePhasePickup;

  /// No description provided for @drivePhaseBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get drivePhaseBoard;

  /// No description provided for @drivePhaseDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get drivePhaseDrop;

  /// No description provided for @activeTripPickUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up {name}'**
  String activeTripPickUpTitle(String name);

  /// No description provided for @activeTripOnBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is on board'**
  String activeTripOnBoardTitle(String name);

  /// No description provided for @activeTripDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop {name}'**
  String activeTripDropTitle(String name);

  /// No description provided for @activeTripRiderFallback.
  ///
  /// In en, this message translates to:
  /// **'your rider'**
  String get activeTripRiderFallback;

  /// No description provided for @activeTripBoardNaMe.
  ///
  /// In en, this message translates to:
  /// **'Board with Na Me'**
  String get activeTripBoardNaMe;

  /// No description provided for @activeTripEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter pickup PIN'**
  String get activeTripEnterPin;

  /// No description provided for @activeTripPinShort.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get activeTripPinShort;

  /// No description provided for @activeTripMessageShort.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get activeTripMessageShort;

  /// No description provided for @activeTripSeatsShort.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get activeTripSeatsShort;

  /// No description provided for @activeTripExtendShort.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get activeTripExtendShort;

  /// No description provided for @activeTripReportShort.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get activeTripReportShort;

  /// No description provided for @activeTripFareLabel.
  ///
  /// In en, this message translates to:
  /// **'Rider pays'**
  String get activeTripFareLabel;

  /// No description provided for @activeTripFeeCaption.
  ///
  /// In en, this message translates to:
  /// **'Along fee {amount} ({percent}%)'**
  String activeTripFeeCaption(String amount, String percent);

  /// No description provided for @incomingAcceptFare.
  ///
  /// In en, this message translates to:
  /// **'Accept · {amount}'**
  String incomingAcceptFare(String amount);

  /// No description provided for @incomingFareCaption.
  ///
  /// In en, this message translates to:
  /// **'Rider pays · {tierLabel}'**
  String incomingFareCaption(String tierLabel);

  /// No description provided for @homeOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get homeOfflineTitle;

  /// No description provided for @homeOnlineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re online'**
  String get homeOnlineTitle;

  /// No description provided for @homeOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Go online to get requests near you.'**
  String get homeOfflineHint;

  /// No description provided for @homeOnlineHint.
  ///
  /// In en, this message translates to:
  /// **'Requests pop up here. Accept in one tap.'**
  String get homeOnlineHint;

  /// No description provided for @homeGoOnline.
  ///
  /// In en, this message translates to:
  /// **'GO'**
  String get homeGoOnline;

  /// No description provided for @homeGoOffline.
  ///
  /// In en, this message translates to:
  /// **'Go offline'**
  String get homeGoOffline;

  /// No description provided for @homeModeAtPark.
  ///
  /// In en, this message translates to:
  /// **'At park'**
  String get homeModeAtPark;

  /// No description provided for @homeModeRoaming.
  ///
  /// In en, this message translates to:
  /// **'Roaming'**
  String get homeModeRoaming;

  /// No description provided for @homeModeFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get homeModeFull;

  /// No description provided for @homeTodayEarned.
  ///
  /// In en, this message translates to:
  /// **'Today · {amount}'**
  String homeTodayEarned(String amount);

  /// No description provided for @homeTodayTrips.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No trips yet} =1{1 trip} other{{count} trips}}'**
  String homeTodayTrips(int count);

  /// No description provided for @homeShortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your day'**
  String get homeShortcutsTitle;

  /// No description provided for @homeDirectionShortOnRoute.
  ///
  /// In en, this message translates to:
  /// **'On my route'**
  String get homeDirectionShortOnRoute;

  /// No description provided for @homeDirectionShortNone.
  ///
  /// In en, this message translates to:
  /// **'Any direction'**
  String get homeDirectionShortNone;

  /// No description provided for @homeTileDemand.
  ///
  /// In en, this message translates to:
  /// **'Demand'**
  String get homeTileDemand;

  /// No description provided for @tripCompleteCashHero.
  ///
  /// In en, this message translates to:
  /// **'Collect in cash'**
  String get tripCompleteCashHero;

  /// No description provided for @tripCompleteRowFare.
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get tripCompleteRowFare;

  /// No description provided for @tripCompleteRowFee.
  ///
  /// In en, this message translates to:
  /// **'Along fee (to balance)'**
  String get tripCompleteRowFee;

  /// No description provided for @tripCompleteRowBalance.
  ///
  /// In en, this message translates to:
  /// **'New balance'**
  String get tripCompleteRowBalance;

  /// No description provided for @tripCompleteYesAmount.
  ///
  /// In en, this message translates to:
  /// **'Yes, I got {amount}'**
  String tripCompleteYesAmount(String amount);

  /// No description provided for @settleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Along account'**
  String get settleSubtitle;

  /// No description provided for @settleOwedLabel.
  ///
  /// In en, this message translates to:
  /// **'You owe Along'**
  String get settleOwedLabel;

  /// No description provided for @settleCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get settleCreditLabel;

  /// No description provided for @settleThreshold.
  ///
  /// In en, this message translates to:
  /// **'Matching pauses if you owe more than {amount}'**
  String settleThreshold(String amount);

  /// No description provided for @settleMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get settleMethodTitle;

  /// No description provided for @settleSubmit.
  ///
  /// In en, this message translates to:
  /// **'Settle {amount}'**
  String settleSubmit(String amount);

  /// No description provided for @settleChannelBankDetail.
  ///
  /// In en, this message translates to:
  /// **'Transfer to your Along account'**
  String get settleChannelBankDetail;

  /// No description provided for @settleChannelUssdDetail.
  ///
  /// In en, this message translates to:
  /// **'Dial a code, no data needed'**
  String get settleChannelUssdDetail;

  /// No description provided for @settleChannelCardDetail.
  ///
  /// In en, this message translates to:
  /// **'Debit card'**
  String get settleChannelCardDetail;

  /// No description provided for @settleChannelAgentDetail.
  ///
  /// In en, this message translates to:
  /// **'Pay cash at an Along agent'**
  String get settleChannelAgentDetail;

  /// No description provided for @earningsBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String earningsBalanceAfter(String amount);

  /// No description provided for @ratingTagSafeDriving.
  ///
  /// In en, this message translates to:
  /// **'Safe driving'**
  String get ratingTagSafeDriving;

  /// No description provided for @ratingTagFairFare.
  ///
  /// In en, this message translates to:
  /// **'Fair fare'**
  String get ratingTagFairFare;

  /// No description provided for @ratingTagCleanVehicle.
  ///
  /// In en, this message translates to:
  /// **'Clean vehicle'**
  String get ratingTagCleanVehicle;

  /// No description provided for @ratingTagPolite.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get ratingTagPolite;

  /// No description provided for @ratingTagOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get ratingTagOnTime;

  /// No description provided for @ratingTagReady.
  ///
  /// In en, this message translates to:
  /// **'Ready at pickup'**
  String get ratingTagReady;

  /// No description provided for @ratingTagPaidPromptly.
  ///
  /// In en, this message translates to:
  /// **'Paid promptly'**
  String get ratingTagPaidPromptly;

  /// No description provided for @guarantorWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who vouches for you'**
  String get guarantorWhoTitle;

  /// No description provided for @guarantorDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Their details'**
  String get guarantorDetailsTitle;

  /// No description provided for @seatToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick tools'**
  String get seatToolsTitle;

  /// No description provided for @seatBoardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Plan your day to set up your vehicle\'s seats. Then you can mark who\'s on board here.'**
  String get seatBoardEmptyBody;

  /// No description provided for @mpGoalSection.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal'**
  String get mpGoalSection;

  /// No description provided for @mpDemandSection.
  ///
  /// In en, this message translates to:
  /// **'Where riders are'**
  String get mpDemandSection;

  /// No description provided for @mpFuelSection.
  ///
  /// In en, this message translates to:
  /// **'Fuel price'**
  String get mpFuelSection;

  /// No description provided for @mpEventSection.
  ///
  /// In en, this message translates to:
  /// **'Events nearby'**
  String get mpEventSection;

  /// No description provided for @seatBoardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} free · tap a seat to switch it'**
  String seatBoardSubtitle(int count);

  /// No description provided for @mpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a target, see where riders are, and share local tips.'**
  String get mpSubtitle;

  /// No description provided for @mpGoalEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set a target to see how many seats to go'**
  String get mpGoalEmpty;

  /// No description provided for @mpMoreSection.
  ///
  /// In en, this message translates to:
  /// **'Share with drivers'**
  String get mpMoreSection;

  /// No description provided for @mpFuelDetail.
  ///
  /// In en, this message translates to:
  /// **'Today\'s pump price nearby'**
  String get mpFuelDetail;

  /// No description provided for @mpEventDetail.
  ///
  /// In en, this message translates to:
  /// **'Open a pickup point for a crowd'**
  String get mpEventDetail;

  /// No description provided for @restSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a proper break after a long stretch. A full rest moves you up the queue.'**
  String get restSubtitle;

  /// No description provided for @restStatusDriving.
  ///
  /// In en, this message translates to:
  /// **'On the road'**
  String get restStatusDriving;

  /// No description provided for @restStatusResting.
  ///
  /// In en, this message translates to:
  /// **'Resting since {time}'**
  String restStatusResting(String time);

  /// No description provided for @restPlan.
  ///
  /// In en, this message translates to:
  /// **'{rest} min break every {drive} min'**
  String restPlan(int rest, int drive);

  /// No description provided for @restPlanEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set how long you drive before a break'**
  String get restPlanEmpty;

  /// No description provided for @restRhythmSection.
  ///
  /// In en, this message translates to:
  /// **'Your rhythm'**
  String get restRhythmSection;

  /// No description provided for @conductorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help the driver keep seats up to date.'**
  String get conductorSubtitle;

  /// No description provided for @conductorHowTo.
  ///
  /// In en, this message translates to:
  /// **'The driver opens Seat map → Conductor code and reads you the 8-character code.'**
  String get conductorHowTo;

  /// No description provided for @restDriveShort.
  ///
  /// In en, this message translates to:
  /// **'Drive (min)'**
  String get restDriveShort;

  /// No description provided for @restBreakShort.
  ///
  /// In en, this message translates to:
  /// **'Break (min)'**
  String get restBreakShort;

  /// No description provided for @mpTargetShort.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get mpTargetShort;

  /// No description provided for @mpEarnedShort.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get mpEarnedShort;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @conductorStep1.
  ///
  /// In en, this message translates to:
  /// **'Get the code'**
  String get conductorStep1;

  /// No description provided for @conductorStep1Body.
  ///
  /// In en, this message translates to:
  /// **'The driver shares it from their seat map'**
  String get conductorStep1Body;

  /// No description provided for @conductorStep2.
  ///
  /// In en, this message translates to:
  /// **'Join the bus'**
  String get conductorStep2;

  /// No description provided for @conductorStep2Body.
  ///
  /// In en, this message translates to:
  /// **'You see the same seats live'**
  String get conductorStep2Body;

  /// No description provided for @conductorStep3.
  ///
  /// In en, this message translates to:
  /// **'Update seats'**
  String get conductorStep3;

  /// No description provided for @conductorStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Tap a seat when riders board or leave'**
  String get conductorStep3Body;

  /// No description provided for @seatEmptyStep1.
  ///
  /// In en, this message translates to:
  /// **'Pick your vehicle'**
  String get seatEmptyStep1;

  /// No description provided for @seatEmptyStep1Body.
  ///
  /// In en, this message translates to:
  /// **'We draw its seats for you'**
  String get seatEmptyStep1Body;

  /// No description provided for @seatEmptyStep2.
  ///
  /// In en, this message translates to:
  /// **'Choose a corridor'**
  String get seatEmptyStep2;

  /// No description provided for @seatEmptyStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Riders on it can see your free seats'**
  String get seatEmptyStep2Body;

  /// No description provided for @seatEmptyStep3.
  ///
  /// In en, this message translates to:
  /// **'Fill seats as you go'**
  String get seatEmptyStep3;

  /// No description provided for @seatEmptyStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Tap a seat to mark it taken or free'**
  String get seatEmptyStep3Body;
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
      <String>['en', 'ha', 'ig', 'pcm', 'yo'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ha':
      return AppLocalizationsHa();
    case 'ig':
      return AppLocalizationsIg();
    case 'pcm':
      return AppLocalizationsPcm();
    case 'yo':
      return AppLocalizationsYo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
