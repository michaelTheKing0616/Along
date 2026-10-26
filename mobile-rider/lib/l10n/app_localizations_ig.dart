// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Igbo (`ig`).
class AppLocalizationsIg extends AppLocalizations {
  AppLocalizationsIg([String locale = 'ig']) : super(locale);

  @override
  String get phoneEntryTitle => 'Move around. Your way.';

  @override
  String get phoneEntrySubtitle =>
      'We text a code to this number so the ride stays yours.';

  @override
  String get continueButton => 'Gaa n\'ihu';

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
  String get skip => 'Hapụ';

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
  String get navHome => 'Ụlọ';

  @override
  String get navTrips => 'Njem';

  @override
  String get sponsoredLabel => 'Nkwado';

  @override
  String get navAccount => 'Akaụnt';

  @override
  String get homeSearchHint => 'Ebee ka anyị ga?';

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
  String get searchTitle => 'Ebee?';

  @override
  String get searchRecentsTitle => 'Recents';

  @override
  String get searchResultsTitle => 'Results';

  @override
  String get searchOfflineHint => 'Offline — search uses cached places';

  @override
  String get cachedOptionsStaleBadge => 'Cached · may be outdated';

  @override
  String get adjustPickupTitle => 'Gbanwee ebe nbuli';

  @override
  String adjustPickupBoardingAt(String stageName) {
    return 'Ịbanye na: $stageName';
  }

