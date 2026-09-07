import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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
  /// **'Enter your number to get started'**
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
  /// **'Along fee {amount} ({percent}%) — added to your balance at completion'**
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

  /// No description provided for @sosPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'SOS will connect in a future release'**
  String get sosPlaceholder;

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
  /// **'ALONG BALANCE'**
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
  /// **'Matching pauses below {amount}'**
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
  /// **'DIGITAL PAYMENTS RECEIVED'**
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
