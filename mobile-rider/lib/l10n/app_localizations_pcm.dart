// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nigerian Pidgin (`pcm`).
class AppLocalizationsPcm extends AppLocalizations {
  AppLocalizationsPcm([String locale = 'pcm']) : super(locale);

  @override
  String get phoneEntryTitle => 'Move anyhow. Your way.';

  @override
  String get phoneEntrySubtitle =>
      'We go text code to this number so the ride go be your own.';

  @override
  String get continueButton => 'Continue';

  @override
  String get legalPrefix => 'If you continue, you agree to our ';

  @override
  String get termsLink => 'Terms';

  @override
  String get legalMiddle => ' and ';

  @override
  String get privacyLink => 'Privacy Policy';

  @override
  String otpTitle(String phone) {
    return 'Put the 6-digit code wey we send to $phone';
  }

  @override
  String get wrongNumber => 'Wrong number?';

  @override
  String get resendCode => 'Send code again';

  @override
  String resendCountdown(int seconds) {
    return 'Send again in ${seconds}s';
  }

  @override
  String get nameTitle => 'Wetin drivers go dey call you?';

  @override
  String get nameHint => 'Your name';

  @override
  String get skip => 'Skip am';

  @override
  String get errorInvalidPhone => 'Put correct Naija number';

  @override
  String errorRateLimited(int seconds) {
    return 'You don try too many times. Try again in ${seconds}s';
  }

  @override
  String get errorWrongOtp => 'Code no correct — try again';

  @override
  String get errorExpiredOtp => 'Code don expire — ask for new one';

  @override
  String get errorGeneric => 'Something no work. Abeg try again.';

  @override
  String get errorAuthNotConfigured =>
      'This build no connect to Along. Rebuild the staging APK with env/staging.json.';

  @override
  String get navHome => 'Home';

  @override
  String get navTrips => 'Trips dem';

  @override
  String get sponsoredLabel => 'Sponsor';

  @override
  String get navAccount => 'Account';

  @override
  String get homeSearchHint => 'Where you dey go?';

  @override
  String get homeMenu => 'Menu';

  @override
  String get homeVehicles => 'Motor dem';

  @override
  String get homeRecenter => 'Center am again';

  @override
  String get guardianIntro =>
      'Check-in for this ride, only when you ask for am.';

  @override
  String get homeLocationDeniedBanner =>
      'On location to see motor wey dey near';

  @override
  String get homeChooseOnMap => 'Choose for map';

  @override
  String get homeNearbyTitle => 'Near you';

  @override
  String homeNearbyRow(
    String countBucket,
    String mode,
    String heading,
    int minutes,
  ) {
    return '$countBucket $mode near · dey go $heading · ~$minutes min';
  }

  @override
  String get modeKeke => 'keke';

  @override
  String get searchTitle => 'Where you dey go?';

  @override
  String get searchRecentsTitle => 'Recent ones';

  @override
  String get searchResultsTitle => 'Results';

  @override
  String get searchOfflineHint => 'No network · dey search saved places';

  @override
  String get cachedOptionsStaleBadge => 'Saved · fit don old';

  @override
  String get adjustPickupTitle => 'Change pickup';

  @override
  String adjustPickupBoardingAt(String stageName) {
    return 'You go board for: $stageName';
  }

  @override
  String get adjustPickupConfirm => 'Confirm place';

  @override
  String get tripOptionsHeading => 'Choose how you go go';

  @override
  String get tripOptionsDegradedBanner => 'Live time no dey';

  @override
  String get tripOptionsSlowerDirectCaption => 'E slow pass transfer options';

  @override
  String get tripOptionsAgreePrice => 'Agree price';

  @override
  String get pricingTitle => 'Along Price';

  @override
  String get pricingLapsed => 'No agreement — try another motor';

  @override
  String get pricingOutOfRange => 'Motor don pass';

  @override
  String get pricingDeclined => 'Dem no gree the offer';

  @override
  String pricingDriverOffer(String amount) {
    return 'Driver offer $amount';
  }

  @override
  String get hailSearchTitle => 'Where you dey go?';

  @override
  String get requestUndoMessage => 'Dey request…';

  @override
  String get loadFlagTitle => 'You carry load?';

  @override
  String get loadFlagSizeSmall => 'Small';

  @override
  String get loadFlagSizeMedium => 'Medium';

  @override
  String get loadFlagSizeLarge => 'Big';

  @override
  String get loadFlagNoteHint => 'Small note if you want (140 letters)';

  @override
  String get loadFlagRememberDay => 'Remember am for today';

  @override
  String get loadFlagCapacityWarning => 'This one fit no carry your load';

  @override
  String get loadFlagRequestAnyway => 'Request am anyway';

  @override
  String get loadFlagDone => 'Done';

  @override
  String requestingCountdown(int seconds) {
    return '${seconds}s remain';
  }

  @override
  String get requestingFindingAnother => 'We dey find another motor…';

  @override
  String get requestingCancel => 'Cancel';

  @override
  String get requestingExpired => 'No driver answer — check other options';

  @override
  String get coverageGapTitle => 'No route for here yet';

