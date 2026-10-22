// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hausa (`ha`).
class AppLocalizationsHa extends AppLocalizations {
  AppLocalizationsHa([String locale = 'ha']) : super(locale);

  @override
  String get phoneEntryTitle => 'Move around. Your way.';

  @override
  String get phoneEntrySubtitle =>
      'We text a code to this number so the ride stays yours.';

  @override
  String get continueButton => 'Ci gaba';

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
  String get skip => 'Tsallake';

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
  String get errorAuthNotConfigured =>
      'This build is not connected to Along. Rebuild the staging APK with env/staging.json.';

  @override
  String get navHome => 'Gida';

  @override
  String get navTrips => 'Tafiye-tafiye';

  @override
  String get sponsoredLabel => 'Tallafi';

  @override
  String get navAccount => 'Asusu';

  @override
  String get homeSearchHint => 'Ina za a je?';

  @override
  String get homeMenu => 'Menu';

  @override
  String get homeVehicles => 'Vehicles';

  @override
  String get homeRecenter => 'Recenter';

  @override
  String get guardianIntro =>
      'A check-in on this ride, only when you ask for it.';

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
  String get searchOfflineHint => 'Offline — search uses cached places';

  @override
  String get cachedOptionsStaleBadge => 'Cached · may be outdated';

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
  String tripCompletePayQuestion(String amount, String name) {
    return 'Pay $amount to $name';
  }

  @override
  String get tripCompletePaidCash => 'Paid cash';

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
  String payDriverPending(String amount) {
    return 'Transfer $amount in your bank app';
  }

  @override
  String get payDriverCopyAccount => 'Copy number';

  @override
  String get payDriverAccountCopied => 'Account number copied';

  @override
  String get payDriverWaitingTransfer => 'Waiting for your transfer';

  @override
  String get payDriverOtherAmount => 'Other';

  @override
  String get payDriverOtherHint => 'Enter amount';

  @override
  String payDriverExpires(int seconds) {
    return 'Expires in ${seconds}s';
  }

  @override
  String get payDriverOpenCheckout => 'Open bank page';

  @override
  String get payDriverMethodTransfer => 'Bank transfer';

  @override
  String get payDriverMethodUssd => 'USSD';

  @override
  String get payDriverChangeMethod => 'Change';

  @override
  String payDriverCashOnly(String name) {
    return '$name accepts cash only';
  }

  @override
  String get payDriverInactive => 'This code is no longer active';

  @override
  String get payDriverDifferentDriver =>
      'Your active trip is with another driver';

  @override
  String get payDriverConfirmOther =>
      'This isn\'t my trip\'s driver — pay anyway';

  @override
  String get payDriverFailed => 'Payment failed';

  @override
  String get payDriverRetry => 'Try again';

  @override
  String get payDriverSuccessTitle => 'Paid';

  @override
  String payDriverSuccessItemised(
    String driverAmount,
    String name,
    String feeAmount,
  ) {
    return '$driverAmount to $name · $feeAmount Along fee';
  }

  @override
  String get payDriverHistoryOptIn => 'Add this trip to your history?';

  @override
  String get scanToPayTitle => 'Scan to pay';

  @override
  String get scanEnterCode => 'Enter code instead';

  @override
  String get scanEnterCodePrompt => 'Enter driver code';

  @override
  String get scanCodeHint => '8-character code';

  @override
  String get scanCodeSubmit => 'Continue';

  @override
  String get scanBackToCamera => 'Back to camera';

  @override
  String get scanNotAlong => 'Not an Along code';

  @override
  String get payMethodsTitle => 'Payment methods';

  @override
  String get payMethodsDefault => 'Default';

  @override
  String get payMethodsSetDefault => 'Set as default';

  @override
  String get payMethodsRemove => 'Remove';

  @override
  String get payMethodsAdd => 'Add card';

  @override
  String get payMethodsTransferDefault => 'Pay with transfer by default';

  @override
  String get activeTripScan => 'Scan';

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

  @override
  String get sosTeamAlerted => 'Along safety team alerted';

  @override
  String get sosSharingDetails =>
      'We\'re sharing your live location and trip details with our safety line';

  @override
  String sosCallEmergency(String number) {
    return 'Call $number';
  }

  @override
  String get sosShareWithContact => 'Share with a contact';

  @override
  String get sosHoldToCancel => 'Hold to cancel';

  @override
  String get sosRaising => 'Alerting safety team…';

  @override
  String get sosRaiseFailed => 'Could not reach safety line';

  @override
  String get sosRetry => 'Try again';

  @override
  String get reportIncidentTitle => 'Report incident';

  @override
  String get reportIncidentCategoryHeading => 'What happened?';

  @override
  String get reportIncidentDescriptionHeading => 'Tell us more';