  @override
  String get adjustPickupConfirm => 'Kwado ebe';

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
  String get hailSearchTitle => 'Ebee ka ị na-aga?';

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
    return 'Sekọnd $seconds fọdụrụ';
  }

  @override
  String get requestingFindingAnother => 'Anyị na-achọ ụgbọ ọzọ…';

  @override
  String get requestingCancel => 'Kagbuo';

  @override
  String get requestingExpired => 'Onweghị onye ọkwọ zara — lee nhọrọ ndị ọzọ';

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
  String get wayfindingTitle => 'Ntụziaka ije ụkwụ';

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
  String get wayfindingNoSteps => 'Enweghị nzọụkwụ dị';

  @override
  String meetVehicleArrivingIn(int minutes) {
    return 'Ọ ga-abịa n\'ime ~nkeji $minutes';
  }

  @override
  String meetVehicleWalkTo(int minutes, String park) {
    return 'Jee ije nkeji $minutes ruo $park';
  }

  @override
  String get meetVehicleDriverSignalLost => 'Mgbama onye ọkwọ efuola';

  @override
  String get meetVehicleLivePaused => 'Mmelite ndụ akwụsịla';

  @override
  String get meetVehicleShare => 'Kesaa njem';

  @override
  String get meetVehicleCancel => 'Kagbuo';

  @override
  String get meetVehicleBoarded => 'Abanyela m';

  @override
  String get activeTripExtend => 'Gbatịa';

  @override
  String get activeTripShare => 'Kesaa';

  @override
  String get activeTripReport => 'Kọọ akụkọ';

  @override
  String get tripCompleteTitle => 'Njem agwụla';

  @override
  String get tripCompletePaidCash => 'Akwụrụ m ego n\'aka';

  @override
  String get tripCompleteTier3Question => 'Ego ole ka ị kwụrụ?';

  @override
  String get tripCompleteYes => 'Ee';

  @override
  String get tripCompleteDifferent => 'Ego dị iche';

  @override
  String get tripCompleteDifferentPrompt => 'Họrọ ego i kwụrụ';

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
    return 'Kwụọ $amount';
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
  String get activeTripScan => 'Nyochaa';

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
  String get accountCityLabel => 'Obodo ụlọ';

  @override
  String get accountCityHint =>
      'Maapụ na ọchụchọ na-eji obodo a mgbe enweghị ebe';

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
    return '$count tọgbọrọ chakoo';
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
  String get seatDriver => 'onye ọkwọ';

  @override
  String get seatLuggage => 'luggage';

  @override
  String get voiceBookingHint => 'Kwuo ya, dịka Wuse ruo Berger';

  @override
  String get textMapTitle => 'Vehicles nearby';

  @override
  String get textMapEmpty => 'No vehicles in this direction yet';

  @override
  String get plateCheck => 'Ahụrụ m nọmba a';

  @override
  String get plateMatches => 'Nọmba dabara';

  @override
  String get plateScan => 'Nyochaa nọmba';

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
  String get guardianTitle => 'Onye nche';

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
  String get guardianOk => 'Adị m mma';

  @override
  String get guardianOffRouteBody => 'Ị nọ anya na ụgbọ karịa ka i debere.';

  @override
  String get guardianLongStopBody => 'Ụgbọ ahụ akwụsịla karịa ka i debere.';

  @override
  String get guardianCheckInBody => 'Oge nlele i debere eruola.';

  @override
  String get guardianMissedBody => 'Nlele ahụ ka mepere emepe.';

  @override
  String get guardianSafeWordHint => 'Kwuo okwu gị';

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
    return 'Zitere $name ozi';
  }

  @override
  String get homeGreetingMorning => 'Ụtụtụ ọma';

  @override
  String get homeGreetingAfternoon => 'Ehihie ọma';

  @override
  String get homeGreetingEvening => 'Mgbede ọma';

  @override
  String get homeGreetingNight => 'Ka chi fo';

  @override
  String homeNearbyEta(int minutes) {
    return '~nkeji $minutes';
  }

  @override
  String get tripOptionsRecommended => 'Anyị tụrụ aro';

  @override
  String tripOptionsRequest(String fare) {
    return 'Rịọ $fare';
  }

  @override
  String get searchChooseOnMapDetail => 'Tinye akara';

  @override
  String get searchEmpty => 'Dee ọdọ ụgbọ, ahịa ma ọ bụ okporo ụzọ';

  @override
  String get tripSortCheapest => 'Kacha ọnụ ala';

  @override
  String get tripSortFastest => 'Kacha ọsọ';

  @override
  String get tripSortEasiest => 'Ije ụkwụ dị nta';

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
    return '$area · $distance site ebe a';
  }

  @override
  String tripOptionsSummary(int minutes, String distance) {
    return 'nkeji $minutes · $distance';
  }

  @override
  String tripMetaWalk(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'ije ụkwụ nkeji $minutes',
    );
    return '$_temp0';
  }

  @override
  String tripMetaWait(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '~nchere nkeji $minutes',
    );
    return '$_temp0';
  }

  @override
  String get tripMetaDirect => 'ozugbo';

  @override
  String tripMetaTransferAt(String park) {
    return 'mgbanwe 1 na $park';
  }

  @override
  String tripMetaTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mgbanwe $count',
    );
    return '$_temp0';
  }

  @override
  String get searchShortcutHome => 'Ụlọ';

  @override
  String get searchShortcutWork => 'Ọrụ';

  @override
  String get searchShortcutAdd => 'Tinye';

  @override
  String get searchShortcutPinDetail => 'Na maapụ';

  @override
  String placeAway(String distance) {
    return '$distance site ebe a';
  }

  @override
  String get homePlanYourDayDetail => 'Jikọta ebe ị na-aga n\'otu njem';

  @override
  String searchPopularTitle(String city) {
    return 'Ndị a ma ama na $city';
  }

  @override
  String get tripEtaWorkingOut => 'Anyị na-agbakọ oge ị ga-eru';

  @override
  String tripEtaLastTo(String place) {
    return 'Atụmatụ ikpeazụ ruo $place';
  }

  @override
  String tripEtaArrivingAt(String place) {
    return 'Ị na-eru $place';
  }

  @override
  String get tripEtaPaused => 'Oge ndụ akwụsịla';

  @override
  String get tripRetry => 'Nwaa ọzọ';

  @override
  String tripEtaTraffic(int minutes) {
    return 'Ọgba ụgbọala dị n\'ihu. Ihe dị ka nkeji $minutes ka e ga-egbu.';
  }

  @override
  String get tripMinUnit => 'nkeji';

  @override
  String tripAboutClock(String time) {
    return 'Ihe dị ka $time';
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
      other: 'nkeji $minutes',
      one: 'nkeji 1',
    );
    return '$_temp0';
  }

  @override
  String tripMinutesRangeLabel(int low, int high) {
    return 'Nkeji $low ruo $high';
  }

  @override
  String get tripEmergency => 'Ihe mberede';

  @override
  String get tripSos => 'SOS';

  @override
  String get tripCall => 'Kpọọ';

  @override
  String tripCallName(String name) {
    return 'Kpọọ $name';
  }

  @override
  String get tripMessage => 'Ozi';

  @override
  String tripArrivesIn(String name) {
    return '$name ga-abịa n\'ime';
  }

  @override
  String tripIsHere(String name) {
    return '$name abịala';
  }

  @override
  String get tripDriverHere => 'Onye ọkwọ ụgbọ abịala';

  @override
  String get tripMeetAtPickup => 'Zute n\'ebe nbuli';

  @override
  String tripCountdownLabel(int minutes, int seconds) {
    return 'Nkeji $minutes na sekọnd $seconds';
  }

  @override
  String get tripPinTitle => 'PIN njem';

  @override
  String get tripPinSay => 'Kwuo ya n\'ọnụ ụzọ';

  @override
  String get tripPinNew => 'Nweta PIN ọhụrụ';

  @override
  String get tripPinTooSoon =>
      'Ị ka nwetara PIN ọhụrụ. Nwaa ọzọ n\'oge na-adịghị anya.';

  @override
  String get tripPinFailed => 'Enweghị ike ịnweta PIN ọhụrụ. Nwaa ọzọ.';

  @override
  String get tripMatchedTitle => 'E jikọtala unu';

  @override
  String tripMatchedBody(String name) {
    return 'Banye. $name ga-amalite njem ahụ.';
  }

  @override
  String get receiptTitle => 'Akwụkwọ nnata';

  @override
  String get receiptNotReady => 'Akwụkwọ nnata adịbeghị njikere';

  @override
  String get receiptNotReadyBody => 'Ọ ka na-abịa. Ọ ga-adịkwa na Njem.';

  @override
  String get receiptTryAgain => 'Nwaa ọzọ';

  @override
  String get receiptDone => 'Emechaala';

  @override
  String receiptHowWas(String name) {
    return 'Kedu ka $name si mee?';
  }

  @override
  String get receiptFare => 'Ụgwọ ụgbọ';

  @override
  String get receiptTotal => 'Ngụkọta';

  @override
  String get receiptCashPaid => 'Ego enyere';

  @override
  String get receiptChangeToWallet => 'Tinye mgbanwe n\'obere akpa';

  @override
  String receiptWalletNow(String amount) {
    return 'Obere akpa ugbu a $amount';
  }

  @override
  String get receiptLoadSurcharge => 'Ụgwọ mgbakwunye ibu';

  @override
  String get receiptAlongFee => 'Ụgwọ Along';

  @override
  String get receiptYourTrip => 'Njem gị';

  @override
  String receiptRoute(String from, String to) {
    return '$from ruo $to';
  }

  @override
  String receiptToday(String time) {
    return 'Taa, $time';
  }

  @override
  String get receiptYourDriver => 'onye ọkwọ gị';

  @override
  String get ratingTagSafeDriving => 'Ọkwọ nchekwa';

  @override
  String get ratingTagFairFare => 'Ụgwọ ziri ezi';

  @override
  String get ratingTagCleanVehicle => 'Ụgbọ dị ọcha';

  @override
  String get ratingTagPolite => 'Nwere nkwanye ugwu';

  @override
  String get ratingTagOnTime => 'N\'oge';

  @override
  String meetVehicleArrivingAt(String time) {
    return 'Ọ na-abịa · $time';
  }

  @override
  String get meetVehicleCalculating => 'Anyị na-agbakọ oge ha ga-abịa';

  @override
  String meetVehicleDriverStats(String rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'njem $count',
      one: 'njem 1',
    );
    return '★ $rating · $_temp0';
  }

  @override
  String meetVehicleMeetAt(String place) {
    return 'Zute na $place';
  }

  @override
  String requestingFinding(String mode) {
    return 'Anyị na-achọ $mode gị';
  }

  @override
  String requestingSeenNear(String place) {
    return 'Ndị ọkwọ nọ nso $place nwere ike ịhụ arịrịọ gị';
  }

  @override
  String get requestingFare => 'Ụgwọ ụgbọ';

  @override
  String get adjustPickupPinLabel => 'Ntụtụ i tinyere';

  @override
  String get adjustPickupHint =>
      'Pịa maapụ ma ọ bụ ọdụ dị n\'okpuru iji bugharịa ntụtụ';

  @override
  String get adjustPickupNearby => 'Ọdụ ndị dị nso';

  @override
  String get tripCompleteFareLabel => 'Ụgwọ ụgbọ';

  @override
  String tripCompleteRoute(String from, String to) {
    return '$from → $to';
  }

  @override
  String get tripEtaCalculating => 'Anyị na-agbakọ…';

  @override
  String get activeTripCall => 'Kpọọ';

  @override
  String get activeTripSos => 'Jide maka SOS';

  @override
  String get activeTripNaMe => 'Gosi Na Me';

  @override
  String get tripCompleteSettleQuestion => 'Ị kwụọla ụgwọ a?';

  @override
  String tripCompletePayHint(String driver) {
    return 'Kwụọ $driver n\'ime ngwa, ma ọ bụ gwa anyị na ị kwụrụ ego aka.';
  }

  @override
  String get meetVehicleNaMeShow => 'Welie ya ka onye ọkwọ ụgbọ gị hụ gị';

  @override
  String get reportIncidentSubtitle =>
      'Gwa anyị ihe mere. Ndị otu nchekwa anyị na-agụ akụkọ ọ bụla.';

  @override
  String get shareTripRevoke => 'Kwụsị ikesa';

  @override
  String tripsRowDetail(String first, String second) {
    return '$first · $second';
  }

  @override
  String get tripDriverFallback => 'Onye ọkwọ ụgbọ gị';

  @override
  String get tripsLoadFailed => 'Anyị enweghị ike ibulite njem gị. Nwaa ọzọ.';

  @override
  String get tripHoldForSos => 'Jide maka SOS';

  @override
  String get tripNaMe => 'Ọ bụ M';

  @override
  String get tripCall112 => 'Kpọọ 112';

  @override
  String get tripSignalSent => 'Ezigala';

  @override
  String get fareTierVerified => 'Ụgwọ nkịtị';

  @override
  String get fareTierCrowd => 'Ụgwọ ndị mmadụ';

  @override
  String get fareTierCandidate => 'Ejibeghị n\'aka';

  @override
  String get fareTierEstimate => 'Atụmatụ, kwekọrịta ọnụ';

  @override
  String get receiptExtension => 'Mgbatị njem';

  @override
  String receiptIncludesFee(String amount) {
    return 'Gụnyere ụgwọ Along $amount';
  }

  @override
  String get receiptShareHeader => 'Akwụkwọ ụgwọ njem Along';

  @override
  String get tripStatusCompleted => 'Emechara';

  @override
  String get extendTripNowFare => 'Ụgwọ ugbu a';

  @override
  String get extendTripNewTotal => 'Mkpokọta ọhụrụ';

  @override
  String get extendTripDriverConfirms =>
      'Onye ọkwọ ụgbọ gị ga-akwado tupu ihe ọ bụla agbanwee';

  @override
  String get scanToPayHint =>
      'Tụgharịa kamera gị n\'koodu Along nke onye ọkwọ ụgbọ';

  @override
  String get scanTorch => 'Ọkụ tọọchị';

  @override
  String get payMethodsSubtitle => 'Họrọ otú ị ga-esi kwụọ ndị ọkwọ ụgbọ ụgwọ';

  @override
  String get payMethodsSectionDefault => 'Kwụọ ndị ọkwọ ụgbọ ụgwọ site na';

  @override
  String get payMethodsTransferHint =>
      'Kwụọ site na ngwa ụlọ akụ gị, achọghị kaadị';

  @override
  String get payMethodsCards => 'Kaadị echekwara';

  @override
  String get payMethodsCardsEmpty => 'Enweghị kaadị echekwara ugbu a';

  @override
  String get payMethodsSecure =>
      'Anyị na-edebe naanị aha kaadị na ọnụọgụ 4 ikpeazụ';

  @override
  String wayfindingTo(String place) {
    return 'Gaa $place';
  }

  @override
  String wayfindingSummary(String distance, int minutes) {
    return '$distance · ije nkeji $minutes';
  }

  @override
  String get wayfindingAudioPlaying => 'Ụda na-akpọ';

  @override
  String get wayfindingNowPlaying => 'Na-akpọ ugbu a';
}