  @override
  String coverageGapNearestBoarding(String name, String distance) {
    return 'Nearest park: $name · $distance';
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
  String get coverageGapVehiclesNone => 'Motor wey near: none';

  @override
  String coverageGapVehiclesNearby(int count) {
    return 'Motor wey near: $count';
  }

  @override
  String get coverageGapWalkThere => 'Waka go there';

  @override
  String get coverageGapTellUs => 'Tell us about this area';

  @override
  String get coverageGapThanks => 'Thank you — we don log your report';

  @override
  String get tripOptionsWhy => 'Why?';

  @override
  String get tripOptionsWhyTitle => 'Why we recommend am';

  @override
  String get tripOptionsWhyFare => 'Fare';

  @override
  String get tripOptionsWhyTime => 'Time';

  @override
  String get tripOptionsWhyEffort => 'Stress';

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
    return '$bucket dey load';
  }

  @override
  String get transferRequestNextLeg => 'Request next leg';

  @override
  String get transferChangePlan => 'Change plan';

  @override
  String get transferWalkLoading => 'Dey load waka direction…';

  @override
  String get wayfindingTitle => 'Waka direction';

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
  String get wayfindingArrived => 'You don reach';

  @override
  String get wayfindingDegraded => 'Direction fit no too correct';

  @override
  String get wayfindingNoSteps => 'No steps dey';

  @override
  String meetVehicleArrivingIn(int minutes) {
    return 'E go reach in ~$minutes min';
  }

  @override
  String meetVehicleWalkTo(int minutes, String park) {
    return 'Waka $minutes min reach $park';
  }

  @override
  String get meetVehicleDriverSignalLost => 'Driver signal don lost';

  @override
  String get meetVehicleLivePaused => 'Live update don pause';

  @override
  String get meetVehicleShare => 'Share trip';

  @override
  String get meetVehicleCancel => 'Cancel';

  @override
  String get meetVehicleBoarded => 'I don enter';

  @override
  String get activeTripExtend => 'Extend';

  @override
  String get activeTripShare => 'Share';

  @override
  String get activeTripReport => 'Report';

  @override
  String get tripCompleteTitle => 'Trip don finish';

  @override
  String get tripCompletePaidCash => 'I pay cash';

  @override
  String get tripCompleteTier3Question => 'How much you pay?';

  @override
  String get tripCompleteYes => 'Yes';

  @override
  String get tripCompleteDifferent => 'Different amount';

  @override
  String get tripCompleteDifferentPrompt => 'Pick the money wey you pay';

  @override
  String get extendTripTitle => 'Extend trip';

  @override
  String get extendTripSearchHint => 'Where now?';

  @override
  String extendTripDestination(String destination) {
    return 'Dey continue go $destination';
  }

  @override
  String get extendTripSend => 'Send to driver';

  @override
  String get incomingExtensionTitle => 'Extension request';

  @override
  String incomingExtensionBody(String destination, String delta) {
    return 'Driver wan continue go $destination for +$delta';
  }

  @override
  String get incomingExtensionAccept => 'Accept';

  @override
  String get incomingExtensionDecline => 'No gree';

  @override
  String get payDriverTitle => 'Pay driver';

  @override
  String payDriverCta(String amount) {
    return 'Pay $amount';
  }

  @override
  String get payDriverAmountLocked => 'Amount don lock to this trip';

  @override
  String get payDriverMethodSaved => 'Visa ···4242';

  @override
  String payDriverPending(String amount) {
    return 'Transfer $amount for your bank app';
  }

  @override
  String get payDriverCopyAccount => 'Copy number';

  @override
  String get payDriverAccountCopied => 'Account number don copy';

  @override
  String get payDriverWaitingTransfer => 'We dey wait for your transfer';

  @override
  String get payDriverOtherAmount => 'Other';

  @override
  String get payDriverOtherHint => 'Put amount';

  @override
  String payDriverExpires(int seconds) {
    return 'E go expire in ${seconds}s';
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
    return '$name dey collect cash only';
  }

  @override
  String get payDriverInactive => 'This code no dey work again';

  @override
  String get payDriverDifferentDriver =>
      'Your trip now dey with another driver';

  @override
  String get payDriverConfirmOther => 'No be my trip driver — pay am anyway';

  @override
  String get payDriverFailed => 'Payment no go';

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
  String get scanEnterCode => 'Type code instead';

  @override
  String get scanEnterCodePrompt => 'Put driver code';

  @override
  String get scanCodeHint => '8-character code';

  @override
  String get scanCodeSubmit => 'Continue';

  @override
  String get scanBackToCamera => 'Go back to camera';

  @override
  String get scanNotAlong => 'No be Along code';

  @override
  String get payMethodsTitle => 'How to pay';

  @override
  String get payMethodsDefault => 'Default';

  @override
  String get payMethodsSetDefault => 'Make am default';

  @override
  String get payMethodsRemove => 'Remove';

  @override
  String get payMethodsAdd => 'Add card';

  @override
  String get payMethodsTransferDefault => 'Pay with transfer by default';

  @override
  String get activeTripScan => 'Scan';

  @override
  String get tripsEmpty => 'No finished trip yet.';

  @override
  String get tripDetailTitle => 'Trip details';

  @override
  String get tripDetailMissing => 'We no see the trip';

  @override
  String get tripDetailShareReceipt => 'Share receipt';

  @override
  String get tripDetailReceiptCopied => 'Receipt don copy';

  @override
  String get sosTeamAlerted => 'Ready to call 112';

  @override
  String get sosSharingDetails => 'Share your live location with your people';

  @override
  String sosCallEmergency(String number) {
    return 'Call $number';
  }

  @override
  String get sosShareWithContact => 'Share with one contact';