  @override
  String get reportIncidentDescriptionHint =>
      'Describe what happened (optional details help)';

  @override
  String get reportIncidentAttachPhoto => 'Attach photo';

  @override
  String get reportIncidentPhotoAttached => 'Photo attached (stub)';

  @override
  String get reportIncidentSubmit => 'Submit report';

  @override
  String get reportIncidentPickCategory => 'Pick a category';

  @override
  String get reportIncidentDescriptionRequired => 'Add a short description';

  @override
  String get reportIncidentSubmitted =>
      'Report submitted — our safety team will review it';

  @override
  String get incidentCategorySafety => 'Safety';

  @override
  String get incidentCategoryFareDispute => 'Fare dispute';

  @override
  String get incidentCategoryVehicleQuality => 'Vehicle quality';

  @override
  String get incidentCategoryDriverBehavior => 'Driver behaviour';

  @override
  String get incidentCategoryLostItem => 'Lost item';

  @override
  String get incidentCategoryOther => 'Other';

  @override
  String get shareTripTitle => 'Share live trip';

  @override
  String get shareTripCreateLink => 'Create share link';

  @override
  String get shareTripCopy => 'Copy link';

  @override
  String get shareTripSms => 'SMS';

  @override
  String get shareTripCopied => 'Link copied';

  @override
  String get shareTripExpiryNote => 'Links auto-expire when your trip ends';

  @override
  String get shareTripActiveHeading => 'Active shares';

  @override
  String get shareTripAnonymousContact => 'Shared contact';

  @override
  String shareTripExpires(String date) {
    return 'Expires $date';
  }

  @override
  String shareTripSmsBody(String url) {
    return 'Track my Along trip: $url';
  }

  @override
  String get accountProfileHeading => 'PROFILE';

  @override
  String get accountPreferencesHeading => 'PREFERENCES';

  @override
  String get accountCityLabel => 'Birnin gida';

  @override
  String get accountCityHint =>
      'Taswira da bincike suna amfani da wannan birni idan wuri bai samu ba';

  @override
  String get accountPaymentHeading => 'PAYMENT';

  @override
  String get accountSafetyHeading => 'SAFETY';

  @override
  String get accountWayfindingLabel => 'Wayfinding mode';

  @override
  String get accountSortLabel => 'Default trip sort';

  @override
  String get accountWomenOnlyLabel => 'Women-only matching';

  @override
  String get accountWomenOnlyHint =>
      'Prefer trips with women-only drivers when available';

  @override
  String get accountPaymentCashDefault => 'Cash';

  @override
  String get accountPaymentCashHint => 'Default payment method for Along trips';

  @override
  String get accountSafetyHowSos => 'How SOS works';

  @override
  String get accountSafetyHowSosBody =>
      'Hold SOS during a trip to alert our safety team and share live location';

  @override
  String get accountHelp => 'Help & support';

  @override
  String get accountLegal => 'Legal';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get homePlanYourDay => 'Plan your day';

  @override
  String get dayPlannerTitle => 'Today\'s plan';

  @override
  String get dayPlannerEmpty => 'No stops in your plan yet';

  @override
  String get dayPlannerNotBookedHint =>
      'Stops are planned — matching starts when you tap Match now. Nothing is reserved ahead of time.';

  @override
  String get dayPlannerLoadToggle => 'Load today';

  @override
  String get dayPlannerMatchNow => 'Match now';

  @override
  String get dayPlannerPrepare => 'Prepare';

  @override
  String get dayPlannerAddStop => 'Add stop';

  @override
  String get dayPlannerStopDone => 'Done';

  @override
  String dayPlannerStopInProgress(int minutes) {
    return 'In progress · ETA $minutes min';
  }

  @override
  String get dayPlannerStopReady => 'Ready — tap Match now below';

  @override
  String get dayPlannerStopPrepareHint => 'Tap Prepare when you are ready';

  @override
  String get dayPlannerStopPending => 'Up next';

  @override
  String get dayPlannerStopSkipped => 'Skipped';

  @override
  String get itineraryEntryTitle => 'Plan your day';

  @override
  String get itineraryEntryStructured => 'Stops';

  @override
  String get itineraryEntryNaturalLanguage => 'Describe';

  @override
  String get itineraryEntryStopHint => 'Where to?';

  @override
  String get itineraryEntryAddRow => 'Add another stop';

  @override
  String get itineraryEntryDescribeDay => 'Describe your day';

  @override
  String get itineraryEntryNlHint =>
      'e.g. drop kids at school, then work, then market';

  @override
  String get itineraryEntryMicTitle => 'Say your stops';

  @override
  String get itineraryEntryMicHint => 'Speak or type your stops…';

  @override
  String get itineraryEntryParse => 'Preview stops';

