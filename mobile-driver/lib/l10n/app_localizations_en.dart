// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get driverBrandingLine => 'Drive with Along';

  @override
  String get phoneEntryTitle => 'Drive with Along';

  @override
  String get phoneEntrySubtitle => 'Enter your number to get started';

  @override
  String get continueButton => 'Continue';

  @override
  String get legalPrefix => 'By continuing, you agree to our ';

  @override
  String get termsLink => 'Terms';

  @override
  String get legalMiddle => ' and ';

  @override
  String get privacyLink => 'Privacy Policy';

  @override
  String otpTitle(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get wrongNumber => 'Wrong number?';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCountdown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get errorInvalidPhone => 'Enter a valid Nigerian number';

  @override
  String get errorWrongOtp => 'Incorrect code — try again';

  @override
  String get errorExpiredOtp => 'Code expired — request a new one';

  @override
  String errorRateLimited(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s';
  }

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorValidation => 'Please check the fields and try again.';

  @override
  String get errorPlateConflict => 'This plate is already registered.';

  @override
  String get profileTitle => 'Your profile';

  @override
  String get profileSubtitle => 'Tell us a bit about yourself';

  @override
  String get nameLabel => 'Full name';

  @override
  String get nameHint => 'Your name';

  @override
  String get cityLabel => 'City';

  @override
  String get genderLabel => 'Gender (optional)';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMale => 'Male';

  @override
  String get genderOther => 'Prefer not to say';

  @override
  String get photoOptional => 'Add photo (optional)';

  @override
  String get vehicleTitle => 'Your vehicle';

  @override
  String get vehicleSubtitle => 'How will you drive on Along?';

  @override
  String get plateLabel => 'Plate number';

  @override
  String get plateHint => 'e.g. ABC-123-XY';

  @override
  String get seatsLabel => 'Seats';

  @override
  String get colorLabel => 'Colour';

  @override
  String get makeModelLabel => 'Make & model';

  @override
  String get ownerQuestion => 'Is this your vehicle?';

  @override
  String get ownerYes => 'Yes, it\'s mine';

  @override
  String get ownerNo => 'No, someone else owns it';

  @override
  String get ownerNameLabel => 'Owner name';

  @override
  String get ownerPhoneLabel => 'Owner phone';

  @override
  String get documentsTitle => 'Verify your documents';

  @override
  String get documentsSubtitle => 'Upload each document to start driving';

  @override
  String get docStatusNotStarted => 'Not started';

  @override
  String get docStatusPending => 'Pending';

  @override
  String get docStatusApproved => 'Approved';

  @override
  String get docStatusRejected => 'Rejected';

  @override
  String get saveAndContinueLater => 'Save and continue later';

  @override
  String captureTitle(String document) {
    return 'Capture $document';
  }

  @override
  String get captureGuide => 'Fit the document inside the frame';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get retakePhoto => 'Retake';

  @override
  String get submitDocument => 'Submit document';

  @override
  String get ocrReviewTitle => 'Review extracted details';

  @override
  String get ocrReviewSubtitle => 'Confirm each field before submitting';

  @override
  String ocrSuggestedValue(String value) {
    return 'Suggested: $value';
  }

  @override
  String get ocrConfirmField => 'Use this value';

  @override
  String get ocrFieldConfirmed => 'Confirmed';

  @override
  String get ocrNoAutoFillNote =>
      'ID numbers are never filled automatically — tap confirm for each field.';

  @override
  String get pendingTitle => 'Verification in progress';

  @override
  String get pendingHero => 'We\'re reviewing your documents';

  @override
  String get pendingExpectedGeneric => 'This usually takes 1–3 business days';

  @override
  String pendingExpectedHours(int hours) {
    return 'Expected within $hours hours';
  }

  @override
  String get pendingWhatNext =>
      'We\'ll notify you when you\'re approved. You can set up your route while you wait.';

  @override
  String get setupRouteCta => 'Set up your route while you wait';

  @override
  String get routesListTitle => 'Your routes';

  @override
  String get routesAddRoute => 'Add route';

  @override
  String get routesEmptyTitle => 'Set up your route in a few taps';

  @override
  String get routesEmptyBody =>
      'Publish your stops and prices so riders can find you on your usual path.';

  @override
  String get routeSuggestedCardTitle => 'Suggested route';

  @override
  String routeSuggestedCardBody(String mode, int stopCount) {
    return 'We detected a usual $mode path with $stopCount stops.';
  }

  @override
  String get routeSuggestedCardCta => 'Tap to review and publish';

  @override
  String routeUnnamedProfile(String mode) {
    return '$mode route';
  }

  @override
  String routeStopsCount(int count) {
    return '$count stops';
  }

  @override
  String routeLoadSurchargeLabel(String amount) {
    return 'Load surcharge: $amount';
  }

  @override
  String get routeLoadSurchargeOptional => 'Load surcharge (optional)';

  @override
  String get routeLoadSurchargeHint => 'e.g. 50';

  @override
  String get routeFastSetupTitle => 'Route setup';

  @override
  String get routeFastSetupQuestion => 'Is this your route?';

  @override
  String routeFastSetupSubtitle(int count) {
    return '$count stops detected from your usual path';
  }

  @override
  String get routeYesPublish => 'Yes, publish';

  @override
  String get routeEditPrices => 'Edit prices';

  @override
  String get routeDrawManually => 'No, draw manually';

  @override
  String get routeDrawTitle => 'Draw your route';

  @override
  String get routeDrawHint => 'Tap the map to add stops';

  @override
  String get routeDrawEmptyStops => 'Add at least two stops on the map';

  @override
  String get routePublish => 'Publish';

  @override
  String routePriceToEnd(String amount) {
    return 'To end: $amount';
  }

  @override
  String routeSnapMatched(String name) {
    return 'Matched: $name ✓';
  }

  @override
  String get routeSnapNewStopHint => 'New stop — name?';

  @override
  String get routeSnapPending => 'Snapping…';

  @override
  String get routePriceKeypadTitle => 'Set price to end';

  @override
  String get routePriceKeypadSet => 'Set';

  @override
  String get routePriceErrorNonMonotone =>
      'Prices must not increase toward the destination.';

  @override
  String get routePriceErrorLastNotZero => 'Last stop must be ₦0.';

  @override
  String get routePriceErrorEmpty => 'Add at least one priced stop.';

  @override
  String get routeLoadError => 'Could not load routes.';

  @override
  String get routePublishError => 'Could not publish route. Try again.';

  @override
  String get back => 'Back';

  @override
  String get navHome => 'Home';

  @override
  String get navRoutes => 'Routes';

  @override
  String get navEarnings => 'Earnings';

  @override
  String get navAccount => 'Account';

  @override
  String get earningsStubBody => 'Earnings and balance coming in Phase 4.';

  @override
  String get accountStubBody => 'Account settings coming soon.';

  @override
  String get homeUnverifiedBanner => 'Complete verification to go online.';

  @override
  String get homeBatteryGuardBanner =>
      'Battery low — location updates slowed to save power.';

  @override
  String get homeLedgerBlockedBanner =>
      'Matching paused — settle your balance to go online.';

  @override
  String get homeSelectPark => 'At: select park ▾';

  @override
  String homeAtPark(String parkName) {
    return 'At: $parkName ▾';
  }

  @override
  String get homeDirectionOnRoute => 'Direction: on my route ▾';

  @override
  String get homeDirectionNone => 'Direction: none ▾';

  @override
  String get homeErrorSelectPark =>
      'Choose a park before going online at park.';

  @override
  String get homeErrorLocation => 'Enable location to go online.';

  @override
  String get homeParkPickerTitle => 'Nearby parks';

  @override
  String get homeParkPickerEmpty => 'No parks within range.';

  @override
  String homeParkDistance(int meters) {
    return '$meters m away';
  }

  @override
  String get homeParkSomewhereElse => 'I\'m somewhere else';
}