  @override
  String get sosHoldToCancel => 'Hold am to cancel';

  @override
  String get sosRaising => 'Dey open the 112 call…';

  @override
  String get sosRaiseFailed => '112 call no gree open';

  @override
  String get sosRetry => 'Try again';

  @override
  String get reportIncidentTitle => 'Report wetin happen';

  @override
  String get reportIncidentCategoryHeading => 'Wetin happen?';

  @override
  String get reportIncidentDescriptionHeading => 'Tell us more';

  @override
  String get reportIncidentDescriptionHint =>
      'Talk wetin happen (details dey help)';

  @override
  String get reportIncidentAttachPhoto => 'Add photo';

  @override
  String get reportIncidentSubmit => 'Send report';

  @override
  String get reportIncidentPickCategory => 'Pick one category';

  @override
  String get reportIncidentDescriptionRequired => 'Add small explanation';

  @override
  String get reportIncidentSubmitted => 'Report don save for this phone';

  @override
  String get incidentCategorySafety => 'Safety';

  @override
  String get incidentCategoryFareDispute => 'Fare wahala';

  @override
  String get incidentCategoryVehicleQuality => 'Motor condition';

  @override
  String get incidentCategoryDriverBehavior => 'Driver behaviour';

  @override
  String get incidentCategoryLostItem => 'Something lost';

  @override
  String get incidentCategoryOther => 'Other';

  @override
  String get shareTripTitle => 'Share live trip';

  @override
  String get shareTripCreateLink => 'Make share link';

  @override
  String get shareTripCopy => 'Copy link';

  @override
  String get shareTripSms => 'SMS';

  @override
  String get shareTripCopied => 'Link don copy';

  @override
  String get shareTripExpiryNote => 'Link go expire when your trip finish';

  @override
  String get shareTripActiveHeading => 'Shares wey dey on';

  @override
  String get shareTripAnonymousContact => 'Shared contact';

  @override
  String shareTripExpires(String date) {
    return 'E go expire $date';
  }

  @override
  String shareTripSmsBody(String url) {
    return 'Follow my Along trip: $url';
  }

  @override
  String get accountProfileHeading => 'PROFILE';

  @override
  String get accountPreferencesHeading => 'WETIN YOU LIKE';

  @override
  String get accountCityLabel => 'Home city';

  @override
  String get accountCityHint =>
      'Map and search go use dis city if location no dey';

  @override
  String get accountPaymentHeading => 'PAYMENT';

  @override
  String get accountSafetyHeading => 'SAFETY';

  @override
  String get accountWayfindingLabel => 'Direction style';

  @override
  String get accountSortLabel => 'Default trip sort';

  @override
  String get accountWomenOnlyLabel => 'Women-only match';

  @override
  String get accountWomenOnlyHint => 'Prefer women drivers when dem dey';

  @override
  String get accountPaymentCashDefault => 'Cash';

  @override
  String get accountPaymentCashHint => 'Default way to pay for Along trips';

  @override
  String get accountSafetyHowSos => 'How SOS dey work';

  @override
  String get accountSafetyHowSosBody =>
      'Hold SOS to call 112 and share where you dey with your people';

  @override
  String get accountHelp => 'Help';

  @override
  String get accountLegal => 'Legal';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get homePlanYourDay => 'Plan your day';

  @override
  String get dayPlannerTitle => 'Today plan';

  @override
  String get dayPlannerEmpty => 'No stop for your plan yet';

