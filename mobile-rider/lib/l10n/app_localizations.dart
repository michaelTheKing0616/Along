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
