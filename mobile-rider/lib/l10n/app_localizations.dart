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

  /// R-02 heading
  ///
  /// In en, this message translates to:
  /// **'Move around. Your way.'**
  String get phoneEntryTitle;

  /// R-02 body copy
  ///
  /// In en, this message translates to:
  /// **'Enter your number to continue'**
  String get phoneEntrySubtitle;

  /// Primary CTA on phone and name screens
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Legal line prefix on R-02
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get legalPrefix;

  /// Terms of service link label
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsLink;

  /// Legal line connector
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get legalMiddle;

  /// Privacy policy link label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyLink;

  /// R-03 heading with masked phone
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String otpTitle(String phone);

  /// R-03 link back to phone entry
  ///
  /// In en, this message translates to:
  /// **'Wrong number?'**
  String get wrongNumber;

  /// R-03 resend OTP action
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// R-03 resend cooldown
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendCountdown(int seconds);

  /// R-04 heading
  ///
  /// In en, this message translates to:
  /// **'What should drivers call you?'**
  String get nameTitle;

  /// R-04 text field hint
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameHint;

  /// R-04 skip optional name
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// R-02 validation error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Nigerian number'**
  String get errorInvalidPhone;

  /// R-02/R-03 rate limit error
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s'**
  String errorRateLimited(int seconds);

  /// R-03 invalid OTP
  ///
  /// In en, this message translates to:
  /// **'Incorrect code — try again'**
  String get errorWrongOtp;

  /// R-03 expired OTP
  ///
  /// In en, this message translates to:
  /// **'Code expired — request a new one'**
  String get errorExpiredOtp;

  /// Fallback error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Bottom nav Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav Trips tab
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get navTrips;

  /// Disclosure label for contextual sponsored placement slots (P8-B-01, FM39)
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get sponsoredLabel;

  /// Bottom nav Account tab
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// R-05 search field hint
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get homeSearchHint;

  /// R-05 location denied banner
  ///
  /// In en, this message translates to:
  /// **'Enable location to see nearby vehicles'**
  String get homeLocationDeniedBanner;

  /// R-06 manual pin path
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get homeChooseOnMap;

  /// R-05 half sheet nearby section title
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get homeNearbyTitle;

  /// R-05 nearby ambient row
  ///
  /// In en, this message translates to:
  /// **'{countBucket} {mode} nearby · heading {heading} · ~{minutes} min'**
  String homeNearbyRow(
    String countBucket,
    String mode,
    String heading,
    int minutes,
  );

  /// Expand home sheet to half
  ///
  /// In en, this message translates to:
  /// **'Show nearby'**
  String get homeExpandNearby;

  /// Collapse home sheet to peek
  ///
  /// In en, this message translates to:
  /// **'Hide nearby'**
  String get homeCollapseNearby;

  /// Ambient row mode label — car/along
  ///
  /// In en, this message translates to:
  /// **'cars'**
  String get modeCar;

  /// Ambient row mode label — keke
  ///
  /// In en, this message translates to:
  /// **'kekes'**
  String get modeKeke;

  /// Ambient row mode label — okada
  ///
  /// In en, this message translates to:
  /// **'okadas'**
  String get modeOkada;

  /// Ambient row mode label — minibus
  ///
  /// In en, this message translates to:
  /// **'minibuses'**
  String get modeMinibus;

  /// R-06 screen title
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get searchTitle;

  /// R-06 recents section
  ///
  /// In en, this message translates to:
  /// **'Recents'**
  String get searchRecentsTitle;

  /// R-06 autocomplete results
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get searchResultsTitle;

  /// R-06 offline state
  ///
  /// In en, this message translates to:
  /// **'Offline — search uses cached places'**
  String get searchOfflineHint;

  /// Offline/stale plan or search results badge (doc 07 §4)
  ///
  /// In en, this message translates to:
  /// **'Cached · may be outdated'**
  String get cachedOptionsStaleBadge;

  /// R-06 result subtitle
  ///
  /// In en, this message translates to:
  /// **'{area} · {distanceM} m away'**
  String searchResultSubtitle(String area, int distanceM);

  /// R-06b title
  ///
  /// In en, this message translates to:
  /// **'Adjust pickup'**
  String get adjustPickupTitle;

  /// R-06b snapped stage label
  ///
  /// In en, this message translates to:
  /// **'Boarding at: {stageName}'**
  String adjustPickupBoardingAt(String stageName);

  /// R-06b confirm CTA
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get adjustPickupConfirm;

  /// Trips tab stub until later phase
  ///
  /// In en, this message translates to:
  /// **'Your trips will appear here.'**
  String get tripsStubBody;

  /// Account tab stub until later phase
  ///
  /// In en, this message translates to:
  /// **'Account settings arrive in a later task.'**
  String get accountStubBody;

  /// R-07 stub title until P1-B-03
  ///
  /// In en, this message translates to:
  /// **'Trip options'**
  String get tripOptionsStubTitle;

  /// R-07 stub body until P1-B-03
  ///
  /// In en, this message translates to:
  /// **'Route and fare options arrive in the next task.'**
  String get tripOptionsStubBody;

  /// R-07 screen title
  ///
  /// In en, this message translates to:
  /// **'Trip options'**
  String get tripOptionsTitle;

  /// R-07 sheet heading
  ///
  /// In en, this message translates to:
  /// **'Choose how to go'**
  String get tripOptionsHeading;

  /// R-07 degraded planner banner
  ///
  /// In en, this message translates to:
  /// **'Live times unavailable'**
  String get tripOptionsDegradedBanner;

  /// R-07 non-viable direct caption
  ///
  /// In en, this message translates to:
  /// **'Slower than transfer options'**
  String get tripOptionsSlowerDirectCaption;

  /// R-07 Tier 3 CTA placeholder
  ///
  /// In en, this message translates to:
  /// **'Agree price'**
  String get tripOptionsAgreePrice;

  /// R-07 Tier 3 toast — negotiation is P2
  ///
  /// In en, this message translates to:
  /// **'Along Pricing arrives in a later phase'**
  String get tripOptionsAgreePricePlaceholder;

  /// R-16 screen title
  ///
  /// In en, this message translates to:
  /// **'Along Pricing'**
  String get pricingTitle;

  /// R-16 lapsed terminal state
  ///
  /// In en, this message translates to:
  /// **'No agreement — try another vehicle'**
  String get pricingLapsed;

  /// R-16 roaming out-of-range terminal state
  ///
  /// In en, this message translates to:
  /// **'Vehicle has passed'**
  String get pricingOutOfRange;

  /// R-16 declined/skipped terminal state
  ///
  /// In en, this message translates to:
  /// **'Offer declined'**
  String get pricingDeclined;

  /// R-16 inline driver response
  ///
  /// In en, this message translates to:
  /// **'Driver offered {amount}'**
  String pricingDriverOffer(String amount);

  /// Destination pick after hail-from-cell tap
  ///
  /// In en, this message translates to:
  /// **'Where are you going?'**
  String get hailSearchTitle;

  /// R-07 undo toast while commit window is open
  ///
  /// In en, this message translates to:
  /// **'Requesting…'**
  String get requestUndoMessage;

  /// R-09 sheet title
  ///
  /// In en, this message translates to:
  /// **'Carrying load?'**
  String get loadFlagTitle;

  /// R-09 load size chip
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get loadFlagSizeSmall;

  /// R-09 load size chip
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get loadFlagSizeMedium;

  /// R-09 load size chip
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get loadFlagSizeLarge;

  /// R-09 optional note field
  ///
  /// In en, this message translates to:
  /// **'Optional note (140 characters)'**
  String get loadFlagNoteHint;

  /// R-09 remember-for-day toggle
  ///
  /// In en, this message translates to:
  /// **'Remember for today'**
  String get loadFlagRememberDay;

  /// R-09 / FM36 inline capacity warning
  ///
  /// In en, this message translates to:
  /// **'This mode may not fit your load'**
  String get loadFlagCapacityWarning;

  /// R-09 FM36 acknowledge and proceed
  ///
  /// In en, this message translates to:
  /// **'Request anyway'**
  String get loadFlagRequestAnyway;

  /// R-09 apply load flag
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get loadFlagDone;

  /// R-10 sheet title
  ///
  /// In en, this message translates to:
  /// **'Requesting a {mode}…'**
  String requestingTitle(String mode);

  /// R-10 countdown from server expires_at
  ///
  /// In en, this message translates to:
  /// **'{seconds}s remaining'**
  String requestingCountdown(int seconds);

  /// R-10 roaming cascade — never names who declined
  ///
  /// In en, this message translates to:
  /// **'Finding another vehicle…'**
  String get requestingFindingAnother;

  /// R-10 cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get requestingCancel;

  /// R-10 expired state
  ///
  /// In en, this message translates to:
  /// **'No driver responded — see other options'**
  String get requestingExpired;

  /// R-10 accepted placeholder until R-11
  ///
  /// In en, this message translates to:
  /// **'Driver accepted — meet your vehicle arrives next'**
  String get requestingAcceptedPlaceholder;

  /// R-18 heading
  ///
  /// In en, this message translates to:
  /// **'No mapped routes here yet'**
  String get coverageGapTitle;

  /// R-18 nearest stage line
  ///
  /// In en, this message translates to:
  /// **'Nearest known boarding point: {name} · {distance}'**
  String coverageGapNearestBoarding(String name, String distance);

  /// R-18 distance in kilometres
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String coverageGapDistanceKm(String km);

  /// R-18 distance in metres
  ///
  /// In en, this message translates to:
  /// **'{m} m'**
  String coverageGapDistanceM(int m);

  /// R-18 honest ambient line — zero
  ///
  /// In en, this message translates to:
  /// **'Vehicles nearby: none'**
  String get coverageGapVehiclesNone;

  /// R-18 honest ambient line — non-zero
  ///
  /// In en, this message translates to:
  /// **'Vehicles nearby: {count}'**
  String coverageGapVehiclesNearby(int count);

  /// R-18 walk to nearest boarding
  ///
  /// In en, this message translates to:
  /// **'Walk there'**
  String get coverageGapWalkThere;

  /// R-18 coverage report action
  ///
  /// In en, this message translates to:
  /// **'Tell us about this area'**
  String get coverageGapTellUs;

  /// R-18 report acknowledgement
  ///
  /// In en, this message translates to:
  /// **'Thanks — we logged your report'**
  String get coverageGapThanks;

  /// R-07 recommended explain popover trigger
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get tripOptionsWhy;

  /// R-07 explain popover title
  ///
  /// In en, this message translates to:
  /// **'Why recommended'**
  String get tripOptionsWhyTitle;

  /// R-07 explain bar label — fare
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get tripOptionsWhyFare;

  /// R-07 explain bar label — time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get tripOptionsWhyTime;

  /// R-07 explain bar label — effort
  ///
  /// In en, this message translates to:
  /// **'Effort'**
  String get tripOptionsWhyEffort;

  /// R-07 multi-leg expand
  ///
  /// In en, this message translates to:
  /// **'Show legs'**
  String get tripOptionsShowLegs;

  /// R-07 multi-leg collapse
  ///
  /// In en, this message translates to:
  /// **'Hide legs'**
  String get tripOptionsHideLegs;

  /// R-07 per-leg request CTA
  ///
  /// In en, this message translates to:
  /// **'Request leg {leg} · {fare}'**
  String tripOptionsRequestLeg(int leg, String fare);

  /// R-14 screen title
  ///
  /// In en, this message translates to:
  /// **'Next leg'**
  String get transferTitle;

  /// R-14 next leg card heading
  ///
  /// In en, this message translates to:
  /// **'Next leg'**
  String get transferNextLegTitle;

  /// R-14 live supply line
  ///
  /// In en, this message translates to:
  /// **'{bucket} loading'**
  String transferSupply(String bucket);

  /// R-14 one-tap next leg request
  ///
  /// In en, this message translates to:
  /// **'Request next leg'**
  String get transferRequestNextLeg;

  /// R-14 tertiary replan CTA
  ///
  /// In en, this message translates to:
  /// **'Change plan'**
  String get transferChangePlan;

  /// R-14 waiting for prefetched walk
  ///
  /// In en, this message translates to:
  /// **'Loading walking directions…'**
  String get transferWalkLoading;

  /// R-19 screen title
  ///
  /// In en, this message translates to:
  /// **'Walking directions'**
  String get wayfindingTitle;

  /// R-19 mode segment
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get wayfindingModeText;

  /// R-19 mode segment
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get wayfindingModeMap;

  /// R-19 mode segment
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get wayfindingModeAudio;

  /// R-19 audio play
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get wayfindingPlay;

  /// R-19 audio pause
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get wayfindingPause;

  /// R-19 auto-arrival label
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get wayfindingArrived;

  /// R-19 OSRM degraded banner
  ///
  /// In en, this message translates to:
  /// **'Directions may be approximate'**
  String get wayfindingDegraded;

  /// R-19 map mode placeholder
  ///
  /// In en, this message translates to:
  /// **'Route with {count} points'**
  String wayfindingMapHint(int count);

  /// R-19 empty steps fallback
  ///
  /// In en, this message translates to:
  /// **'No steps available'**
  String get wayfindingNoSteps;

  /// R-11 driver ETA line
  ///
  /// In en, this message translates to:
  /// **'Arriving in ~{minutes} min'**
  String meetVehicleArrivingIn(int minutes);

  /// R-11 walk-to-boarding line
  ///
  /// In en, this message translates to:
  /// **'Walk {minutes} min to {park}'**
  String meetVehicleWalkTo(int minutes, String park);

  /// R-11 Na Me chip caption
  ///
  /// In en, this message translates to:
  /// **'Show this to your driver — {label}'**
  String meetVehicleNaMeHint(String label);

  /// R-11 driver offline > threshold
  ///
  /// In en, this message translates to:
  /// **'Driver signal lost'**
  String get meetVehicleDriverSignalLost;

  /// R-11 realtime heartbeat stale
  ///
  /// In en, this message translates to:
  /// **'Live updates paused'**
  String get meetVehicleLivePaused;

  /// R-11 share placeholder
  ///
  /// In en, this message translates to:
  /// **'Share trip'**
  String get meetVehicleShare;

  /// R-11 cancel when driver offline
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get meetVehicleCancel;

  /// R-11 manual boarding override
  ///
  /// In en, this message translates to:
  /// **'I\'ve boarded'**
  String get meetVehicleBoarded;

  /// R-13 sheet peek line
  ///
  /// In en, this message translates to:
  /// **'In transit · ETA {minutes} min · {fare} Standard fare'**
  String activeTripStatus(int minutes, String fare);

  /// R-13 extend placeholder
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get activeTripExtend;

  /// R-13 share placeholder
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get activeTripShare;

  /// R-13 report placeholder
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get activeTripReport;

  /// R-25 placeholder snackbar
  ///
  /// In en, this message translates to:
  /// **'Share trip — coming in Phase 5'**
  String get sharePlaceholder;

  /// R-23 placeholder snackbar
  ///
  /// In en, this message translates to:
  /// **'SOS — coming in Phase 5'**
  String get sosPlaceholder;

  /// R-15 placeholder snackbar
  ///
  /// In en, this message translates to:
  /// **'Extend trip — coming in Phase 5'**
  String get extendPlaceholder;

  /// R-24 placeholder snackbar
  ///
  /// In en, this message translates to:
  /// **'Report incident — coming in Phase 5'**
  String get reportPlaceholder;

  /// R-17 sheet title
  ///
  /// In en, this message translates to:
  /// **'Trip complete'**
  String get tripCompleteTitle;

  /// R-17 Tier 1/2 fare confirm
  ///
  /// In en, this message translates to:
  /// **'Did you pay {amount}?'**
  String tripCompletePaidQuestion(String amount);

  /// R-17 Tier 3 fare confirm (FM33)
  ///
  /// In en, this message translates to:
  /// **'What did you pay?'**
  String get tripCompleteTier3Question;

  /// R-17 one-tap as_shown confirm
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get tripCompleteYes;

  /// R-17 alternate fare path
  ///
  /// In en, this message translates to:
  /// **'Different amount'**
  String get tripCompleteDifferent;

  /// R-17 different-amount chips heading
  ///
  /// In en, this message translates to:
  /// **'Pick the amount you paid'**
  String get tripCompleteDifferentPrompt;

  /// R-17 rating step heading
  ///
  /// In en, this message translates to:
  /// **'Rate your trip'**
  String get tripCompleteRateTitle;

  /// R-15 sheet title
  ///
  /// In en, this message translates to:
  /// **'Extend trip'**
  String get extendTripTitle;

  /// R-15 destination search
  ///
  /// In en, this message translates to:
  /// **'Where to now?'**
  String get extendTripSearchHint;

  /// R-15 selected destination label
  ///
  /// In en, this message translates to:
  /// **'Continuing to {destination}'**
  String extendTripDestination(String destination);

  /// R-15 propose extension CTA
  ///
  /// In en, this message translates to:
  /// **'Send to driver'**
  String get extendTripSend;

  /// R-15 driver proposal sheet title
  ///
  /// In en, this message translates to:
  /// **'Extension request'**
  String get incomingExtensionTitle;

  /// R-15 driver proposal copy
  ///
  /// In en, this message translates to:
  /// **'Driver proposes continuing to {destination} for +{delta}'**
  String incomingExtensionBody(String destination, String delta);

  /// R-15 one-tap accept
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get incomingExtensionAccept;

  /// R-15 decline extension
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get incomingExtensionDecline;

  /// R-27 sheet title
  ///
  /// In en, this message translates to:
  /// **'Pay driver'**
  String get payDriverTitle;

  /// R-27 primary pay button
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payDriverCta(String amount);

  /// R-27 locked amount hint (TS-UI-04)
  ///
  /// In en, this message translates to:
  /// **'Amount locked to this trip'**
  String get payDriverAmountLocked;

  /// R-27 default payment method row
  ///
  /// In en, this message translates to:
  /// **'Visa ···4242'**
  String get payDriverMethodSaved;

  /// R-27 pending transfer/USSD state
  ///
  /// In en, this message translates to:
  /// **'Complete payment in your bank app'**
  String get payDriverPending;

  /// R-27 default method when transfer preferred
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get payDriverMethodTransfer;

  /// R-27 USSD payment method row
  ///
  /// In en, this message translates to:
  /// **'USSD'**
  String get payDriverMethodUssd;

  /// R-27 link to R-32
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get payDriverChangeMethod;

  /// R-27 cash-only driver state
  ///
  /// In en, this message translates to:
  /// **'{name} accepts cash only'**
  String payDriverCashOnly(String name);

  /// R-27 inactive driver code
  ///
  /// In en, this message translates to:
  /// **'This code is no longer active'**
  String get payDriverInactive;

  /// R-27 sticker-swap warning banner
  ///
  /// In en, this message translates to:
  /// **'Your active trip is with another driver'**
  String get payDriverDifferentDriver;

  /// R-27 explicit confirm for different_driver
  ///
  /// In en, this message translates to:
  /// **'This isn\'t my trip\'s driver — pay anyway'**
  String get payDriverConfirmOther;

  /// R-27 failed state
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get payDriverFailed;

  /// R-27 retry after failure
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get payDriverRetry;

  /// R-27 success heading
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get payDriverSuccessTitle;

  /// R-27 itemised success (FM3)
  ///
  /// In en, this message translates to:
  /// **'{driverAmount} to {name} · {feeAmount} Along fee'**
  String payDriverSuccessItemised(
    String driverAmount,
    String name,
    String feeAmount,
  );

  /// R-27 unattributed success opt-in
  ///
  /// In en, this message translates to:
  /// **'Add this trip to your history?'**
  String get payDriverHistoryOptIn;

  /// R-31 screen title
  ///
  /// In en, this message translates to:
  /// **'Scan to pay'**
  String get scanToPayTitle;

  /// R-31 typed code fallback
  ///
  /// In en, this message translates to:
  /// **'Enter code instead'**
  String get scanEnterCode;

  /// R-31 typed entry heading
  ///
  /// In en, this message translates to:
  /// **'Enter driver code'**
  String get scanEnterCodePrompt;

  /// R-31 code field hint
  ///
  /// In en, this message translates to:
  /// **'8-character code'**
  String get scanCodeHint;

  /// R-31 typed code submit
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get scanCodeSubmit;

  /// R-31 return to scanner
  ///
  /// In en, this message translates to:
  /// **'Back to camera'**
  String get scanBackToCamera;

  /// R-31 reject non-Along payloads
  ///
  /// In en, this message translates to:
  /// **'Not an Along code'**
  String get scanNotAlong;

  /// R-32 screen title
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get payMethodsTitle;

  /// R-32 default badge
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get payMethodsDefault;

  /// R-32 set default action
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get payMethodsSetDefault;

  /// R-32 remove method
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get payMethodsRemove;

  /// R-32 add method CTA
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get payMethodsAdd;

  /// R-32 transfer preference
  ///
  /// In en, this message translates to:
  /// **'Pay with transfer by default'**
  String get payMethodsTransferDefault;

  /// R-13 scan to pay entry
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get activeTripScan;

  /// R-22 empty history
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet.'**
  String get tripsEmpty;

  /// R-22 detail screen title
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetailTitle;

  /// R-22 missing trip detail
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get tripDetailMissing;

  /// R-22 text receipt share
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get tripDetailShareReceipt;

  /// R-22 receipt share acknowledgement
  ///
  /// In en, this message translates to:
  /// **'Receipt copied to clipboard'**
  String get tripDetailReceiptCopied;

  /// R-23 SOS headline
  ///
  /// In en, this message translates to:
  /// **'Along safety team alerted'**
  String get sosTeamAlerted;

  /// R-23 SOS subcopy
  ///
  /// In en, this message translates to:
  /// **'We\'re sharing your live location and trip details with our safety line'**
  String get sosSharingDetails;

  /// R-23 emergency tel button
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String sosCallEmergency(String number);

  /// R-23 link to R-25
  ///
  /// In en, this message translates to:
  /// **'Share with a contact'**
  String get sosShareWithContact;

  /// R-23 hold-to-cancel label
  ///
  /// In en, this message translates to:
  /// **'Hold to cancel'**
  String get sosHoldToCancel;

  /// R-23 SOS in progress
  ///
  /// In en, this message translates to:
  /// **'Alerting safety team…'**
  String get sosRaising;

  /// R-23 SOS failure
  ///
  /// In en, this message translates to:
  /// **'Could not reach safety line'**
  String get sosRaiseFailed;

  /// R-23 SOS retry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get sosRetry;

  /// R-24 screen title
  ///
  /// In en, this message translates to:
  /// **'Report incident'**
  String get reportIncidentTitle;

  /// R-24 category grid heading
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get reportIncidentCategoryHeading;

  /// R-24 description heading
  ///
  /// In en, this message translates to:
  /// **'Tell us more'**
  String get reportIncidentDescriptionHeading;

  /// R-24 description placeholder
  ///
  /// In en, this message translates to:
  /// **'Describe what happened (optional details help)'**
  String get reportIncidentDescriptionHint;

  /// R-24 optional photo stub
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get reportIncidentAttachPhoto;

  /// R-24 photo stub attached
  ///
  /// In en, this message translates to:
  /// **'Photo attached (stub)'**
  String get reportIncidentPhotoAttached;

  /// R-24 submit CTA
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportIncidentSubmit;

  /// R-24 validation
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get reportIncidentPickCategory;

  /// R-24 validation
  ///
  /// In en, this message translates to:
  /// **'Add a short description'**
  String get reportIncidentDescriptionRequired;

  /// R-24 success
  ///
  /// In en, this message translates to:
  /// **'Report submitted — our safety team will review it'**
  String get reportIncidentSubmitted;

  /// No description provided for @incidentCategorySafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
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
  /// **'Driver behaviour'**
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

  /// R-25 sheet title
  ///
  /// In en, this message translates to:
  /// **'Share live trip'**
  String get shareTripTitle;

  /// R-25 create link CTA
  ///
  /// In en, this message translates to:
  /// **'Create share link'**
  String get shareTripCreateLink;

  /// R-25 copy
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareTripCopy;

  /// R-25 SMS share
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get shareTripSms;

  /// R-25 copy acknowledgement
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get shareTripCopied;

  /// R-25 expiry note
  ///
  /// In en, this message translates to:
  /// **'Links auto-expire when your trip ends'**
  String get shareTripExpiryNote;

  /// R-25 active list heading
  ///
  /// In en, this message translates to:
  /// **'Active shares'**
  String get shareTripActiveHeading;

  /// R-25 share without contact name
  ///
  /// In en, this message translates to:
  /// **'Shared contact'**
  String get shareTripAnonymousContact;

  /// R-25 share expiry label
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String shareTripExpires(String date);

  /// R-25 SMS body
  ///
  /// In en, this message translates to:
  /// **'Track my Along trip: {url}'**
  String shareTripSmsBody(String url);

  /// No description provided for @accountProfileHeading.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get accountProfileHeading;

  /// No description provided for @accountPreferencesHeading.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get accountPreferencesHeading;

  /// R-26 city switcher label
  ///
  /// In en, this message translates to:
  /// **'Home city'**
  String get accountCityLabel;

  /// R-26 city switcher hint
  ///
  /// In en, this message translates to:
  /// **'Map and search default to this city when location is unavailable'**
  String get accountCityHint;

  /// No description provided for @accountPaymentHeading.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT'**
  String get accountPaymentHeading;

  /// No description provided for @accountSafetyHeading.
  ///
  /// In en, this message translates to:
  /// **'SAFETY'**
  String get accountSafetyHeading;

  /// No description provided for @accountWayfindingLabel.
  ///
  /// In en, this message translates to:
  /// **'Wayfinding mode'**
  String get accountWayfindingLabel;

  /// No description provided for @accountSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Default trip sort'**
  String get accountSortLabel;

  /// No description provided for @accountWomenOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Women-only matching'**
  String get accountWomenOnlyLabel;

  /// No description provided for @accountWomenOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Prefer trips with women-only drivers when available'**
  String get accountWomenOnlyHint;

  /// No description provided for @accountPaymentCashDefault.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountPaymentCashDefault;

  /// No description provided for @accountPaymentCashHint.
  ///
  /// In en, this message translates to:
  /// **'Default payment method for Along trips'**
  String get accountPaymentCashHint;

  /// No description provided for @accountSafetyHowSos.
  ///
  /// In en, this message translates to:
  /// **'How SOS works'**
  String get accountSafetyHowSos;

  /// No description provided for @accountSafetyHowSosBody.
  ///
  /// In en, this message translates to:
  /// **'Hold SOS during a trip to alert our safety team and share live location'**
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

  /// No description provided for @homePlanYourDay.
  ///
  /// In en, this message translates to:
  /// **'Plan your day'**
  String get homePlanYourDay;

  /// No description provided for @dayPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s plan'**
  String get dayPlannerTitle;

  /// No description provided for @dayPlannerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stops in your plan yet'**
  String get dayPlannerEmpty;

  /// No description provided for @dayPlannerNotBookedHint.
  ///
  /// In en, this message translates to:
  /// **'Stops are planned — matching starts when you tap Match now. Nothing is reserved ahead of time.'**
  String get dayPlannerNotBookedHint;

  /// No description provided for @dayPlannerLoadToggle.
  ///
  /// In en, this message translates to:
  /// **'Load today'**
  String get dayPlannerLoadToggle;

  /// No description provided for @dayPlannerMatchNow.
  ///
  /// In en, this message translates to:
  /// **'Match now'**
  String get dayPlannerMatchNow;

  /// No description provided for @dayPlannerPrepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get dayPlannerPrepare;

  /// No description provided for @dayPlannerAddStop.
  ///
  /// In en, this message translates to:
  /// **'Add stop'**
  String get dayPlannerAddStop;

  /// No description provided for @dayPlannerStopDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dayPlannerStopDone;

  /// No description provided for @dayPlannerStopInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress · ETA {minutes} min'**
  String dayPlannerStopInProgress(int minutes);

  /// No description provided for @dayPlannerStopReady.
  ///
  /// In en, this message translates to:
  /// **'Ready — tap Match now below'**
  String get dayPlannerStopReady;

  /// No description provided for @dayPlannerStopPrepareHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Prepare when you are ready'**
  String get dayPlannerStopPrepareHint;

  /// No description provided for @dayPlannerStopPending.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get dayPlannerStopPending;

  /// No description provided for @dayPlannerStopSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get dayPlannerStopSkipped;

  /// No description provided for @itineraryEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your day'**
  String get itineraryEntryTitle;

  /// No description provided for @itineraryEntryStructured.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get itineraryEntryStructured;

  /// No description provided for @itineraryEntryNaturalLanguage.
  ///
  /// In en, this message translates to:
  /// **'Describe'**
  String get itineraryEntryNaturalLanguage;

  /// No description provided for @itineraryEntryStopHint.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get itineraryEntryStopHint;

  /// No description provided for @itineraryEntryAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add another stop'**
  String get itineraryEntryAddRow;

  /// No description provided for @itineraryEntryDescribeDay.
  ///
  /// In en, this message translates to:
  /// **'Describe your day'**
  String get itineraryEntryDescribeDay;

  /// No description provided for @itineraryEntryNlHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. drop kids at school, then work, then market'**
  String get itineraryEntryNlHint;

  /// No description provided for @itineraryEntryMicTitle.
  ///
  /// In en, this message translates to:
  /// **'Say your stops'**
  String get itineraryEntryMicTitle;

  /// No description provided for @itineraryEntryMicHint.
  ///
  /// In en, this message translates to:
  /// **'Speak or type your stops…'**
  String get itineraryEntryMicHint;

  /// No description provided for @itineraryEntryParse.
  ///
  /// In en, this message translates to:
  /// **'Preview stops'**
  String get itineraryEntryParse;

  /// No description provided for @itineraryEntryProposalTitle.
  ///
  /// In en, this message translates to:
  /// **'We heard'**
  String get itineraryEntryProposalTitle;

  /// No description provided for @itineraryEntryUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Needs a place name'**
  String get itineraryEntryUnresolved;

  /// No description provided for @itineraryEntryLooksRight.
  ///
  /// In en, this message translates to:
  /// **'Looks right'**
  String get itineraryEntryLooksRight;

  /// No description provided for @itineraryEntrySavePlan.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get itineraryEntrySavePlan;
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
