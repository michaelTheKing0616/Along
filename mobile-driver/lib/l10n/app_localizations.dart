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

  /// No description provided for @routesStubTitle.
  ///
  /// In en, this message translates to:
  /// **'Your routes'**
  String get routesStubTitle;

  /// No description provided for @routesStubBody.
  ///
  /// In en, this message translates to:
  /// **'Route setup coming in the next step.'**
  String get routesStubBody;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;
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
