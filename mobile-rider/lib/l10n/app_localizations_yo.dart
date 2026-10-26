// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Yoruba (`yo`).
class AppLocalizationsYo extends AppLocalizations {
  AppLocalizationsYo([String locale = 'yo']) : super(locale);

  @override
  String get phoneEntryTitle => 'Move around. Your way.';

  @override
  String get phoneEntrySubtitle =>
      'We text a code to this number so the ride stays yours.';

  @override
  String get continueButton => 'Tẹ̀síwájú';

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
  String get skip => 'Fò';

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
  String get navHome => 'Ilé';

  @override
  String get navTrips => 'Irìn-àjò';

  @override
  String get sponsoredLabel => 'Atìlẹyin';

  @override
  String get navAccount => 'Àkọọlẹ';

  @override
  String get homeSearchHint => 'Níbo ni a ó lọ?';

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
  String get searchTitle => 'Níbo ni?';

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
  String get adjustPickupTitle => 'Ṣàtúnṣe ibi ìgbé';

  @override
  String adjustPickupBoardingAt(String stageName) {
    return 'Wíwọ ọkọ̀ ní: $stageName';
  }

  @override
  String get adjustPickupConfirm => 'Jẹ́rìí ibi náà';

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
  String get hailSearchTitle => 'Níbo lò ń lọ?';

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
    return 'Ìṣẹ́jú-àáyá $seconds ló kù';
  }

  @override
  String get requestingFindingAnother => 'À ń wá ọkọ̀ mìíràn…';

  @override
  String get requestingCancel => 'Fagilé';

  @override
  String get requestingExpired =>
      'Kò sí awakọ̀ tó dáhùn — wo àwọn àṣàyàn mìíràn';

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
  String get wayfindingTitle => 'Ìtọ́sọ́nà ìrìn ẹsẹ̀';

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
  String get wayfindingNoSteps => 'Kò sí ìgbésẹ̀ kankan';

  @override
  String meetVehicleArrivingIn(int minutes) {
    return 'Yóò dé ní ~ìṣẹ́jú $minutes';
  }

  @override
  String meetVehicleWalkTo(int minutes, String park) {
    return 'Rìn ìṣẹ́jú $minutes lọ sí $park';
  }

  @override
  String meetVehicleNaMeHint(String label) {
    return 'Fi èyí han awakọ̀ rẹ — $label';
  }

  @override
  String get meetVehicleDriverSignalLost => 'Àmì awakọ̀ ti sọnù';

  @override
  String get meetVehicleLivePaused => 'Ìmúdójúìwọ̀n tààrà ti dúró';

  @override
  String get meetVehicleShare => 'Pín ìrìn-àjò';

  @override
  String get meetVehicleCancel => 'Fagilé';

  @override
  String get meetVehicleBoarded => 'Mo ti wọlé';

  @override
  String activeTripStatus(int minutes, String fare) {
    return 'In transit · ETA $minutes min · $fare Standard fare';
  }

  @override
  String get activeTripExtend => 'Fi kún un';

  @override
  String get activeTripShare => 'Pín';

  @override
  String get activeTripReport => 'Fi ẹ̀sùn sùn';

  @override
  String get sharePlaceholder => 'Share trip — coming in Phase 5';

  @override
  String get sosPlaceholder => 'SOS — coming in Phase 5';

  @override
  String get extendPlaceholder => 'Extend trip — coming in Phase 5';

  @override
  String get reportPlaceholder => 'Report incident — coming in Phase 5';

  @override
  String get tripCompleteTitle => 'Ìrìn-àjò ti parí';

  @override
  String tripCompletePaidQuestion(String amount) {
    return 'Ṣé o san $amount?';
  }

  @override
  String tripCompletePayQuestion(String amount, String name) {
    return 'San $amount fún $name';
  }

  @override
  String get tripCompletePaidCash => 'Mo san owó lọ́wọ́';

  @override
  String get tripCompleteTier3Question => 'Èló ni o san?';

  @override
  String get tripCompleteYes => 'Bẹ́ẹ̀ ni';

  @override
  String get tripCompleteDifferent => 'Iye owó mìíràn';

  @override
  String get tripCompleteDifferentPrompt => 'Yan iye tí o san';

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
    return 'San $amount';
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
  String get activeTripScan => 'Ṣàyẹ̀wò';

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
  String get sosTeamAlerted => 'Ready to call 112';

  @override
  String get sosSharingDetails => 'Share your live location with your contacts';

  @override
  String sosCallEmergency(String number) {
    return 'Call $number';
  }

  @override
  String get sosShareWithContact => 'Share with a contact';

  @override
  String get sosHoldToCancel => 'Hold to cancel';

  @override
  String get sosRaising => 'Opening the 112 call…';

  @override
  String get sosRaiseFailed => 'Could not open the 112 call';

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
  String get reportIncidentSubmitted => 'Report saved on this phone';

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
  String get accountCityLabel => 'Ìlú ilé';

  @override
  String get accountCityHint =>
      'Maapu àti wíwá n lo ìlú yìí nígbà tí a kò leè rí ibùdó';

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
      'Hold SOS to call 112 and share your location with contacts';

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
      'Saved on this phone. Call 112 when you are back online.';

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
    return '$count ṣófo';
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
  String get seatDriver => 'awakọ̀';

  @override
  String get seatLuggage => 'luggage';

  @override
  String get voiceBookingHint => 'Sọ ọ́, fún àpẹẹrẹ Wuse sí Berger';

  @override
  String get textMapTitle => 'Vehicles nearby';

  @override
  String get textMapEmpty => 'No vehicles in this direction yet';

  @override
  String get plateCheck => 'Mo rí nọ́mbà yìí';

  @override
  String get plateMatches => 'Nọ́mbà bá a mu';

  @override
  String get plateScan => 'Ṣàyẹ̀wò nọ́mbà';

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
  String get guardianTitle => 'Olùṣọ́';

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
  String get guardianOk => 'Mo wà dáadáa';

  @override
  String get guardianOffRouteBody => 'O ti jìnnà sí ọkọ̀ ju bí o ti ṣètò lọ.';

  @override
  String get guardianLongStopBody => 'Ọkọ̀ náà ti dúró pẹ́ ju bí o ti ṣètò lọ.';

  @override
  String get guardianCheckInBody => 'Àkókò àyẹ̀wò tí o ṣètò ti tó.';

  @override
  String get guardianMissedBody => 'Àyẹ̀wò náà ṣì ṣí sílẹ̀.';

  @override
  String get guardianSafeWordHint => 'Sọ ọ̀rọ̀ rẹ';

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

  @override
  String get stageRadarTitle => 'Park board';

  @override
  String get stageRadarLeaving => 'Leaves next';

  @override
  String stageRadarSeats(int free, int total) {
    return '$free of $total free';
  }

  @override
  String get stageRadarEmpty => 'No car is loading here yet';

  @override
  String get stageRadarVerified => 'Verified';

  @override
  String get stageRadarFavourite => 'Save driver';

  @override
  String get fareShieldTitle => 'Fair fare';

  @override
  String get fareShieldQuiet => 'Not enough trips on this corridor yet';

  @override
  String get fareShieldDispute => 'This fare is high';

  @override
  String fareShieldAnchored(int seconds) {
    return 'One offer, open for $seconds seconds';
  }

  @override
  String get fareHistoryTitle => 'By hour';

  @override
  String fareHistoryRow(int hour, String amount) {
    return '$hour:00 · $amount';
  }

  @override
  String activeTripMessage(String name) {
    return 'Fi ọ̀rọ̀ ránṣẹ́ sí $name';
  }

  @override
  String get homeGreetingMorning => 'Ẹ káàárọ̀';

  @override
  String get homeGreetingAfternoon => 'Ẹ káàsán';

  @override
  String get homeGreetingEvening => 'Ẹ káalẹ́';

  @override
  String get homeGreetingNight => 'Ó dàárọ̀';

  @override
  String homeNearbyEta(int minutes) {
    return '~ìṣẹ́jú $minutes';
  }

  @override
  String get tripOptionsRecommended => 'A dábàá';

  @override
  String tripOptionsRequest(String fare) {
    return 'Béèrè $fare';
  }

  @override
  String get searchChooseOnMapDetail => 'Fi àmì sí i';

  @override
  String get searchEmpty => 'Kọ ibùdókọ̀, ọjà tàbí òpópónà';

  @override
  String get tripSortCheapest => 'Èyí tó kéré jù';

  @override
  String get tripSortFastest => 'Èyí tó yára jù';

  @override
  String get tripSortEasiest => 'Ìrìn díẹ̀';

  @override
  String get fareTierVerified => 'Owó ọkọ̀ déédé';

  @override
  String get fareTierCrowd => 'Owó tí àwọn èèyàn ń san';

  @override
  String get fareTierCandidate => 'Kò tíì dájú';

  @override
  String get fareTierEstimate => 'Ìfojúdíwọ̀n, ẹ fohùn ṣọ̀kan';

  @override
  String distanceKm(String km) {
    return 'km $km';
  }

  @override
  String distanceM(int meters) {
    return 'm $meters';
  }

  @override
  String searchResultDetail(String area, String distance) {
    return '$area · $distance sí ibí';
  }

  @override
  String tripOptionsSummary(int minutes, String distance) {
    return 'ìṣẹ́jú $minutes · $distance';
  }

  @override
  String tripMetaWalk(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'ìrìn ìṣẹ́jú $minutes',
    );
    return '$_temp0';
  }

  @override
  String tripMetaWait(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '~ìdúró ìṣẹ́jú $minutes',
    );
    return '$_temp0';
  }

  @override
  String get tripMetaDirect => 'tààrà';

  @override
  String tripMetaTransferAt(String park) {
    return 'ìyípadà 1 ní $park';
  }

  @override
  String tripMetaTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ìyípadà $count',
    );
    return '$_temp0';
  }

  @override
  String get searchShortcutHome => 'Ilé';

  @override
  String get searchShortcutWork => 'Iṣẹ́';

  @override
  String get searchShortcutAdd => 'Fi kún';

  @override
  String get searchShortcutPinDetail => 'Lórí máàpù';

  @override
  String placeAway(String distance) {
    return '$distance sí ibí';
  }

  @override
  String get homePlanYourDayDetail => 'So àwọn ibùdó rẹ pọ̀ sí ìrìn kan';

  @override
  String searchPopularTitle(String city) {
    return 'Gbajúmọ̀ ní $city';
  }

  @override
  String get tripEtaWorkingOut => 'À ń ṣírò ìgbà tí o máa dé';

  @override
  String tripEtaLastTo(String place) {
    return 'Ìṣirò tó kẹ́yìn sí $place';
  }

  @override
  String tripEtaArrivingAt(String place) {
    return 'Ò ń dé $place';
  }

  @override
  String get tripEtaPaused => 'Àkókò tààrà ti dúró';

  @override
  String get tripRetry => 'Tún gbìyànjú';

  @override
  String tripEtaTraffic(int minutes) {
    return 'Súnkẹrẹ-fàkẹrẹ wà níwájú. Bíi ìṣẹ́jú $minutes lẹ́yìn.';
  }

  @override
  String get tripMinUnit => 'ìṣẹ́jú';

  @override
  String tripAboutClock(String time) {
    return 'Ní nǹkan bí $time';
  }

  @override
  String tripClockRange(String first, String last) {
    return '$first sí $last';
  }

  @override
  String tripMinutesLabel(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'ìṣẹ́jú $minutes',
      one: 'ìṣẹ́jú 1',
    );
    return '$_temp0';
  }

  @override
  String tripMinutesRangeLabel(int low, int high) {
    return 'Ìṣẹ́jú $low sí $high';
  }

  @override
  String get tripEmergency => 'Pàjáwìrì';

  @override
  String get tripSos => 'SOS';

  @override
  String get tripCall => 'Pè é';

  @override
  String tripCallName(String name) {
    return 'Pe $name';
  }

  @override
  String get tripMessage => 'Ìfiránṣẹ́';

  @override
  String tripArrivesIn(String name) {
    return '$name máa dé ní';
  }

  @override
  String tripIsHere(String name) {
    return '$name ti dé';
  }

  @override
  String get tripDriverHere => 'Awakọ̀ ti dé';

  @override
  String get tripMeetAtPickup => 'Pàdé ní ibi ìgbé';

  @override
  String tripCountdownLabel(int minutes, int seconds) {
    return 'Ìṣẹ́jú $minutes àti ìṣẹ́jú-àáyá $seconds';
  }

  @override
  String get tripPinTitle => 'PIN ìrìn-àjò';

  @override
  String get tripPinSay => 'Sọ ọ́ ní ẹnu ọ̀nà';

  @override
  String get tripPinNew => 'Gba PIN tuntun';

  @override
  String get tripPinTooSoon => 'O ṣẹ̀ṣẹ̀ gba PIN tuntun. Tún gbìyànjú láìpẹ́.';

  @override
  String get tripPinFailed => 'A kò rí PIN tuntun gbà. Tún gbìyànjú.';

  @override
  String get tripMatchedTitle => 'A ti so yín pọ̀';

  @override
  String tripMatchedBody(String name) {
    return 'Wọlé. $name máa bẹ̀rẹ̀ ìrìn-àjò náà.';
  }

  @override
  String get receiptTitle => 'Ìwé-ẹ̀rí ìsanwó';

  @override
  String get receiptNotReady => 'Ìwé-ẹ̀rí kò tíì ṣetán';

  @override
  String get receiptNotReadyBody => 'Ó ṣì ń bọ̀. Yóò tún wà nínú Ìrìn-àjò.';

  @override
  String get receiptTryAgain => 'Tún gbìyànjú';

  @override
  String get receiptDone => 'Ó ti parí';

  @override
  String receiptHowWas(String name) {
    return 'Báwo ni $name ṣe ṣe?';
  }

  @override
  String get receiptFare => 'Owó ọkọ̀';

  @override
  String get receiptTotal => 'Àpapọ̀';

  @override
  String get receiptCashPaid => 'Owó tí a san';

  @override
  String get receiptChangeToWallet => 'Fi ṣẹ́ǹjì sí àpò owó';

  @override
  String receiptWalletNow(String amount) {
    return 'Àpò owó báyìí $amount';
  }

  @override
  String get receiptLoadSurcharge => 'Owó àfikún ẹrù';

  @override
  String get receiptAlongFee => 'Owó Along';

  @override
  String get receiptYourTrip => 'Ìrìn-àjò rẹ';

  @override
  String receiptRoute(String from, String to) {
    return '$from sí $to';
  }

  @override
  String receiptToday(String time) {
    return 'Òní, $time';
  }

  @override
  String get receiptYourDriver => 'awakọ̀ rẹ';

  @override
  String get ratingTagSafeDriving => 'Ìwakọ̀ aláàbò';

  @override
  String get ratingTagFairFare => 'Owó tó tọ́';

  @override
  String get ratingTagCleanVehicle => 'Ọkọ̀ tó mọ́';

  @override
  String get ratingTagPolite => 'Oníwà rere';

  @override
  String get ratingTagOnTime => 'Ní àkókò';

  @override
  String meetVehicleArrivingAt(String time) {
    return 'Ó ń bọ̀ · $time';
  }

  @override
  String get meetVehicleCalculating => 'À ń ṣírò ìgbà tí wọ́n máa dé';

  @override
  String meetVehicleDriverStats(String rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ìrìn-àjò $count',
      one: 'ìrìn-àjò 1',
    );
    return '★ $rating · $_temp0';
  }

  @override
  String meetVehicleMeetAt(String place) {
    return 'Pàdé ní $place';
  }

  @override
  String requestingFinding(String mode) {
    return 'À ń wá $mode rẹ';
  }

  @override
  String requestingSeenNear(String place) {
    return 'Àwọn awakọ̀ nítòsí $place lè rí ìbéèrè rẹ';
  }

  @override
  String get requestingFare => 'Owó ọkọ̀';

  @override
  String get adjustPickupPinLabel => 'Àmì tí o fi sílẹ̀';

  @override
  String get adjustPickupHint =>
      'Tẹ màápù tàbí ibùdókọ̀ nísàlẹ̀ láti gbé àmì náà';

  @override
  String get adjustPickupNearby => 'Àwọn ibùdókọ̀ nítòsí';

  @override
  String get tripCompleteFareLabel => 'Owó ọkọ̀';

  @override
  String tripCompleteRoute(String from, String to) {
    return '$from → $to';
  }
}
