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
  String get phoneEntrySubtitle =>
      'We text a code to this number so the ride stays yours.';

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
  String get errorAuthNotConfigured =>
      'This build is not connected to Along. Rebuild the staging APK with env/staging.json.';

  @override
  String get navHome => 'Home';

  @override
  String get navTrips => 'Trips';

  @override
  String get sponsoredLabel => 'Sponsored';

  @override
  String get navAccount => 'Account';

  @override
  String get homeSearchHint => 'Where to?';

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
  String get modeKeke => 'kekes';

  @override
  String get searchTitle => 'Where to?';

  @override
  String get searchRecentsTitle => 'Recents';

  @override
  String get searchResultsTitle => 'Results';

  @override
  String get searchOfflineHint => 'Offline · searching saved places';

  @override
  String get cachedOptionsStaleBadge => 'Cached · may be outdated';

  @override
  String get adjustPickupTitle => 'Adjust pickup';

  @override
  String adjustPickupBoardingAt(String stageName) {
    return 'Boarding at: $stageName';
  }

  @override
  String get adjustPickupConfirm => 'Confirm location';

  @override
  String get tripOptionsHeading => 'Choose how to go';

  @override
  String get tripOptionsDegradedBanner => 'Live times unavailable';

  @override
  String get tripOptionsSlowerDirectCaption => 'Slower than transfer options';

  @override
  String get tripOptionsAgreePrice => 'Agree price';

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
  String get activeTripExtend => 'Extend';

  @override
  String get activeTripShare => 'Share';

  @override
  String get activeTripReport => 'Report';

  @override
  String get tripCompleteTitle => 'Trip complete';

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
  String get accountCityLabel => 'Home city';

  @override
  String get accountCityHint =>
      'Map and search default to this city when location is unavailable';

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
    return '$count free';
  }

  @override
  String get seatStale => 'Seat map is more than a minute old';

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
    return 'Message $name';
  }

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeGreetingNight => 'Good night';

  @override
  String homeNearbyEta(int minutes) {
    return '~$minutes min';
  }

  @override
  String get tripOptionsRecommended => 'Recommended';

  @override
  String tripOptionsRequest(String fare) {
    return 'Request $fare';
  }

  @override
  String get searchChooseOnMapDetail => 'Drop a pin';

  @override
  String get searchEmpty => 'Type a park, market or street';

  @override
  String get tripSortCheapest => 'Cheapest';

  @override
  String get tripSortFastest => 'Fastest';

  @override
  String get tripSortEasiest => 'Least walking';

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String distanceM(int meters) {
    return '$meters m';
  }

  @override
  String searchResultDetail(String area, String distance) {
    return '$area · $distance away';
  }

  @override
  String tripOptionsSummary(int minutes, String distance) {
    return '$minutes min · $distance';
  }

  @override
  String tripMetaWalk(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min walk',
      one: '1 min walk',
    );
    return '$_temp0';
  }

  @override
  String tripMetaWait(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '~$minutes min wait',
      one: '~1 min wait',
    );
    return '$_temp0';
  }

  @override
  String get tripMetaDirect => 'direct';

  @override
  String tripMetaTransferAt(String park) {
    return '1 transfer at $park';
  }

  @override
  String tripMetaTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers',
      one: '1 transfer',
    );
    return '$_temp0';
  }

  @override
  String get searchShortcutHome => 'Home';

  @override
  String get searchShortcutWork => 'Work';

  @override
  String get searchShortcutAdd => 'Add';

  @override
  String get searchShortcutPinDetail => 'On the map';

  @override
  String placeAway(String distance) {
    return '$distance away';
  }

  @override
  String get homePlanYourDayDetail => 'Chain your stops into one trip';

  @override
  String searchPopularTitle(String city) {
    return 'Popular in $city';
  }

  @override
  String get tripEtaWorkingOut => 'Working out your arrival';

  @override
  String tripEtaLastTo(String place) {
    return 'Last estimate to $place';
  }

  @override
  String tripEtaArrivingAt(String place) {
    return 'Arriving at $place';
  }

  @override
  String get tripEtaPaused => 'Live times paused';

  @override
  String get tripRetry => 'Retry';

  @override
  String tripEtaTraffic(int minutes) {
    return 'Traffic ahead. About $minutes min later.';
  }

  @override
  String get tripMinUnit => 'min';

  @override
  String tripAboutClock(String time) {
    return 'About $time';
  }

  @override
  String tripClockRange(String first, String last) {
    return '$first–$last';
  }

  @override
  String tripMinutesLabel(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String tripMinutesRangeLabel(int low, int high) {
    return '$low to $high minutes';
  }

  @override
  String get tripEmergency => 'Emergency';

  @override
  String get tripSos => 'SOS';

  @override
  String get tripCall => 'Call';

  @override
  String tripCallName(String name) {
    return 'Call $name';
  }

  @override
  String get tripMessage => 'Message';

  @override
  String tripArrivesIn(String name) {
    return '$name arrives in';
  }

  @override
  String tripIsHere(String name) {
    return '$name is here';
  }

  @override
  String get tripDriverHere => 'Driver is here';

  @override
  String get tripMeetAtPickup => 'Meet at pickup';

  @override
  String tripCountdownLabel(int minutes, int seconds) {
    return '$minutes minutes $seconds seconds';
  }

  @override
  String get tripPinTitle => 'Trip PIN';

  @override
  String get tripPinSay => 'Say it at the door';

  @override
  String get tripPinNew => 'Get a new PIN';

  @override
  String get tripPinTooSoon => 'You just got a new PIN. Try again in a moment.';

  @override
  String get tripPinFailed => 'Couldn\'t get a new PIN. Try again.';

  @override
  String get tripMatchedTitle => 'You\'re matched';

  @override
  String tripMatchedBody(String name) {
    return 'Get in. $name will start the trip.';
  }

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptNotReady => 'Receipt not ready';

  @override
  String get receiptNotReadyBody =>
      'It is still on its way. It will also be in Trips.';

  @override
  String get receiptTryAgain => 'Try again';

  @override
  String get receiptDone => 'Done';

  @override
  String receiptHowWas(String name) {
    return 'How was $name?';
  }

  @override
  String get receiptFare => 'Fare';

  @override
  String get receiptTotal => 'Total';

  @override
  String get receiptCashPaid => 'Cash paid';

  @override
  String get receiptChangeToWallet => 'Change to wallet';

  @override
  String receiptWalletNow(String amount) {
    return 'Wallet now $amount';
  }

  @override
  String get receiptLoadSurcharge => 'Load surcharge';

  @override
  String get receiptAlongFee => 'Along fee';

  @override
  String get receiptYourTrip => 'Your trip';

  @override
  String receiptRoute(String from, String to) {
    return '$from to $to';
  }

  @override
  String receiptToday(String time) {
    return 'Today, $time';
  }

  @override
  String get receiptYourDriver => 'your driver';

  @override
  String get ratingTagSafeDriving => 'Safe driving';

  @override
  String get ratingTagFairFare => 'Fair fare';

  @override
  String get ratingTagCleanVehicle => 'Clean car';

  @override
  String get ratingTagPolite => 'Polite';

  @override
  String get ratingTagOnTime => 'On time';

  @override
  String meetVehicleArrivingAt(String time) {
    return 'Arriving · $time';
  }

  @override
  String get meetVehicleCalculating => 'Working out when they arrive';

  @override
  String meetVehicleDriverStats(String rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
    );
    return '★ $rating · $_temp0';
  }

  @override
  String meetVehicleMeetAt(String place) {
    return 'Meet at $place';
  }

  @override
  String requestingFinding(String mode) {
    return 'Finding your $mode';
  }

  @override
  String requestingSeenNear(String place) {
    return 'Drivers near $place can see your request';
  }

  @override
  String get requestingFare => 'Fare';

  @override
  String get adjustPickupPinLabel => 'Dropped pin';

  @override
  String get adjustPickupHint => 'Tap the map or a stop below to move the pin';

  @override
  String get adjustPickupNearby => 'Stops nearby';

  @override
  String get tripCompleteFareLabel => 'Fare';

  @override
  String tripCompleteRoute(String from, String to) {
    return '$from → $to';
  }

  @override
  String get tripEtaCalculating => 'Calculating…';

  @override
  String get activeTripCall => 'Call';

  @override
  String get activeTripSos => 'Hold for SOS';

  @override
  String get activeTripNaMe => 'Show Na Me';

  @override
  String get tripCompleteSettleQuestion => 'Did you pay this fare?';

  @override
  String tripCompletePayHint(String driver) {
    return 'Pay $driver in the app, or tell us you paid cash.';
  }

  @override
  String get meetVehicleNaMeShow => 'Hold it up so your driver can spot you';

  @override
  String get reportIncidentSubtitle =>
      'Tell us what happened. Our safety team reads every report.';

  @override
  String get shareTripRevoke => 'Stop sharing';

  @override
  String tripsRowDetail(String first, String second) {
    return '$first · $second';
  }

  @override
  String get tripDriverFallback => 'Your driver';

  @override
  String get tripsLoadFailed => 'Couldn\'t load your trips. Pull to try again.';

  @override
  String get tripHoldForSos => 'Hold for SOS';

  @override
  String get tripNaMe => 'Na Me';

  @override
  String get tripCall112 => 'Call 112';

  @override
  String get tripSignalSent => 'Sent';

  @override
  String get fareTierVerified => 'Standard fare';

  @override
  String get fareTierCrowd => 'Community fare';

  @override
  String get fareTierCandidate => 'Unconfirmed';

  @override
  String get fareTierEstimate => 'Estimate, agree price';

  @override
  String get receiptExtension => 'Trip extension';

  @override
  String receiptIncludesFee(String amount) {
    return 'Includes $amount Along fee';
  }

  @override
  String get receiptShareHeader => 'Along trip receipt';

  @override
  String get tripStatusCompleted => 'Completed';

  @override
  String get extendTripNowFare => 'Current fare';

  @override
  String get extendTripNewTotal => 'New total';

  @override
  String get extendTripDriverConfirms =>
      'Your driver confirms before anything changes';

  @override
  String get scanToPayHint => 'Point your camera at the driver\'s Along code';

  @override
  String get scanTorch => 'Torch';

  @override
  String get payMethodsSubtitle => 'Choose how you pay drivers';

  @override
  String get payMethodsSectionDefault => 'Pay drivers with';

  @override
  String get payMethodsTransferHint => 'Pay from your bank app, no card needed';

  @override
  String get payMethodsCards => 'Saved cards';

  @override
  String get payMethodsCardsEmpty => 'No saved cards yet';

  @override
  String get payMethodsSecure =>
      'We keep only the card brand and last 4 digits';

  @override
  String wayfindingTo(String place) {
    return 'To $place';
  }

  @override
  String wayfindingSummary(String distance, int minutes) {
    return '$distance · $minutes min walk';
  }

  @override
  String get wayfindingAudioPlaying => 'Audio playing';

  @override
  String get wayfindingNowPlaying => 'Now playing';

  @override
  String get wayfindingYouAreHere => 'You are here';

  @override
  String wayfindingStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get wayfindingIveArrived => 'I\'ve arrived';

  @override
  String get scanFitHint => 'Fit the code inside the corners';

  @override
  String get scanFound => 'Code found';

  @override
  String get requestingNextTitle => 'What happens next';

  @override
  String get requestingStepSent => 'Request sent to drivers nearby';

  @override
  String get requestingStepAccept => 'A driver accepts and you see their plate';

  @override
  String requestingStepMeet(String place) {
    return 'Meet them at $place';
  }

  @override
  String get tripGlanceTitle => 'Your trip';

  @override
  String tripGlanceWalk(String place) {
    return 'Walk to $place';
  }

  @override
  String get tripGlanceWait => 'Wait for your ride';

  @override
  String tripGlanceRide(String place) {
    return 'Ride to $place';
  }

  @override
  String tripGlanceMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get tripsSummaryTitle => 'Recent trips';

  @override
  String tripsSummaryCount(int count) {
    return '$count trips';
  }

  @override
  String tripsSummarySpent(String amount) {
    return '$amount paid';
  }

  @override
  String get tripsEmptyHint =>
      'Trips you take with Along show up here, with receipts.';

  @override
  String get tripsEmptyCta => 'Plan a trip';

  @override
  String get scanCodeWhereTitle => 'Where to find it';

  @override
  String get scanCodeWhereBody =>
      'The 8-character code is printed under the QR on the driver\'s sticker, or ask them to open My QR.';

  @override
  String get connOffline => 'Offline · you can keep going';

  @override
  String connOfflineQueued(int count) {
    return 'Offline · $count saved to send';
  }

  @override
  String get connReconnecting => 'Reconnecting';

  @override
  String connSending(int count) {
    return 'Reconnecting · sending $count';
  }

  @override
  String get connRestored => 'Back online';

  @override
  String connRestoredSent(int count) {
    return 'Back online · $count sent';
  }

  @override
  String get connRetry => 'Retry';

  @override
  String get searchPausedTitle => 'Search paused';

  @override
  String get searchPausedBody =>
      'The network dropped. Saved places and the map still work.';

  @override
  String get searchEmptyTitle => 'No places found';

  @override
  String get searchEmptyBody => 'Try a nearby landmark, market or bus stop.';

  @override
  String get searchEmptyOfflineBody =>
      'You\'re offline, so only saved places show. Drop a pin instead.';

  @override
  String connNeedsConnection(int count) {
    return 'Offline · $count to redo online';
  }

  @override
  String connOfflineMixed(int queued, int needs) {
    return 'Offline · $queued to send · $needs to redo';
  }

  @override
  String get walletTitle => 'Wallet';

  @override
  String get walletSubtitle => 'Along credit';

  @override
  String get walletBalance => 'Balance';

  @override
  String get walletBalanceNote => 'It stays in Along';

  @override
  String get walletAddCredit => 'Add credit';

  @override
  String get walletCustom => 'Custom';

  @override
  String get walletHistory => 'History';

  @override
  String get walletHistoryEmpty =>
      'No credit yet. Top ups, fares and refunds show here.';

  @override
  String get walletAddCustom => 'Add a custom amount';

  @override
  String walletAdd(String amount) {
    return 'Add $amount';
  }

  @override
  String get walletTopUp => 'Top up';

  @override
  String get walletFare => 'Fare';

  @override
  String get walletRefund => 'Refund';

  @override
  String get walletToday => 'Today';

  @override
  String get walletYesterday => 'Yesterday';

  @override
  String get walletUnavailable => 'Wallet didn\'t load';

  @override
  String get walletUnavailableBody =>
      'Your credit is safe. Check your connection and try again.';

  @override
  String get walletRetry => 'Try again';

  @override
  String get walletCustomTitle => 'How much?';

  @override
  String get walletCustomHint => '₦100 to ₦50,000';

  @override
  String get walletCustomTooSmall => 'At least ₦100';

  @override
  String get walletCustomTooLarge => 'At most ₦50,000';

  @override
  String get walletCancel => 'Cancel';

  @override
  String walletAdded(String amount) {
    return '$amount added';
  }

  @override
  String get walletTopUpFailed => 'Nothing was added. Try again.';

  @override
  String get walletActionTopUp => 'Top up';

  @override
  String get walletActionSend => 'Send';

  @override
  String get walletActionPass => 'Pass';

  @override
  String get walletActionSplit => 'Split';

  @override
  String get walletActivity => 'Activity';

  @override
  String get walletEarlier => 'Earlier';

  @override
  String get walletActivityEmpty =>
      'No activity yet. Top up to ride without cash.';

  @override
  String walletBalanceSemantics(String amount) {
    return 'Balance $amount';
  }

  @override
  String walletSentTo(String name) {
    return 'To $name';
  }

  @override
  String walletReceivedFrom(String name) {
    return 'From $name';
  }

  @override
  String get walletSent => 'Sent';

  @override
  String get walletReceived => 'Received';

  @override
  String get walletPassEntry => 'Along Pass';

  @override
  String get walletSplitPaid => 'Split paid';

  @override
  String get walletSplitReceived => 'Split received';

  @override
  String walletOwedTitle(String name, String amount) {
    return '$name asked for $amount';
  }

  @override
  String get walletOwedBody => 'Your share of a shared ride';

  @override
  String get walletOwedPay => 'Pay';

  @override
  String get walletOwedDecline => 'Decline';

  @override
  String walletOwedPaidSnack(String amount) {
    return 'Paid $amount';
  }

  @override
  String get walletOwedDeclinedSnack => 'Request declined';

  @override
  String get walletInsufficient => 'Not enough credit. Top up first.';

  @override
  String get walletActionFailed =>
      'Couldn\'t finish. Try again — you won\'t be charged twice.';

  @override
  String get walletSendTitle => 'Send credit';

  @override
  String get walletSendSubtitle => 'To another Along rider';

  @override
  String get walletSendPhone => 'Phone number';

  @override
  String get walletSendPhoneHint => '0803 123 4567';

  @override
  String get walletSendPhoneInvalid => 'Enter a Nigerian mobile number';

  @override
  String get walletSendAmount => 'Amount';

  @override
  String get walletSendTooSmall => 'Send at least ₦50';

  @override
  String get walletSendTooLarge => 'Send at most ₦50,000';

  @override
  String get walletSendOverBalance => 'More than your balance';

  @override
  String walletSendCta(String amount) {
    return 'Send $amount';
  }

  @override
  String get walletSendCtaEmpty => 'Send';

  @override
  String get walletSendNotFound => 'No Along rider has that number';

  @override
  String walletSentSnack(String amount) {
    return 'Sent $amount';
  }

  @override
  String walletAvailable(String amount) {
    return 'Available $amount';
  }

  @override
  String get walletPassTitle => 'Along Pass';

  @override
  String get walletPassSubtitle => 'Rides paid ahead from your credit';

  @override
  String walletPassPrice(String amount) {
    return '$amount a month';
  }

  @override
  String get walletPassBody =>
      'One payment from your wallet. No card, no cash at the door.';

  @override
  String walletPassCta(String amount) {
    return 'Buy pass · $amount';
  }

  @override
  String get walletPassBought => 'Pass active · Done';

  @override
  String walletPassShort(String amount) {
    return 'Top up $amount more to buy';
  }

  @override
  String get walletSplitTitle => 'Split a fare';

  @override
  String get walletSplitSubtitle => 'Ask co-riders for their share';

  @override
  String get walletSplitFare => 'Fare';

  @override
  String get walletSplitYou => 'You';

  @override
  String walletSplitCoRider(int n) {
    return 'Rider $n';
  }

  @override
  String get walletSplitAdd => 'Add co-rider';

  @override
  String get walletSplitRemove => 'Remove';

  @override
  String walletSplitEach(String amount) {
    return '$amount each';
  }

  @override
  String walletSplitCta(String amount) {
    return 'Request $amount each';
  }

  @override
  String get walletSplitCtaEmpty => 'Request share';

  @override
  String get walletSplitFareInvalid => 'Enter the fare, at least ₦100';

  @override
  String walletSplitSentSnack(int count) {
    return 'Asked $count co-riders';
  }

  @override
  String get walletSplitNotFound => 'One of those numbers isn\'t on Along yet';

  @override
  String get walletSplitNote =>
      'They pay from their wallet. You keep paying the driver as usual.';

  @override
  String get accountWallet => 'Wallet';

  @override
  String get accountWalletHint => 'Top up, send, pass, split fares';

  @override
  String get walletPassPlanWeek => 'Week';

  @override
  String get walletPassPlanPack => '5 rides';

  @override
  String get walletPassPlanMonth => 'Month';

  @override
  String walletPassRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides',
      one: '1 ride',
    );
    return '$_temp0';
  }

  @override
  String walletPassValidity(int days) {
    return 'Good for $days days';
  }

  @override
  String walletPassPerRide(String amount) {
    return '$amount a ride';
  }

  @override
  String get walletPassVersus => 'Versus single fares';

  @override
  String walletPassSingleRow(int count, String fare) {
    return '$count × $fare single';
  }

  @override
  String get walletPassPassRow => 'Pass';

  @override
  String walletPassSave(String amount) {
    return 'You save $amount';
  }

  @override
  String get walletPassNoSave => 'No saving at your usual fare';

  @override
  String get walletPassNoHistory =>
      'Savings show after your first fare paid from the wallet';

  @override
  String walletPassUsualFare(String amount) {
    return 'Your usual fare is $amount';
  }

  @override
  String walletPassActive(String date) {
    return 'Active until $date';
  }

  @override
  String walletSplitNotFoundNumber(String phone) {
    return '$phone isn\'t on Along yet';
  }

  @override
  String get walletSplitNotOnAlong => 'Not on Along yet';

  @override
  String get walletSplitRequests => 'Your requests';

  @override
  String get walletSplitPending => 'Waiting';

  @override
  String get walletSplitPaidStatus => 'Paid';

  @override
  String get walletSplitDeclined => 'Declined';

  @override
  String get walletPassSaveLabel => 'You save';

  @override
  String get walletPassHow => 'How it works';

  @override
  String get walletPassStep1 => 'Pick a plan above';

  @override
  String get walletPassStep2 =>
      'Pay once from your Along credit. No card needed';

  @override
  String walletPassStep3(int days) {
    return 'It stays active for $days days from today';
  }

  @override
  String get walletPassDetails => 'Details';

  @override
  String get walletPassRowRides => 'Rides';

  @override
  String get walletPassRowValid => 'Valid until';

  @override
  String get walletPassRowPaid => 'Paid with';

  @override
  String get walletPassRowPaidValue => 'Along credit';

  @override
  String get sosTitle => 'Safety';

  @override
  String get sosStatusSending => 'Alerting the Along safety team…';

  @override
  String sosStatusSent(String time) {
    return 'Safety team alerted · $time';
  }

  @override
  String get sosStatusQueued =>
      'No signal · alert saved, sends when you\'re back';

  @override
  String get sosStatusFailed => 'Alert not sent · call 112 now';

  @override
  String get sosHoldHint => 'Hold to call';

  @override
  String get sosMapLive => 'Live';

  @override
  String get sosContactsTitle => 'Contacts';

  @override
  String get sosNoContacts => 'No trusted contacts yet';

  @override
  String get sosAddContact => 'Add';

  @override
  String get sosShareLive => 'Share live trip';

  @override
  String get sosImSafe => 'I\'m safe';

  @override
  String get sosImSafeTitle => 'Cancel the alert?';

  @override
  String get sosImSafeBody =>
      'The safety team stops following this trip. Only cancel if you are safe.';

  @override
  String get sosImSafeConfirm => 'Yes, I\'m safe';

  @override
  String get sosKeepAlert => 'Keep alert on';

  @override
  String sosReach(String name) {
    return 'Reach $name';
  }

  @override
  String get guardianShareSubtitle => 'Let someone you trust follow this trip';

  @override
  String guardianShareWatching(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people can see this trip',
      one: '1 person can see this trip',
    );
    return '$_temp0';
  }

  @override
  String get guardianShareWho => 'Who can follow';

  @override
  String get guardianShareNoContacts =>
      'Add a trusted contact to share in one tap';

  @override
  String get guardianShareAddContact => 'Add contact';

  @override
  String get guardianSharePlate => 'Share the plate';

  @override
  String get guardianShareLocation => 'Share live location';

  @override
  String get guardianShareExpiry => 'Stop after';

  @override
  String get guardianShare30 => '30 min';

  @override
  String get guardianShare60 => '1 hour';

  @override
  String get guardianShareTripEnd => 'Trip ends';

  @override
  String guardianShareCta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Share with $count people',
      one: 'Share with 1 person',
      zero: 'Create a share link',
    );
    return '$_temp0';
  }

  @override
  String get guardianShareStop => 'Stop sharing';

  @override
  String guardianShareUntil(String time) {
    return 'Until $time';
  }

  @override
  String get guardianShareWhatsapp => 'WhatsApp';

  @override
  String get guardianShareOffline =>
      'Sharing needs a connection. SOS still works offline.';

  @override
  String get guardianShareFailed => 'Couldn\'t start sharing. Try again.';

  @override
  String get guardianShareStopped => 'Sharing stopped';

  @override
  String get guardianShareNoTrip => 'Sharing starts once you\'re on a trip';

  @override
  String get reportIncidentPhotosHeading => 'Photos';

  @override
  String get reportIncidentPhotosNote =>
      'Up to 4 · only our safety team sees them';

  @override
  String get reportIncidentAddPhoto => 'Add photo';

  @override
  String get reportIncidentTakePhoto => 'Take photo';

  @override
  String get reportIncidentChoosePhoto => 'Choose from gallery';

  @override
  String reportIncidentRemovePhoto(int n) {
    return 'Remove photo $n';
  }

  @override
  String reportIncidentUploading(int done, int total) {
    return 'Sending photo $done of $total';
  }

  @override
  String get reportIncidentSent =>
      'Report sent. Our safety team will follow up.';

  @override
  String get reportIncidentQueued =>
      'No signal. Report saved, it sends when you\'re back.';

  @override
  String get reportIncidentFailed => 'Couldn\'t send the report. Try again.';

  @override
  String get reportIncidentPhotoError => 'Couldn\'t add that photo';

  @override
  String optionCardRouteLine(String board, String alight) {
    return 'Board at $board → $alight';
  }

  @override
  String get authYourNumber => 'Your number';

  @override
  String get authSendCode => 'Text me the code';

  @override
  String get otpCheckTitle => 'Check your texts';

  @override
  String get otpChecking => 'Checking the code…';

  @override
  String get otpAutofillHint =>
      'The code fills in by itself when the text arrives.';

  @override
  String get authOffline => 'You are offline. Connect to get your code.';

  @override
  String get authBack => 'Back';

  @override
  String get permSubtitle =>
      'Along asks once. You can change this any time in Settings.';

  @override
  String get permLocationTitle => 'Location';

  @override
  String get permNotifTitle => 'Notifications';

  @override
  String get permCameraTitle => 'Camera';

  @override
  String get permAllow => 'Allow access';

  @override
  String get permLater => 'Not now';

  @override
  String get authStory1H => 'Move around. Your way.';

  @override
  String get authStory1B => 'Keke, okada, danfo and taxi in one app.';

  @override
  String get authStory2H => 'A fair fare, every time.';

  @override
  String get authStory2B => 'See the price before you go. No haggling.';

  @override
  String get authStory3H => 'Someone always knows.';

  @override
  String get authStory3B =>
      'Share your trip and hold for SOS if you need help.';

  @override
  String get nameSubtitle =>
      'Drivers see your first name only. You can skip this.';

  @override
  String get permTitle => 'Ready for your first ride';

  @override
  String get permLocationBody =>
      'Find your pickup and show the driver where you are.';

  @override
  String get permNotifBody => 'Know the moment your driver arrives.';

  @override
  String get permCameraBody =>
      'Scan to pay and check the plate before you board.';
}