  @override
  String get dayPlannerNotBookedHint =>
      'Stops don plan — matching go start when you tap Match now. Nothing dey reserved before time.';

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
    return 'E dey go · ETA $minutes min';
  }

  @override
  String get dayPlannerStopReady => 'Ready — tap Match now below';

  @override
  String get dayPlannerStopPrepareHint => 'Tap Prepare when you ready';

  @override
  String get dayPlannerStopPending => 'Next';

  @override
  String get dayPlannerStopSkipped => 'Skipped';

  @override
  String get itineraryEntryTitle => 'Plan your day';

  @override
  String get itineraryEntryStructured => 'Stops';

  @override
  String get itineraryEntryNaturalLanguage => 'Describe';

  @override
  String get itineraryEntryStopHint => 'Where you dey go?';

  @override
  String get itineraryEntryAddRow => 'Add another stop';

  @override
  String get itineraryEntryDescribeDay => 'Talk about your day';

  @override
  String get itineraryEntryNlHint =>
      'e.g. drop pikin for school, then work, then market';

  @override
  String get itineraryEntryMicTitle => 'Talk your stops';

  @override
  String get itineraryEntryMicHint => 'Talk or type your stops…';

  @override
  String get itineraryEntryParse => 'Preview stops';

  @override
  String get itineraryEntryProposalTitle => 'Wetin we hear';

  @override
  String get itineraryEntryUnresolved => 'E need place name';

  @override
  String get itineraryEntryLooksRight => 'E correct';

  @override
  String get itineraryEntrySavePlan => 'Save plan';

  @override
  String get sosQueued =>
      'E don save for this phone. Call 112 when network come back.';

  @override
  String get sosLiveLink => 'Copy live location link';

  @override
  String get sosLiveLinkCopied => 'Live location link don copy';

  @override
  String get sosContactsHeading => 'Tell person wey you trust';

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
      'We go tell these people if you press SOS. Up to 5. WhatsApp or text go open for your phone.';

  @override
  String get emergencyContactsEmpty => 'No emergency contact yet';

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
  String get emergencyContactInvalidPhone => 'Use number like +2348012345678';

  @override
  String get emergencyContactLimit => 'You fit save up to 5 contacts';

  @override
  String get emergencyContactSaveFailed => 'We no fit save that contact';

  @override
  String get vehiclesTitle => 'Motor dem';

  @override
  String freeSeatCount(int count) {
    return '$count free';
  }

  @override
  String get seatStale => 'Seat map don pass one minute';

  @override
  String get filterRulesHint => 'Search driver rules';

  @override
  String get seatTaken => 'Person just take that seat';

  @override
  String get acknowledgeToClaim => 'I gree';

  @override
  String get noVehicles => 'No motor match these rules';

  @override
  String get seatFree => 'free';

  @override
  String get seatOccupied => 'person dey';

  @override
  String get seatHeld => 'held';

  @override
  String get seatBlocked => 'blocked';

  @override
  String get seatDriver => 'driver';

  @override
  String get seatLuggage => 'load';

  @override
  String get voiceBookingHint => 'Talk am, like Wuse go Berger';

  @override
  String get textMapTitle => 'Motor wey near';

  @override
  String get textMapEmpty => 'No motor for this side yet';

  @override
  String get plateCheck => 'I see dis plate';

  @override
  String get plateMatches => 'Plate correct';

  @override
  String get plateScan => 'Scan plate';

  @override
  String get plateScanHint => 'Put the plate inside the frame';

  @override
  String get plateScanDenied =>
      'Camera dey off. You fit still confirm the plate yourself.';

  @override
  String get plateScanMismatch =>
      'This plate no match the one wey dem register.';

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
  String get guardianEnabled => 'Check-in for this trip';

  @override
  String get guardianOffRoute => 'Metres off route';

  @override
  String get guardianLongStop => 'Long stop minutes';

  @override
  String get guardianCheckIn => 'Check-in minutes';

  @override
  String get guardianSafeWord => 'Safe word';

  @override
  String get guardianSave => 'Save';

  @override
  String get guardianOk => 'I dey OK';

  @override
  String get guardianOffRouteBody =>
      'You don far from the motor pass wetin you set.';

  @override
  String get guardianLongStopBody =>
      'The motor don stand one place pass the time wey you set.';

  @override
  String get guardianCheckInBody =>
      'Time don reach for the check-in wey you set.';

  @override
  String get guardianMissedBody => 'The check-in still dey open.';

  @override
  String get guardianSafeWordHint => 'Talk your word';

  @override
  String get tripMessagesTitle => 'Message the driver';

  @override
  String get tripMessagesClosed => 'This chat don close.';

  @override
  String get tripMessagesDriver => 'Driver';

  @override
  String get tripMessagesRider => 'You';

  @override
  String get tripMessagesHint => 'Note about something wey you forget';

  @override
  String get tripMessagesSend => 'Send';

  @override
  String get holdNotOffered => 'This driver never on seat hold';

  @override
  String get walkExtension => 'Minutes wey you need to waka';

  @override
  String get stageRadarTitle => 'Park board';

  @override
  String get stageRadarLeaving => 'Next to comot';

  @override
  String stageRadarSeats(int free, int total) {
    return '$free of $total free';
  }

  @override
  String get stageRadarEmpty => 'No motor dey load here yet';

  @override
  String get stageRadarVerified => 'Verified';

  @override
  String get stageRadarFavourite => 'Save driver';

  @override
  String get fareShieldTitle => 'Fair fare';

  @override
  String get fareShieldQuiet => 'Trips never reach for this road';

  @override
  String get fareShieldDispute => 'This fare too high';

  @override
  String fareShieldAnchored(int seconds) {
    return 'One offer, e open for $seconds seconds';
  }

  @override
  String get fareHistoryTitle => 'By hour';

  @override
  String fareHistoryRow(int hour, String amount) {
    return '$hour:00 · $amount';
  }

  @override
  String activeTripMessage(String name) {
    return 'Send message give $name';
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
  String get tripOptionsRecommended => 'Best one';

  @override
  String tripOptionsRequest(String fare) {
    return 'Request $fare';
  }

  @override
  String get searchChooseOnMapDetail => 'Put pin for map';

  @override
  String get searchEmpty => 'Type park, market or street';

  @override
  String get tripSortCheapest => 'Cheapest';

  @override
  String get tripSortFastest => 'Fastest';

  @override
  String get tripSortEasiest => 'Less waka';

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
    return '$area · $distance from here';
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
      other: '$minutes min waka',
    );
    return '$_temp0';
  }

  @override
  String tripMetaWait(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '~$minutes min to wait',
    );
    return '$_temp0';
  }

  @override
  String get tripMetaDirect => 'straight';

  @override
  String tripMetaTransferAt(String park) {
    return 'change motor for $park';
  }

  @override
  String tripMetaTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count change',
    );
    return '$_temp0';
  }

  @override
  String get searchShortcutHome => 'House';

  @override
  String get searchShortcutWork => 'Work';

  @override
  String get searchShortcutAdd => 'Add am';

  @override
  String get searchShortcutPinDetail => 'For map';

  @override
  String placeAway(String distance) {
    return '$distance from here';
  }

  @override
  String get homePlanYourDayDetail => 'Join your stops for one trip';

  @override
  String searchPopularTitle(String city) {
    return 'Wetin people dey go for $city';
  }

  @override
  String get tripEtaWorkingOut => 'We dey calculate when you go reach';

  @override
  String tripEtaLastTo(String place) {
    return 'Last time wey we calculate reach $place';
  }

  @override
  String tripEtaArrivingAt(String place) {
    return 'You go reach $place';
  }

  @override
  String get tripEtaPaused => 'Live time don pause';

  @override
  String get tripRetry => 'Try again';

  @override
  String tripEtaTraffic(int minutes) {
    return 'Go-slow dey front. E fit pass $minutes min.';
  }

  @override
  String get tripMinUnit => 'min';

  @override
  String tripAboutClock(String time) {
    return 'Around $time';
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
    return '$low reach $high minutes';
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
    return '$name go reach in';
  }

  @override
  String tripIsHere(String name) {
    return '$name don reach';
  }

  @override
  String get tripDriverHere => 'Driver don reach';

  @override
  String get tripMeetAtPickup => 'Meet am for pickup';

  @override
  String tripCountdownLabel(int minutes, int seconds) {
    return '$minutes minutes $seconds seconds';
  }

  @override
  String get tripPinTitle => 'Trip PIN';

  @override
  String get tripPinSay => 'Talk am for door';

  @override
  String get tripPinNew => 'Collect new PIN';

  @override
  String get tripPinTooSoon =>
      'You just collect new PIN. Try again small time.';

  @override
  String get tripPinFailed => 'We no fit get new PIN. Try again.';

  @override
  String get tripMatchedTitle => 'Una don match';

  @override
  String tripMatchedBody(String name) {
    return 'Enter. $name go start the trip.';
  }

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptNotReady => 'Receipt never ready';

  @override
  String get receiptNotReadyBody =>
      'E still dey come. E go also dey for Trips.';

  @override
  String get receiptTryAgain => 'Try again';

  @override
  String get receiptDone => 'Done';

  @override
  String receiptHowWas(String name) {
    return 'How $name take do?';
  }

  @override
  String get receiptFare => 'Fare';

  @override
  String get receiptTotal => 'Total';

  @override
  String get receiptCashPaid => 'Cash wey you pay';

  @override
  String get receiptChangeToWallet => 'Put change for wallet';

  @override
  String receiptWalletNow(String amount) {
    return 'Wallet don be $amount';
  }

  @override
  String get receiptLoadSurcharge => 'Load extra money';

  @override
  String get receiptAlongFee => 'Along fee';

  @override
  String get receiptYourTrip => 'Your trip';

  @override
  String receiptRoute(String from, String to) {
    return '$from go $to';
  }

  @override
  String receiptToday(String time) {
    return 'Today, $time';
  }

  @override
  String get receiptYourDriver => 'your driver';

  @override
  String get ratingTagSafeDriving => 'Correct driving';

  @override
  String get ratingTagFairFare => 'Fair price';

  @override
  String get ratingTagCleanVehicle => 'Clean motor';

  @override
  String get ratingTagPolite => 'Get respect';

  @override
  String get ratingTagOnTime => 'Reach on time';

  @override
  String meetVehicleArrivingAt(String time) {
    return 'E dey come · $time';
  }

  @override
  String get meetVehicleCalculating => 'We dey calculate when e go reach';

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
    return 'Meet am for $place';
  }

  @override
  String requestingFinding(String mode) {
    return 'We dey find your $mode';
  }

  @override
  String requestingSeenNear(String place) {
    return 'Drivers wey dey near $place fit see your request';
  }

  @override
  String get requestingFare => 'Fare';

  @override
  String get adjustPickupPinLabel => 'Pin wey you drop';

  @override
  String get adjustPickupHint =>
      'Tap the map or one stop for down to move the pin';

  @override
  String get adjustPickupNearby => 'Stops wey dey near';

  @override
  String get tripCompleteFareLabel => 'Fare';

  @override
  String tripCompleteRoute(String from, String to) {
    return '$from → $to';
  }

  @override
  String get tripEtaCalculating => 'We dey calculate…';

  @override
  String get activeTripCall => 'Call';

  @override
  String get activeTripSos => 'Hold am for SOS';

  @override
  String get activeTripNaMe => 'Show Na Me';

  @override
  String get tripCompleteSettleQuestion => 'You don pay this fare?';

  @override
  String tripCompletePayHint(String driver) {
    return 'Pay $driver for app, or tell us say you pay cash.';
  }

  @override
  String get meetVehicleNaMeShow => 'Raise am make your driver fit see you';

  @override
  String get reportIncidentSubtitle =>
      'Tell us wetin happen. Our safety team dey read every report.';

  @override
  String get shareTripRevoke => 'Stop to share';

  @override
  String tripsRowDetail(String first, String second) {
    return '$first · $second';
  }

  @override
  String get tripDriverFallback => 'Your driver';

  @override
  String get tripsLoadFailed => 'We no fit load your trips. Try again.';

  @override
  String get tripHoldForSos => 'Hold am for SOS';

  @override
  String get tripNaMe => 'Na Me';

  @override
  String get tripCall112 => 'Call 112';

  @override
  String get tripSignalSent => 'E don go';

  @override
  String get fareTierVerified => 'Normal price';

  @override
  String get fareTierCrowd => 'Wetin people dey pay';

  @override
  String get fareTierCandidate => 'No sure yet';

  @override
  String get fareTierEstimate => 'Estimate, price am';

  @override
  String get receiptExtension => 'Trip extension';

  @override
  String receiptIncludesFee(String amount) {
    return 'E don include $amount Along fee';
  }

  @override
  String get receiptShareHeader => 'Along trip receipt';

  @override
  String get tripStatusCompleted => 'Don finish';

  @override
  String get extendTripNowFare => 'Fare wey you dey pay';

  @override
  String get extendTripNewTotal => 'New total';

  @override
  String get extendTripDriverConfirms =>
      'Your driver go confirm before anything change';

  @override
  String get scanToPayHint => 'Point your camera for driver Along code';

  @override
  String get scanTorch => 'Torchlight';

  @override
  String get payMethodsSubtitle => 'Choose how you go dey pay drivers';

  @override
  String get payMethodsSectionDefault => 'Pay drivers with';

  @override
  String get payMethodsTransferHint =>
      'Pay from your bank app, you no need card';

  @override
  String get payMethodsCards => 'Cards wey you save';

  @override
  String get payMethodsCardsEmpty => 'No card dey yet';

  @override
  String get payMethodsSecure => 'We only keep card brand and last 4 numbers';

  @override
  String wayfindingTo(String place) {
    return 'Go $place';
  }

  @override
  String wayfindingSummary(String distance, int minutes) {
    return '$distance · $minutes min waka';
  }

  @override
  String get wayfindingAudioPlaying => 'Audio dey play';

  @override
  String get wayfindingNowPlaying => 'E dey play now';

  @override
  String get wayfindingYouAreHere => 'You dey here';

  @override
  String wayfindingStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get wayfindingIveArrived => 'I don reach';

  @override
  String get scanFitHint => 'Put the code inside the corners';

  @override
  String get scanFound => 'We don see the code';

  @override
  String get requestingNextTitle => 'Wetin go happen next';

  @override
  String get requestingStepSent =>
      'We don send your request to drivers wey dey near';

  @override
  String get requestingStepAccept =>
      'Driver go accept, you go see im plate number';

  @override
  String requestingStepMeet(String place) {
    return 'Meet am for $place';
  }

  @override
  String get tripGlanceTitle => 'Your trip';

  @override
  String tripGlanceWalk(String place) {
    return 'Waka go $place';
  }

  @override
  String get tripGlanceWait => 'Wait for your ride';

  @override
  String tripGlanceRide(String place) {
    return 'Enter go $place';
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
    return 'You don pay $amount';
  }

  @override
  String get tripsEmptyHint =>
      'Trips wey you take with Along go show here, with receipt.';

  @override
  String get tripsEmptyCta => 'Plan trip';

  @override
  String get scanCodeWhereTitle => 'Where you go see am';

  @override
  String get scanCodeWhereBody =>
      'The 8-character code dey under the QR for driver sticker, or tell am make e open My QR.';

  @override
  String get connOffline => 'No network · you fit still continue';

  @override
  String connOfflineQueued(int count) {
    return 'No network · $count dey wait to send';
  }

  @override
  String get connReconnecting => 'Dey connect again';

  @override
  String connSending(int count) {
    return 'Dey connect again · dey send $count';
  }

  @override
  String get connRestored => 'Network don come back';

  @override
  String connRestoredSent(int count) {
    return 'Network don come back · $count don send';
  }

  @override
  String get connRetry => 'Try again';

  @override
  String get searchPausedTitle => 'Search don pause';

  @override
  String get searchPausedBody =>
      'Network cut. Saved places and map still dey work.';

  @override
  String get searchEmptyTitle => 'We no see any place';

  @override
  String get searchEmptyBody =>
      'Try landmark, market or bus stop wey dey near.';

  @override
  String get searchEmptyOfflineBody =>
      'You no get network, na only saved places dey show. Drop pin instead.';

  @override
  String connNeedsConnection(int count) {
    return 'No network · $count to do again when network dey';
  }

  @override
  String connOfflineMixed(int queued, int needs) {
    return 'No network · $queued go send · $needs to do again';
  }

  @override
  String get walletTitle => 'Wallet';

  @override
  String get walletSubtitle => 'Along credit';

  @override
  String get walletBalance => 'Balance';

  @override
  String get walletBalanceNote => 'E dey stay inside Along';

  @override
  String get walletAddCredit => 'Add credit';

  @override
  String get walletCustom => 'Your own';

  @override
  String get walletHistory => 'History';

  @override
  String get walletHistoryEmpty =>
      'No credit yet. Top up, fare and refund go show here.';

  @override
  String get walletAddCustom => 'Add the amount wey you want';

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
  String get walletUnavailable => 'Wallet no load';

  @override
  String get walletUnavailableBody =>
      'Your credit dey safe. Check your network and try again.';

  @override
  String get walletRetry => 'Try again';

  @override
  String get walletCustomTitle => 'How much?';

  @override
  String get walletCustomHint => '₦100 reach ₦50,000';

  @override
  String get walletCustomTooSmall => 'Minimum na ₦100';

  @override
  String get walletCustomTooLarge => 'Maximum na ₦50,000';

  @override
  String get walletCancel => 'Cancel';

  @override
  String walletAdded(String amount) {
    return '$amount don enter';
  }

  @override
  String get walletTopUpFailed => 'Nothing enter. Try again.';

  @override
  String get walletActionTopUp => 'Top up';

  @override
  String get walletActionSend => 'Send';

  @override
  String get walletActionPass => 'Pass';

  @override
  String get walletActionSplit => 'Share am';

  @override
  String get walletActivity => 'Wetin happen';

  @override
  String get walletEarlier => 'Before';

  @override
  String get walletActivityEmpty =>
      'Nothing never happen. Top up make you ride without cash.';

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
  String get walletSent => 'Don send';

  @override
  String get walletReceived => 'Don collect';

  @override
  String get walletPassEntry => 'Along Pass';

  @override
  String get walletSplitPaid => 'Share don pay';

  @override
  String get walletSplitReceived => 'Share don land';

  @override
  String walletOwedTitle(String name, String amount) {
    return '$name ask for $amount';
  }

  @override
  String get walletOwedBody => 'Your share for ride wey una share';

  @override
  String get walletOwedPay => 'Pay';

  @override
  String get walletOwedDecline => 'No gree';

  @override
  String walletOwedPaidSnack(String amount) {
    return 'You don pay $amount';
  }

  @override
  String get walletOwedDeclinedSnack => 'You no gree the request';

  @override
  String get walletInsufficient => 'Credit no reach. Top up first.';

  @override
  String get walletActionFailed =>
      'E no finish. Try again — we no go charge you twice.';

  @override
  String get walletSendTitle => 'Send credit';

  @override
  String get walletSendSubtitle => 'To another Along rider';

  @override
  String get walletSendPhone => 'Phone number';

  @override
  String get walletSendPhoneHint => '0803 123 4567';

  @override
  String get walletSendPhoneInvalid => 'Put Naija phone number';

  @override
  String get walletSendAmount => 'How much';

  @override
  String get walletSendTooSmall => 'Send at least ₦50';

  @override
  String get walletSendTooLarge => 'No pass ₦50,000';

  @override
  String get walletSendOverBalance => 'E pass your balance';

  @override
  String walletSendCta(String amount) {
    return 'Send $amount';
  }

  @override
  String get walletSendCtaEmpty => 'Send';

  @override
  String get walletSendNotFound => 'No Along rider get that number';

  @override
  String walletSentSnack(String amount) {
    return 'You don send $amount';
  }

  @override
  String walletAvailable(String amount) {
    return 'You get $amount';
  }

  @override
  String get walletPassTitle => 'Along Pass';

  @override
  String get walletPassSubtitle =>
      'Rides wey you don pay before from your credit';

  @override
  String walletPassPrice(String amount) {
    return '$amount every month';
  }

  @override
  String get walletPassBody =>
      'One payment from your wallet. No card, no cash for door.';

  @override
  String walletPassCta(String amount) {
    return 'Buy pass · $amount';
  }

  @override
  String get walletPassBought => 'Pass dey work · Done';

  @override
  String walletPassShort(String amount) {
    return 'Top up $amount more to buy';
  }

  @override
  String get walletSplitTitle => 'Share fare';

  @override
  String get walletSplitSubtitle => 'Ask your co-riders for their share';

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
  String get walletSplitRemove => 'Comot';

  @override
  String walletSplitEach(String amount) {
    return '$amount each';
  }

  @override
  String walletSplitCta(String amount) {
    return 'Ask $amount each';
  }

  @override
  String get walletSplitCtaEmpty => 'Ask for share';

  @override
  String get walletSplitFareInvalid => 'Put the fare, at least ₦100';

  @override
  String walletSplitSentSnack(int count) {
    return 'You don ask $count co-riders';
  }

  @override
  String get walletSplitNotFound => 'One of the numbers never dey Along';

  @override
  String get walletSplitNote =>
      'Dem go pay from their wallet. You go still pay driver like before.';

  @override
  String get accountWallet => 'Wallet';

  @override
  String get accountWalletHint => 'Top up, send, pass, share fare';

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
    return 'E go work for $days days';
  }

  @override
  String walletPassPerRide(String amount) {
    return '$amount for one ride';
  }

  @override
  String get walletPassVersus => 'Compare am with single fares';

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
  String get walletPassNoSave => 'No saving for your normal fare';

  @override
  String get walletPassNoHistory =>
      'Saving go show after your first fare from wallet';

  @override
  String walletPassUsualFare(String amount) {
    return 'Your normal fare na $amount';
  }

  @override
  String walletPassActive(String date) {
    return 'E dey work reach $date';
  }

  @override
  String walletSplitNotFoundNumber(String phone) {
    return '$phone never dey Along';
  }

  @override
  String get walletSplitNotOnAlong => 'E never dey Along';

  @override
  String get walletSplitRequests => 'Your requests';

  @override
  String get walletSplitPending => 'Dey wait';

  @override
  String get walletSplitPaidStatus => 'Don pay';

  @override
  String get walletSplitDeclined => 'E refuse';

  @override
  String get walletPassSaveLabel => 'You save';

  @override
  String get walletPassHow => 'How e dey work';

  @override
  String get walletPassStep1 => 'Pick one plan for up';

  @override
  String get walletPassStep2 =>
      'Pay one time from your Along credit. No card need';

  @override
  String walletPassStep3(int days) {
    return 'E go dey active for $days days from today';
  }

  @override
  String get walletPassDetails => 'Details';

  @override
  String get walletPassRowRides => 'Rides';

  @override
  String get walletPassRowValid => 'Valid reach';

  @override
  String get walletPassRowPaid => 'Pay with';

  @override
  String get walletPassRowPaidValue => 'Along credit';

  @override
  String get sosTitle => 'Safety';

  @override
  String get sosStatusSending => 'We dey tell Along safety team…';

  @override
  String sosStatusSent(String time) {
    return 'Safety team don hear · $time';
  }

  @override
  String get sosStatusQueued =>
      'No network · we don save am, e go send when network come';

  @override
  String get sosStatusFailed => 'E no send · call 112 now';

  @override
  String get sosHoldHint => 'Hold am to call';

  @override
  String get sosMapLive => 'Live';

  @override
  String get sosContactsTitle => 'Contacts';

  @override
  String get sosNoContacts => 'You never add person wey you trust';

  @override
  String get sosAddContact => 'Add';

  @override
  String get sosShareLive => 'Share live trip';

  @override
  String get sosImSafe => 'I dey safe';

  @override
  String get sosImSafeTitle => 'Cancel the alert?';

  @override
  String get sosImSafeBody =>
      'Safety team go stop to follow this trip. Cancel only if you dey safe.';

  @override
  String get sosImSafeConfirm => 'Yes, I dey safe';

  @override
  String get sosKeepAlert => 'Leave the alert';

  @override
  String sosReach(String name) {
    return 'Reach $name';
  }

  @override
  String get guardianShareSubtitle =>
      'Make person wey you trust follow this trip';

  @override
  String guardianShareWatching(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people fit see this trip',
      one: '1 person fit see this trip',
    );
    return '$_temp0';
  }

  @override
  String get guardianShareWho => 'Who fit follow';

  @override
  String get guardianShareNoContacts =>
      'Add person wey you trust to share with one tap';

  @override
  String get guardianShareAddContact => 'Add contact';

  @override
  String get guardianSharePlate => 'Share the plate number';

  @override
  String get guardianShareLocation => 'Share live location';

  @override
  String get guardianShareExpiry => 'Stop after';

  @override
  String get guardianShare30 => '30 min';

  @override
  String get guardianShare60 => '1 hour';

  @override
  String get guardianShareTripEnd => 'Trip finish';

  @override
  String guardianShareCta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Share with $count people',
      one: 'Share with 1 person',
      zero: 'Make share link',
    );
    return '$_temp0';
  }

  @override
  String get guardianShareStop => 'Stop sharing';

  @override
  String guardianShareUntil(String time) {
    return 'Till $time';
  }

  @override
  String get guardianShareWhatsapp => 'WhatsApp';

  @override
  String get guardianShareOffline =>
      'Sharing need network. SOS still dey work without network.';

  @override
  String get guardianShareFailed => 'E no fit start sharing. Try again.';

  @override
  String get guardianShareStopped => 'Sharing don stop';

  @override
  String get guardianShareNoTrip => 'Sharing go start when you dey for trip';

  @override
  String get reportIncidentPhotosHeading => 'Photos';

  @override
  String get reportIncidentPhotosNote =>
      'Reach 4 · na only our safety team go see am';

  @override
  String get reportIncidentAddPhoto => 'Add photo';

  @override
  String get reportIncidentTakePhoto => 'Snap photo';

  @override
  String get reportIncidentChoosePhoto => 'Pick from gallery';

  @override
  String reportIncidentRemovePhoto(int n) {
    return 'Remove photo $n';
  }

  @override
  String reportIncidentUploading(int done, int total) {
    return 'We dey send photo $done of $total';
  }

  @override
  String get reportIncidentSent =>
      'Report don send. Our safety team go follow up.';

  @override
  String get reportIncidentQueued =>
      'No network. Report don save, e go send when network come.';

  @override
  String get reportIncidentFailed => 'E no fit send the report. Try again.';

  @override
  String get reportIncidentPhotoError => 'E no fit add that photo';

  @override
  String optionCardRouteLine(String board, String alight) {
    return 'Enter for $board → $alight';
  }

  @override
  String get authYourNumber => 'Your number';

  @override
  String get authSendCode => 'Text me the code';

  @override
  String get otpCheckTitle => 'Check your text message';

  @override
  String get otpChecking => 'We dey check the code…';

  @override
  String get otpAutofillHint =>
      'The code go fill by itself when the text land.';

  @override
  String get authOffline => 'Network no dey. Connect make you get your code.';

  @override
  String get authBack => 'Go back';

  @override
  String get permSubtitle =>
      'Along go ask only once. You fit change am for Settings any time.';

  @override
  String get permLocationTitle => 'Location';

  @override
  String get permNotifTitle => 'Notifications';

  @override
  String get permCameraTitle => 'Camera';

  @override
  String get permAllow => 'Allow am';

  @override
  String get permLater => 'No be now';

  @override
  String get authStory1H => 'Move around. Your own way.';

  @override
  String get authStory1B => 'Keke, okada, danfo and taxi for one app.';

  @override
  String get authStory2H => 'Correct price, every time.';

  @override
  String get authStory2B => 'See the price before you move. No price wahala.';

  @override
  String get authStory3H => 'Person go always know.';

  @override
  String get authStory3B => 'Share your trip and hold SOS if you need help.';

  @override
  String get nameSubtitle =>
      'Driver go see only your first name. You fit skip am.';

  @override
  String get permTitle => 'Ready for your first ride';

  @override
  String get permLocationBody =>
      'Find where dem go pick you and show driver where you dey.';

  @override
  String get permNotifBody => 'Know the moment your driver land.';

  @override
  String get permCameraBody =>
      'Scan to pay and check the plate before you enter.';

  @override
  String get otpDidntGet => 'E no reach you?';
}
