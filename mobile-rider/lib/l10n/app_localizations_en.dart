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

  @override
  String get tripOptionsTitle => 'Trip options';

  @override
  String get tripOptionsHeading => 'Choose how to go';

  @override
  String get tripOptionsDegradedBanner => 'Live times unavailable';

  @override
  String get tripOptionsSlowerDirectCaption => 'Slower than transfer options';

  @override
  String get tripOptionsAgreePrice => 'Agree price';

  @override
  String get tripOptionsAgreePricePlaceholder =>
      'Along Pricing arrives in a later phase';

  @override
  String get pricingTitle => 'Along Pricing';

  @override
  String get pricingLapsed => 'No agreement — try another vehicle';

  @override
  String get pricingOutOfRange => 'Vehicle has passed';

  @override
  String get pricingDeclined => 'Offer declined';

  @override
  String pricingDriverOffer(String amount) {
    return 'Driver offered $amount';
  }

  @override
  String get hailSearchTitle => 'Where are you going?';

  @override
  String get requestUndoMessage => 'Requesting…';

  @override
  String get loadFlagTitle => 'Carrying load?';

  @override
  String get loadFlagSizeSmall => 'Small';

  @override
  String get loadFlagSizeMedium => 'Medium';

  @override
  String get loadFlagSizeLarge => 'Large';

  @override
  String get loadFlagNoteHint => 'Optional note (140 characters)';

  @override
  String get loadFlagRememberDay => 'Remember for today';

  @override
  String get loadFlagCapacityWarning => 'This mode may not fit your load';

  @override
  String get loadFlagRequestAnyway => 'Request anyway';

  @override
  String get loadFlagDone => 'Done';

  @override
  String requestingTitle(String mode) {
    return 'Requesting a $mode…';
  }

  @override
  String requestingCountdown(int seconds) {
    return '${seconds}s remaining';
  }

  @override
  String get requestingFindingAnother => 'Finding another vehicle…';

  @override
  String get requestingCancel => 'Cancel';

  @override
  String get requestingExpired => 'No driver responded — see other options';

  @override
  String get requestingAcceptedPlaceholder =>
      'Driver accepted — meet your vehicle arrives next';

  @override
  String get coverageGapTitle => 'No mapped routes here yet';

  @override
  String coverageGapNearestBoarding(String name, String distance) {
    return 'Nearest known boarding point: $name · $distance';
  }

  @override
  String coverageGapDistanceKm(String km) {
    return '$km km';
  }

  @override
  String coverageGapDistanceM(int m) {
    return '$m m';
  }

  @override
  String get coverageGapVehiclesNone => 'Vehicles nearby: none';

  @override
  String coverageGapVehiclesNearby(int count) {
    return 'Vehicles nearby: $count';
  }

  @override
  String get coverageGapWalkThere => 'Walk there';

  @override
  String get coverageGapTellUs => 'Tell us about this area';

  @override
  String get coverageGapThanks => 'Thanks — we logged your report';

  @override
  String get tripOptionsWhy => 'Why?';

  @override
  String get tripOptionsWhyTitle => 'Why recommended';

  @override
  String get tripOptionsWhyFare => 'Fare';

  @override
  String get tripOptionsWhyTime => 'Time';

  @override
  String get tripOptionsWhyEffort => 'Effort';

  @override
  String get tripOptionsShowLegs => 'Show legs';

  @override
  String get tripOptionsHideLegs => 'Hide legs';

  @override
  String tripOptionsRequestLeg(int leg, String fare) {
    return 'Request leg $leg · $fare';
  }

  @override
  String get transferTitle => 'Next leg';

  @override
  String get transferNextLegTitle => 'Next leg';

  @override
  String transferSupply(String bucket) {
    return '$bucket loading';
  }

  @override
  String get transferRequestNextLeg => 'Request next leg';

  @override
  String get transferChangePlan => 'Change plan';

  @override
  String get transferWalkLoading => 'Loading walking directions…';

  @override
  String get wayfindingTitle => 'Walking directions';

  @override
  String get wayfindingModeText => 'Text';

  @override
  String get wayfindingModeMap => 'Map';

  @override
  String get wayfindingModeAudio => 'Audio';

  @override
  String get wayfindingPlay => 'Play';

  @override
  String get wayfindingPause => 'Pause';

  @override
  String get wayfindingArrived => 'Arrived';

  @override
  String get wayfindingDegraded => 'Directions may be approximate';

  @override
  String wayfindingMapHint(int count) {
    return 'Route with $count points';
  }

  @override
  String get wayfindingNoSteps => 'No steps available';

  @override
  String meetVehicleArrivingIn(int minutes) {
    return 'Arriving in ~$minutes min';
  }

  @override
  String meetVehicleWalkTo(int minutes, String park) {
    return 'Walk $minutes min to $park';
  }

  @override
  String meetVehicleNaMeHint(String label) {
    return 'Show this to your driver — $label';
  }

  @override
  String get meetVehicleDriverSignalLost => 'Driver signal lost';

  @override
  String get meetVehicleLivePaused => 'Live updates paused';

  @override
  String get meetVehicleShare => 'Share trip';

  @override
  String get meetVehicleCancel => 'Cancel';

  @override
  String get meetVehicleBoarded => 'I\'ve boarded';

  @override
  String activeTripStatus(int minutes, String fare) {
    return 'In transit · ETA $minutes min · $fare Standard fare';
  }

  @override
  String get activeTripExtend => 'Extend';

  @override
  String get activeTripShare => 'Share';

  @override
  String get activeTripReport => 'Report';

  @override
  String get sharePlaceholder => 'Share trip — coming in Phase 5';

  @override
  String get sosPlaceholder => 'SOS — coming in Phase 5';

  @override
  String get extendPlaceholder => 'Extend trip — coming in Phase 5';

  @override
  String get reportPlaceholder => 'Report incident — coming in Phase 5';

  @override
  String get tripCompleteTitle => 'Trip complete';

  @override
  String tripCompletePaidQuestion(String amount) {
    return 'Did you pay $amount?';
  }

  @override
  String get tripCompleteTier3Question => 'What did you pay?';

  @override
  String get tripCompleteYes => 'Yes';

  @override
  String get tripCompleteDifferent => 'Different amount';

  @override
  String get tripCompleteDifferentPrompt => 'Pick the amount you paid';

  @override
  String get tripCompleteRateTitle => 'Rate your trip';

  @override
  String get extendTripTitle => 'Extend trip';

  @override
  String get extendTripSearchHint => 'Where to now?';

  @override
  String extendTripDestination(String destination) {
    return 'Continuing to $destination';
  }

  @override
  String get extendTripSend => 'Send to driver';

  @override
  String get incomingExtensionTitle => 'Extension request';

  @override
  String incomingExtensionBody(String destination, String delta) {
    return 'Driver proposes continuing to $destination for +$delta';
  }

  @override
  String get incomingExtensionAccept => 'Accept';

  @override
  String get incomingExtensionDecline => 'Decline';

  @override
  String get payDriverTitle => 'Pay driver';

  @override
  String payDriverCta(String amount) {
    return 'Pay $amount';
  }

  @override
  String get payDriverAmountLocked => 'Amount locked to this trip';

  @override
  String get payDriverMethodSaved => 'Visa ···4242';

  @override
  String get payDriverPending => 'Payment initiation — deferred to P1-G-01';

  @override
  String get tripsEmpty => 'No completed trips yet.';

  @override
  String get tripDetailTitle => 'Trip details';

  @override
  String get tripDetailMissing => 'Trip not found';

  @override
  String get tripDetailShareReceipt => 'Share receipt';

  @override
  String get tripDetailReceiptCopied => 'Receipt copied to clipboard';
}