  @override
  String get itineraryEntryProposalTitle => 'We heard';

  @override
  String get itineraryEntryUnresolved => 'Needs a place name';

  @override
  String get itineraryEntryLooksRight => 'Looks right';

  @override
  String get itineraryEntrySavePlan => 'Save plan';

  @override
  String get sosQueued =>
      'Saved on this phone. We\'ll alert the safety team when you\'re back online.';

  @override
  String get sosLiveLink => 'Copy live location link';

  @override
  String get sosLiveLinkCopied => 'Live location link copied';

  @override
  String get sosContactsHeading => 'Tell someone you trust';

  @override
  String sosContactWhatsapp(String name) {
    return 'WhatsApp $name';
  }

  @override
  String sosContactSms(String name) {
    return 'Text $name';
  }

  @override
  String get emergencyContactsHeading => 'EMERGENCY CONTACTS';

  @override
  String get emergencyContactsHint =>
      'We notify these people if you raise SOS. Up to 5. WhatsApp or a text opens on your phone.';

  @override
  String get emergencyContactsEmpty => 'No emergency contacts yet';

  @override
  String get emergencyContactName => 'Name';

  @override
  String get emergencyContactPhone => 'Phone';

  @override
  String get emergencyContactAdd => 'Add contact';

  @override
  String emergencyContactRemove(String name) {
    return 'Remove $name';
  }

  @override
  String get emergencyContactInvalidPhone =>
      'Use a phone number like +2348012345678';

  @override
  String get emergencyContactLimit => 'You can save up to 5 contacts';

  @override
  String get emergencyContactSaveFailed => 'Could not save that contact';

  @override
  String get vehiclesTitle => 'Vehicles';

  @override
  String freeSeatCount(int count) {
    return '$count free';
  }

  @override
  String get seatStale => 'Seat map is more than a minute old';

  @override
  String get seatMapTitle => 'Seat map';

  @override
  String get filterRulesHint => 'Search a driver\'s rules';

  @override
  String get seatTaken => 'That seat was just taken';

  @override
  String get acknowledgeToClaim => 'I agree';

  @override
  String get noVehicles => 'No vehicles match these rules';

  @override
  String get seatFree => 'free';

  @override
  String get seatOccupied => 'occupied';

  @override
  String get seatHeld => 'held';

  @override
  String get seatBlocked => 'blocked';

  @override
  String get seatDriver => 'driver';

  @override
  String get seatLuggage => 'luggage';

  @override
  String get voiceBookingHint => 'Say it, for example Wuse to Berger';

  @override
  String get textMapTitle => 'Vehicles nearby';

  @override
  String get textMapEmpty => 'No vehicles in this direction yet';

  @override
  String get plateCheck => 'I see this plate';

  @override
  String get plateMatches => 'Plate matches';

  @override
  String get plateScan => 'Scan plate';

  @override
  String get plateScanHint => 'Fit the plate in the frame';

  @override
  String get plateScanDenied =>
      'Camera is off. You can still confirm the plate yourself.';

  @override
  String get plateScanMismatch =>
      'This plate does not match the registered one.';

  @override
  String get plateScanReport => 'Report';

  @override
  String get plateScanSos => 'SOS';

  @override
  String get plateScanTorch => 'Light';

  @override
  String get plateScanContinue => 'Continue';

  @override
  String get guardianTitle => 'Guardian';

  @override
  String get guardianEnabled => 'Check in on this trip';

  @override
  String get guardianOffRoute => 'Off-route metres';

  @override
  String get guardianLongStop => 'Long stop minutes';

  @override
  String get guardianCheckIn => 'Check-in minutes';

  @override
  String get guardianSafeWord => 'Safe word';

  @override
  String get guardianSave => 'Save';

  @override
  String get guardianOk => 'I\'m OK';

  @override
  String get guardianOffRouteBody =>
      'You are farther from the vehicle than you set.';

  @override
  String get guardianLongStopBody =>
      'The vehicle has been still longer than you set.';

  @override
  String get guardianCheckInBody => 'Time for the check-in you set.';

  @override
  String get guardianMissedBody => 'The check-in is still open.';

  @override
  String get guardianSafeWordHint => 'Say your word';

  @override
  String get tripMessagesTitle => 'Message the driver';

  @override
  String get tripMessagesClosed => 'This conversation is closed.';

  @override
  String get tripMessagesDriver => 'Driver';

  @override
  String get tripMessagesRider => 'You';

  @override
  String get tripMessagesHint => 'A note about something left behind';

  @override
  String get tripMessagesSend => 'Send';

  @override
  String get holdNotOffered => 'This driver has not turned on seat holds';

  @override
  String get walkExtension => 'Minutes you need to walk';
}
