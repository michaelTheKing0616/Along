// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get phoneEntryTitle => 'Move around. Your way.';

  @override
  String get phoneEntrySubtitle => 'Enter your number to continue';

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
  String get nameTitle => 'What should drivers call you?';

  @override
  String get nameHint => 'Your name';

  @override
  String get skip => 'Skip';

  @override
  String get errorInvalidPhone => 'Enter a valid Nigerian number';

  @override
  String errorRateLimited(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s';
  }

  @override
  String get errorWrongOtp => 'Incorrect code — try again';

  @override
  String get errorExpiredOtp => 'Code expired — request a new one';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navTrips => 'Trips';

  @override
  String get navAccount => 'Account';

  @override
  String get homeSearchHint => 'Where to?';

  @override
  String get homeLocationDeniedBanner =>
      'Enable location to see nearby vehicles';

  @override
  String get homeChooseOnMap => 'Choose on map';

  @override
  String get homeNearbyTitle => 'Nearby';

  @override
  String homeNearbyRow(
    String countBucket,
    String mode,
    String heading,
    int minutes,
  ) {
    return '$countBucket $mode nearby · heading $heading · ~$minutes min';
  }

  @override
  String get homeExpandNearby => 'Show nearby';

  @override
  String get homeCollapseNearby => 'Hide nearby';

  @override
  String get modeCar => 'cars';

  @override
  String get modeKeke => 'kekes';

  @override
  String get modeOkada => 'okadas';

  @override
  String get modeMinibus => 'minibuses';

  @override
  String get searchTitle => 'Where to?';

  @override
  String get searchRecentsTitle => 'Recents';

  @override
  String get searchResultsTitle => 'Results';

  @override
  String get searchOfflineHint => 'Offline — showing recents only';

  @override
  String searchResultSubtitle(String area, int distanceM) {
    return '$area · $distanceM m away';
  }

  @override
  String get adjustPickupTitle => 'Adjust pickup';

  @override
  String adjustPickupBoardingAt(String stageName) {
    return 'Boarding at: $stageName';
  }

  @override
  String get adjustPickupConfirm => 'Confirm location';

  @override
  String get tripsStubBody => 'Your trips will appear here.';

  @override
  String get accountStubBody => 'Account settings arrive in a later task.';

  @override
  String get tripOptionsStubTitle => 'Trip options';

  @override
  String get tripOptionsStubBody =>
      'Route and fare options arrive in the next task.';
}
