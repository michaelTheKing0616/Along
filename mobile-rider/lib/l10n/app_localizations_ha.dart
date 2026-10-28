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
  String get modeKeke => 'kekes';

  @override
  String get searchTitle => 'Ina za ka?';

  @override
  String get searchRecentsTitle => 'Recents';

  @override
  String get searchResultsTitle => 'Results';

  @override
  String get searchOfflineHint => 'Offline · searching saved places';

  @override
  String get cachedOptionsStaleBadge => 'Cached · may be outdated';

  @override
  String get adjustPickupTitle => 'Gyara wurin ɗauka';

  @override
  String adjustPickupBoardingAt(String stageName) {
    return 'Hawa a: $stageName';
  }

  @override
  String get adjustPickupConfirm => 'Tabbatar da wuri';

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
  String get hailSearchTitle => 'Ina za ka?';

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
    return 'Saura daƙiƙa $seconds';
  }

  @override
  String get requestingFindingAnother => 'Muna neman wata mota…';

  @override
  String get requestingCancel => 'Soke';

  @override
  String get requestingExpired =>
      'Babu direban da ya amsa — duba wasu zaɓuɓɓuka';

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
  String get wayfindingTitle => 'Kwatance tafiya da ƙafa';

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
  String get wayfindingNoSteps => 'Babu matakai';

  @override
  String meetVehicleArrivingIn(int minutes) {
    return 'Zai iso cikin ~minti $minutes';
  }

  @override
  String meetVehicleWalkTo(int minutes, String park) {
    return 'Yi tafiyar minti $minutes zuwa $park';
  }

  @override
  String get meetVehicleDriverSignalLost => 'Siginar direba ta ɓace';

  @override
  String get meetVehicleLivePaused => 'An dakatar da sabuntawa kai tsaye';

  @override
  String get meetVehicleShare => 'Raba tafiya';

  @override
  String get meetVehicleCancel => 'Soke';

  @override
  String get meetVehicleBoarded => 'Na shiga';

  @override
  String get activeTripExtend => 'Ƙara nisa';

  @override
  String get activeTripShare => 'Raba';

  @override
  String get activeTripReport => 'Kai rahoto';

  @override
  String get tripCompleteTitle => 'An kammala tafiya';

  @override
  String get tripCompletePaidCash => 'Na biya da kuɗin hannu';

  @override
  String get tripCompleteTier3Question => 'Nawa ka biya?';

  @override
  String get tripCompleteYes => 'Eh';

  @override
  String get tripCompleteDifferent => 'Wani adadi daban';

  @override
  String get tripCompleteDifferentPrompt => 'Zaɓi adadin da ka biya';

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
    return 'Biya $amount';
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
  String get activeTripScan => 'Duba';

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
    return '$count babu kowa';
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
  String get seatDriver => 'direba';

  @override
  String get seatLuggage => 'luggage';

  @override
  String get voiceBookingHint => 'Faɗe shi, misali Wuse zuwa Berger';

  @override
  String get textMapTitle => 'Vehicles nearby';

  @override
  String get textMapEmpty => 'No vehicles in this direction yet';

  @override
  String get plateCheck => 'Na ga wannan lamba';

  @override
  String get plateMatches => 'Lambar ta dace';

  @override
  String get plateScan => 'Duba lamba';

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
  String get guardianTitle => 'Mai tsaro';

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
  String get guardianOk => 'Ina lafiya';

  @override
  String get guardianOffRouteBody =>
      'Ka yi nisa da motar fiye da yadda ka saita.';

  @override
  String get guardianLongStopBody => 'Motar ta tsaya fiye da yadda ka saita.';

  @override
  String get guardianCheckInBody => 'Lokacin dubawa da ka saita ya yi.';

  @override
  String get guardianMissedBody => 'Har yanzu dubawar a buɗe take.';

  @override
  String get guardianSafeWordHint => 'Faɗi kalmarka';

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
    return 'Aika wa $name saƙo';
  }

  @override
  String get homeGreetingMorning => 'Ina kwana';

  @override
  String get homeGreetingAfternoon => 'Barka da rana';

  @override
  String get homeGreetingEvening => 'Barka da yamma';

  @override
  String get homeGreetingNight => 'Sai da safe';

  @override
  String homeNearbyEta(int minutes) {
    return '~minti $minutes';
  }

  @override
  String get tripOptionsRecommended => 'Shawarar mu';

  @override
  String tripOptionsRequest(String fare) {
    return 'Nemi $fare';
  }

  @override
  String get searchChooseOnMapDetail => 'Saka alama';

  @override
  String get searchEmpty => 'Rubuta tasha, kasuwa ko titi';

  @override
  String get tripSortCheapest => 'Mafi arha';

  @override
  String get tripSortFastest => 'Mafi sauri';

  @override
  String get tripSortEasiest => 'Ƙarancin tafiya';

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
    return '$area · nisan $distance';
  }

  @override
  String tripOptionsSummary(int minutes, String distance) {
    return 'minti $minutes · $distance';
  }

  @override
  String tripMetaWalk(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'tafiya minti $minutes',
    );
    return '$_temp0';
  }

  @override
  String tripMetaWait(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '~jira minti $minutes',
    );
    return '$_temp0';
  }

  @override
  String get tripMetaDirect => 'kai tsaye';

  @override
  String tripMetaTransferAt(String park) {
    return 'canji 1 a $park';
  }

  @override
  String tripMetaTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'canji $count',
    );
    return '$_temp0';
  }

  @override
  String get searchShortcutHome => 'Gida';

  @override
  String get searchShortcutWork => 'Aiki';

  @override
  String get searchShortcutAdd => 'Ƙara';

  @override
  String get searchShortcutPinDetail => 'A taswira';

  @override
  String placeAway(String distance) {
    return '$distance daga nan';
  }

  @override
  String get homePlanYourDayDetail => 'Haɗa tashoshinka a tafiya ɗaya';

  @override
  String searchPopularTitle(String city) {
    return 'Shahararru a $city';
  }

  @override
  String get tripEtaWorkingOut => 'Muna lissafin lokacin isowarka';

  @override
  String tripEtaLastTo(String place) {
    return 'Kiyasin karshe zuwa $place';
  }

  @override
  String tripEtaArrivingAt(String place) {
    return 'Za ka isa $place';
  }

  @override
  String get tripEtaPaused => 'An dakatar da lokutan kai tsaye';

  @override
  String get tripRetry => 'Sake gwadawa';

  @override
  String tripEtaTraffic(int minutes) {
    return 'Akwai cunkoso a gaba. Kusan minti $minutes a makara.';
  }

  @override
  String get tripMinUnit => 'minti';

  @override
  String tripAboutClock(String time) {
    return 'Kusan $time';
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
      other: 'minti $minutes',
      one: 'minti 1',
    );
    return '$_temp0';
  }

  @override
  String tripMinutesRangeLabel(int low, int high) {
    return 'Minti $low zuwa $high';
  }

  @override
  String get tripEmergency => 'Gaggawa';

  @override
  String get tripSos => 'SOS';

  @override
  String get tripCall => 'Kira';

  @override
  String tripCallName(String name) {
    return 'Kira $name';
  }

  @override
  String get tripMessage => 'Saƙo';

  @override
  String tripArrivesIn(String name) {
    return '$name zai iso cikin';
  }

  @override
  String tripIsHere(String name) {
    return '$name ya iso';
  }

  @override
  String get tripDriverHere => 'Direba ya iso';

  @override
  String get tripMeetAtPickup => 'Haɗu a wurin ɗauka';

  @override
  String tripCountdownLabel(int minutes, int seconds) {
    return 'Minti $minutes da daƙiƙa $seconds';
  }

  @override
  String get tripPinTitle => 'PIN ɗin tafiya';

  @override
  String get tripPinSay => 'Faɗe shi a ƙofa';

  @override
  String get tripPinNew => 'Sami sabon PIN';

  @override
  String get tripPinTooSoon =>
      'Yanzu ka sami sabon PIN. Sake gwadawa nan da ɗan lokaci.';

  @override
  String get tripPinFailed => 'Ba a sami sabon PIN ba. Sake gwadawa.';

  @override
  String get tripMatchedTitle => 'An haɗa ku';

  @override
  String tripMatchedBody(String name) {
    return 'Shiga. $name zai fara tafiyar.';
  }

  @override
  String get receiptTitle => 'Rasiti';

  @override
  String get receiptNotReady => 'Rasiti bai shirya ba';

  @override
  String get receiptNotReadyBody =>
      'Har yanzu yana zuwa. Zai kuma kasance a cikin Tafiye-tafiye.';

  @override
  String get receiptTryAgain => 'Sake gwadawa';

  @override
  String get receiptDone => 'An gama';

  @override
  String receiptHowWas(String name) {
    return 'Yaya $name ya kasance?';
  }

  @override
  String get receiptFare => 'Kuɗin mota';

  @override
  String get receiptTotal => 'Jimilla';

  @override
  String get receiptCashPaid => 'Kuɗin hannu da aka biya';

  @override
  String get receiptChangeToWallet => 'Saka canji a walat';

  @override
  String receiptWalletNow(String amount) {
    return 'Walat yanzu $amount';
  }

  @override
  String get receiptLoadSurcharge => 'Ƙarin kuɗin kaya';

  @override
  String get receiptAlongFee => 'Kuɗin Along';

  @override
  String get receiptYourTrip => 'Tafiyarka';

  @override
  String receiptRoute(String from, String to) {
    return '$from zuwa $to';
  }

  @override
  String receiptToday(String time) {
    return 'Yau, $time';
  }

  @override
  String get receiptYourDriver => 'diretanka';

  @override
  String get ratingTagSafeDriving => 'Tuƙi lafiya';

  @override
  String get ratingTagFairFare => 'Kuɗi mai adalci';

  @override
  String get ratingTagCleanVehicle => 'Mota mai tsabta';

  @override
  String get ratingTagPolite => 'Mai ladabi';

  @override
  String get ratingTagOnTime => 'A kan lokaci';

  @override
  String meetVehicleArrivingAt(String time) {
    return 'Yana zuwa · $time';
  }

  @override
  String get meetVehicleCalculating => 'Muna lissafin lokacin isowa';

  @override
  String meetVehicleDriverStats(String rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tafiye-tafiye $count',
      one: 'tafiya 1',
    );
    return '★ $rating · $_temp0';
  }

  @override
  String meetVehicleMeetAt(String place) {
    return 'Haɗu a $place';
  }

  @override
  String requestingFinding(String mode) {
    return 'Muna neman $mode ɗinka';
  }

  @override
  String requestingSeenNear(String place) {
    return 'Direbobin kusa da $place suna ganin buƙatarka';
  }

  @override
  String get requestingFare => 'Kuɗin mota';

  @override
  String get adjustPickupPinLabel => 'Alamar da ka sanya';

  @override
  String get adjustPickupHint =>
      'Taɓa taswira ko tasha a ƙasa don matsar da alamar';

  @override
  String get adjustPickupNearby => 'Tashoshi na kusa';

  @override
  String get tripCompleteFareLabel => 'Kuɗin mota';

  @override
  String tripCompleteRoute(String from, String to) {
    return '$from → $to';
  }

  @override
  String get tripEtaCalculating => 'Ana lissafi…';

  @override
  String get activeTripCall => 'Kira';

  @override
  String get activeTripSos => 'Riƙe don SOS';

  @override
  String get activeTripNaMe => 'Nuna Na Me';

  @override
  String get tripCompleteSettleQuestion => 'Ka biya wannan kuɗin?';

  @override
  String tripCompletePayHint(String driver) {
    return 'Biya $driver a manhaja, ko ka faɗa mana ka biya da tsabar kuɗi.';
  }

  @override
  String get meetVehicleNaMeShow => 'Ɗaga shi don direbanka ya gane ka';

  @override
  String get reportIncidentSubtitle =>
      'Faɗa mana abin da ya faru. Ƙungiyar tsaro tana karanta kowane rahoto.';

  @override
  String get shareTripRevoke => 'Daina rabawa';

  @override
  String tripsRowDetail(String first, String second) {
    return '$first · $second';
  }

  @override
  String get tripDriverFallback => 'Direbanka';

  @override
  String get tripsLoadFailed =>
      'Ba mu iya loda tafiye-tafiyenka ba. Sake gwadawa.';

  @override
  String get tripHoldForSos => 'Riƙe don SOS';

  @override
  String get tripNaMe => 'Ni Ne';

  @override
  String get tripCall112 => 'Kira 112';

  @override
  String get tripSignalSent => 'An aika';

  @override
  String get fareTierVerified => 'Kuɗin da aka saba';

  @override
  String get fareTierCrowd => 'Kuɗin jama\'a';

  @override
  String get fareTierCandidate => 'Ba a tabbatar ba';

  @override
  String get fareTierEstimate => 'Ƙiyasi, ku daidaita';

  @override
  String get receiptExtension => 'Ƙarin tafiya';

  @override
  String receiptIncludesFee(String amount) {
    return 'Ya haɗa da kuɗin Along $amount';
  }

  @override
  String get receiptShareHeader => 'Rasidin tafiyar Along';

  @override
  String get tripStatusCompleted => 'An gama';

  @override
  String get extendTripNowFare => 'Kuɗin yanzu';

  @override
  String get extendTripNewTotal => 'Sabon jimilla';

  @override
  String get extendTripDriverConfirms =>
      'Direbanka zai tabbatar kafin wani abu ya canza';

  @override
  String get scanToPayHint => 'Nuna kyamararka ga lambar Along ta direba';

  @override
  String get scanTorch => 'Fitila';

  @override
  String get payMethodsSubtitle => 'Zaɓi yadda kake biyan direbobi';

  @override
  String get payMethodsSectionDefault => 'Biya direbobi da';

  @override
  String get payMethodsTransferHint =>
      'Biya daga manhajar bankinka, babu buƙatar kati';

  @override
  String get payMethodsCards => 'Katunan da aka adana';

  @override
  String get payMethodsCardsEmpty => 'Babu katin da aka adana tukuna';

  @override
  String get payMethodsSecure =>
      'Muna adana sunan kati da lambobi 4 na ƙarshe kawai';

  @override
  String wayfindingTo(String place) {
    return 'Zuwa $place';
  }

  @override
  String wayfindingSummary(String distance, int minutes) {
    return '$distance · tafiyar minti $minutes';
  }

  @override
  String get wayfindingAudioPlaying => 'Ana kunna sauti';

  @override
  String get wayfindingNowPlaying => 'Ana kunnawa yanzu';

  @override
  String get wayfindingYouAreHere => 'Kana nan';

  @override
  String wayfindingStepOf(int step, int total) {
    return 'Mataki $step cikin $total';
  }

  @override
  String get wayfindingIveArrived => 'Na iso';

  @override
  String get scanFitHint => 'Sa lambar a cikin kusurwoyin';

  @override
  String get scanFound => 'An sami lambar';

  @override
  String get requestingNextTitle => 'Abin da zai biyo baya';

  @override
  String get requestingStepSent => 'An aika buƙata ga direbobi na kusa';

  @override
  String get requestingStepAccept => 'Direba ya karɓa, za ka ga lambar motarsa';

  @override
  String requestingStepMeet(String place) {
    return 'Ku haɗu a $place';
  }

  @override
  String get tripGlanceTitle => 'Tafiyarka';

  @override
  String tripGlanceWalk(String place) {
    return 'Tafi da ƙafa zuwa $place';
  }

  @override
  String get tripGlanceWait => 'Jira abin hawanka';

  @override
  String tripGlanceRide(String place) {
    return 'Hau zuwa $place';
  }

  @override
  String tripGlanceMinutes(int minutes) {
    return 'minti $minutes';
  }

  @override
  String get tripsSummaryTitle => 'Tafiye-tafiye na kwanan nan';

  @override
  String tripsSummaryCount(int count) {
    return 'Tafiya $count';
  }

  @override
  String tripsSummarySpent(String amount) {
    return 'An biya $amount';
  }

  @override
  String get tripsEmptyHint =>
      'Tafiye-tafiyen da ka yi da Along za su bayyana a nan, tare da rasit.';

  @override
  String get tripsEmptyCta => 'Shirya tafiya';

  @override
  String get scanCodeWhereTitle => 'Inda za ka same shi';

  @override
  String get scanCodeWhereBody =>
      'An buga lambar haruffa 8 a ƙarƙashin QR a kan sitikar direba, ko ka ce ya buɗe My QR.';

  @override
  String get connOffline => 'Babu intanet · za ka iya ci gaba';

  @override
  String connOfflineQueued(int count) {
    return 'Babu intanet · $count an ajiye don aikawa';
  }

  @override
  String get connReconnecting => 'Ana sake haɗawa';

  @override
  String connSending(int count) {
    return 'Ana sake haɗawa · ana aika $count';
  }

  @override
  String get connRestored => 'An dawo kan layi';

  @override
  String connRestoredSent(int count) {
    return 'An dawo kan layi · an aika $count';
  }

  @override
  String get connRetry => 'Sake gwadawa';

  @override
  String get searchPausedTitle => 'An dakatar da bincike';

  @override
  String get searchPausedBody =>
      'Intanet ta katse. Wuraren da aka ajiye da taswira suna aiki.';

  @override
  String get searchEmptyTitle => 'Ba a sami wurare ba';

  @override
  String get searchEmptyBody =>
      'Gwada wani sanannen wuri, kasuwa ko tashar mota kusa.';

  @override
  String get searchEmptyOfflineBody =>
      'Ba ka kan layi, wuraren da aka ajiye kawai ke nunawa. Sa alama a taswira.';

  @override
  String connNeedsConnection(int count) {
    return 'Babu intanet · $count a sake yi da intanet';
  }

  @override
  String connOfflineMixed(int queued, int needs) {
    return 'Babu intanet · $queued za a aika · $needs a sake';
  }

  @override
  String get walletTitle => 'Walat';

  @override
  String get walletSubtitle => 'Kuɗin Along';

  @override
  String get walletBalance => 'Ragowar kuɗi';

  @override
  String get walletBalanceNote => 'Yana zama a Along';

  @override
  String get walletAddCredit => 'Ƙara kuɗi';

  @override
  String get walletCustom => 'Naka';

  @override
  String get walletHistory => 'Tarihi';

  @override
  String get walletHistoryEmpty =>
      'Babu kuɗi tukuna. Ƙari, kuɗin hawa da maidowa za su bayyana a nan.';

  @override
  String get walletAddCustom => 'Ƙara adadin da kake so';

  @override
  String walletAdd(String amount) {
    return 'Ƙara $amount';
  }

  @override
  String get walletTopUp => 'Ƙari';

  @override
  String get walletFare => 'Kuɗin hawa';

  @override
  String get walletRefund => 'Maidowa';

  @override
  String get walletToday => 'Yau';

  @override
  String get walletYesterday => 'Jiya';

  @override
  String get walletUnavailable => 'Walat bai buɗe ba';

  @override
  String get walletUnavailableBody =>
      'Kuɗinka yana nan lafiya. Duba intanet ka sake gwadawa.';

  @override
  String get walletRetry => 'Sake gwadawa';

  @override
  String get walletCustomTitle => 'Nawa?';

  @override
  String get walletCustomHint => '₦100 zuwa ₦50,000';

  @override
  String get walletCustomTooSmall => 'Aƙalla ₦100';

  @override
  String get walletCustomTooLarge => 'Mafi yawa ₦50,000';

  @override
  String get walletCancel => 'Soke';

  @override
  String walletAdded(String amount) {
    return 'An ƙara $amount';
  }

  @override
  String get walletTopUpFailed => 'Ba a ƙara komai ba. Sake gwadawa.';

  @override
  String get walletActionTopUp => 'Ƙara kuɗi';

  @override
  String get walletActionSend => 'Aika';

  @override
  String get walletActionPass => 'Fasi';

  @override
  String get walletActionSplit => 'Raba';

  @override
  String get walletActivity => 'Ayyuka';

  @override
  String get walletEarlier => 'A baya';

  @override
  String get walletActivityEmpty =>
      'Babu aiki tukuna. Ƙara kuɗi don hawa ba tare da tsabar kuɗi ba.';

  @override
  String walletBalanceSemantics(String amount) {
    return 'Ma\'auni $amount';
  }

  @override
  String walletSentTo(String name) {
    return 'Zuwa ga $name';
  }

  @override
  String walletReceivedFrom(String name) {
    return 'Daga $name';
  }

  @override
  String get walletSent => 'An aika';

  @override
  String get walletReceived => 'An karɓa';

  @override
  String get walletPassEntry => 'Fasin Along';

  @override
  String get walletSplitPaid => 'An biya rabo';

  @override
  String get walletSplitReceived => 'An karɓi rabo';

  @override
  String walletOwedTitle(String name, String amount) {
    return '$name ya nemi $amount';
  }

  @override
  String get walletOwedBody => 'Rabonka na hawan haɗin gwiwa';

  @override
  String get walletOwedPay => 'Biya';

  @override
  String get walletOwedDecline => 'Ƙi';

  @override
  String walletOwedPaidSnack(String amount) {
    return 'An biya $amount';
  }

  @override
  String get walletOwedDeclinedSnack => 'An ƙi buƙata';

  @override
  String get walletInsufficient => 'Babu isasshen kuɗi. Ƙara kuɗi tukuna.';

  @override
  String get walletActionFailed =>
      'Ba a gama ba. Sake gwadawa — ba za a caje ka sau biyu ba.';

  @override
  String get walletSendTitle => 'Aika kuɗi';

  @override
  String get walletSendSubtitle => 'Ga wani mai hawan Along';

  @override
  String get walletSendPhone => 'Lambar waya';

  @override
  String get walletSendPhoneHint => '0803 123 4567';

  @override
  String get walletSendPhoneInvalid => 'Shigar da lambar waya ta Najeriya';

  @override
  String get walletSendAmount => 'Adadi';

  @override
  String get walletSendTooSmall => 'Aika aƙalla ₦50';

  @override
  String get walletSendTooLarge => 'Aika aƙalla bai wuce ₦50,000 ba';

  @override
  String get walletSendOverBalance => 'Ya fi ma\'aunin ka';

  @override
  String walletSendCta(String amount) {
    return 'Aika $amount';
  }

  @override
  String get walletSendCtaEmpty => 'Aika';

  @override
  String get walletSendNotFound => 'Babu mai hawan Along da wannan lamba';

  @override
  String walletSentSnack(String amount) {
    return 'An aika $amount';
  }

  @override
  String walletAvailable(String amount) {
    return 'Akwai $amount';
  }

  @override
  String get walletPassTitle => 'Fasin Along';

  @override
  String get walletPassSubtitle => 'Hawa da aka biya gaba daga kuɗinka';

  @override
  String walletPassPrice(String amount) {
    return '$amount a wata';
  }

  @override
  String get walletPassBody =>
      'Biya ɗaya daga walat ɗinka. Babu kati, babu tsabar kuɗi a ƙofa.';

  @override
  String walletPassCta(String amount) {
    return 'Saya fasi · $amount';
  }

  @override
  String get walletPassBought => 'Fasi yana aiki · An gama';

  @override
  String walletPassShort(String amount) {
    return 'Ƙara $amount don saya';
  }

  @override
  String get walletSplitTitle => 'Raba kuɗin hawa';

  @override
  String get walletSplitSubtitle => 'Nemi rabon abokan hawa';

  @override
  String get walletSplitFare => 'Kuɗin hawa';

  @override
  String get walletSplitYou => 'Kai';

  @override
  String walletSplitCoRider(int n) {
    return 'Abokin hawa $n';
  }

  @override
  String get walletSplitAdd => 'Ƙara abokin hawa';

  @override
  String get walletSplitRemove => 'Cire';

  @override
  String walletSplitEach(String amount) {
    return '$amount kowanne';
  }

  @override
  String walletSplitCta(String amount) {
    return 'Nemi $amount kowanne';
  }

  @override
  String get walletSplitCtaEmpty => 'Nemi rabo';

  @override
  String get walletSplitFareInvalid => 'Shigar da kuɗin hawa, aƙalla ₦100';

  @override
  String walletSplitSentSnack(int count) {
    return 'An nemi abokan hawa $count';
  }

  @override
  String get walletSplitNotFound => 'Ɗaya daga lambobin ba ya kan Along tukuna';

  @override
  String get walletSplitNote =>
      'Za su biya daga walat ɗinsu. Kai kuma ka ci gaba da biyan direba kamar yadda aka saba.';

  @override
  String get accountWallet => 'Walat';

  @override
  String get accountWalletHint => 'Ƙara kuɗi, aika, fasi, raba kuɗin hawa';

  @override
  String get walletPassPlanWeek => 'Mako';

  @override
  String get walletPassPlanPack => 'Hawa 5';

  @override
  String get walletPassPlanMonth => 'Wata';

  @override
  String walletPassRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hawa $count',
      one: 'Hawa 1',
    );
    return '$_temp0';
  }

  @override
  String walletPassValidity(int days) {
    return 'Yana aiki na kwanaki $days';
  }

  @override
  String walletPassPerRide(String amount) {
    return '$amount kowace hawa';
  }

  @override
  String get walletPassVersus => 'Idan aka kwatanta da kuɗin hawa ɗaya-ɗaya';

  @override
  String walletPassSingleRow(int count, String fare) {
    return '$count × $fare ɗaya';
  }

  @override
  String get walletPassPassRow => 'Fasi';

  @override
  String walletPassSave(String amount) {
    return 'Ka tanadi $amount';
  }

  @override
  String get walletPassNoSave => 'Babu tanadi a kuɗin hawanka na yau da kullum';

  @override
  String get walletPassNoHistory =>
      'Tanadi zai bayyana bayan kuɗin hawanka na farko daga walat';

  @override
  String walletPassUsualFare(String amount) {
    return 'Kuɗin hawanka na yau da kullum $amount';
  }

  @override
  String walletPassActive(String date) {
    return 'Yana aiki har zuwa $date';
  }

  @override
  String walletSplitNotFoundNumber(String phone) {
    return '$phone ba ya kan Along tukuna';
  }

  @override
  String get walletSplitNotOnAlong => 'Ba ya kan Along tukuna';

  @override
  String get walletSplitRequests => 'Buƙatunka';

  @override
  String get walletSplitPending => 'Ana jira';

  @override
  String get walletSplitPaidStatus => 'An biya';

  @override
  String get walletSplitDeclined => 'An ƙi';

  @override
  String get walletPassSaveLabel => 'Tanadinka';
}
