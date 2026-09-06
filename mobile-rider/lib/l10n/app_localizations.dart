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
  /// **'Offline — showing recents only'**
  String get searchOfflineHint;

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
