// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nigerian Pidgin (`pcm`).
class AppLocalizationsPcm extends AppLocalizations {
  AppLocalizationsPcm([String locale = 'pcm']) : super(locale);

  @override
  String get driverBrandingLine => 'Drive with Along';

  @override
  String get phoneEntryTitle => 'Drive with Along';

  @override
  String get phoneEntrySubtitle =>
      'We go text code to this number so your day go be your own.';

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
  String get errorInvalidPhone => 'Put correct Naija number';

  @override
  String get errorWrongOtp => 'Code no correct — try again';

  @override
  String get errorExpiredOtp => 'Code don expire — ask for new one';

  @override
  String errorRateLimited(int seconds) {
    return 'You don try too many times. Try again in ${seconds}s';
  }

  @override
  String get errorGeneric => 'Something no work. Abeg try again.';

  @override
  String get errorAuthNotConfigured =>
      'This build no connect to Along. Rebuild the staging APK with env/staging.json.';

  @override
  String get errorValidation => 'Abeg check the fields come try again.';

  @override
  String get errorPlateConflict => 'Dem don register this plate before.';

  @override
  String get profileTitle => 'Your profile';

  @override
  String get profileSubtitle => 'Tell us small about yourself';

  @override
  String get nameLabel => 'Full name';

  @override
  String get nameHint => 'Your name';

  @override
  String get cityLabel => 'City';

  @override
  String get genderLabel => 'Gender (if you want)';

  @override
  String get genderFemale => 'Woman';

  @override
  String get genderMale => 'Man';

  @override
  String get genderOther => 'I no wan talk';

  @override
  String get photoOptional => 'Add photo (if you want)';

  @override
  String get vehicleTitle => 'Your motor';

  @override
  String get vehicleSubtitle => 'How you go drive for Along?';

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
  String get ownerQuestion => 'Na your motor be this?';

  @override
  String get ownerYes => 'Yes, na my own';

  @override
  String get ownerNo => 'No, na another person own';

  @override
  String get ownerNameLabel => 'Owner name';

  @override
  String get ownerPhoneLabel => 'Owner phone';

  @override
  String get documentsTitle => 'Verify your papers';

  @override
  String get documentsSubtitle => 'Upload each paper to start to drive';

  @override
  String get docStatusNotStarted => 'Never start';

  @override
  String get docStatusPending => 'E dey wait';

  @override
  String get docStatusApproved => 'Approved';

  @override
  String get docStatusRejected => 'Dem reject am';

  @override
  String get saveAndContinueLater => 'Save am, continue later';

  @override
  String captureTitle(String document) {
    return 'Snap $document';
  }

  @override
  String get captureGuide => 'Put the paper inside the frame';

  @override
  String get takePhoto => 'Snap photo';

  @override
  String get retakePhoto => 'Snap again';

  @override
  String get submitDocument => 'Send paper';

  @override
  String get ocrReviewTitle => 'Check the details wey we pull out';

  @override
  String get ocrReviewSubtitle => 'Confirm each field before you send';

  @override
  String ocrSuggestedValue(String value) {
    return 'Suggested: $value';
  }

  @override
  String get ocrConfirmField => 'Use this one';

  @override
  String get ocrFieldConfirmed => 'Confirmed';

  @override
  String get ocrNoAutoFillNote =>
      'We no dey fill ID numbers by ourself — tap confirm for each field.';

  @override
  String get pendingTitle => 'Verification dey go on';

  @override
  String get pendingHero => 'We dey check your papers';

  @override
  String get pendingExpectedGeneric => 'E dey take 1–3 work days';

  @override
  String pendingExpectedHours(int hours) {
    return 'Expect am inside $hours hours';
  }

  @override
  String get pendingWhatNext =>
      'We go tell you when dem approve you. You fit set your route while you dey wait.';

  @override
  String get setupRouteCta => 'Set your route while you dey wait';

  @override
  String get routesListTitle => 'Your routes';

  @override
  String get routesAddRoute => 'Add route';

  @override
  String get routesEmptyTitle => 'Set your route with small taps';

  @override
  String get routesEmptyBody =>
      'Publish your stops and prices so passengers fit find you for your usual road.';

  @override
  String get routeSuggestedCardTitle => 'Suggested route';

  @override
  String routeSuggestedCardBody(String mode, int stopCount) {
    return 'We see your usual $mode road with $stopCount stops.';
  }

  @override
  String get routeSuggestedCardCta => 'Tap to check and publish';

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
    return 'Load extra: $amount';
  }

  @override
  String get routeLoadSurchargeOptional => 'Load extra (if you want)';

  @override
  String get routeLoadSurchargeHint => 'e.g. 50';

  @override
  String get routeFastSetupTitle => 'Route setup';

  @override
  String get routeFastSetupQuestion => 'Na your route be this?';

  @override
  String routeFastSetupSubtitle(int count) {
    return 'We see $count stops from your usual road';
  }

  @override
  String get routeYesPublish => 'Yes, publish';

  @override
  String get routeEditPrices => 'Edit prices';

  @override
  String get routeDrawManually => 'No, draw am myself';

  @override
  String get routeDrawTitle => 'Draw your route';

  @override
  String get routeDrawHint => 'Tap the map to add stops';

  @override
  String get routeDrawEmptyStops => 'Add at least two stops for map';

  @override
  String get routePublish => 'Publish';

  @override
  String routePriceToEnd(String amount) {
    return 'Reach end: $amount';
  }

  @override
  String routeSnapMatched(String name) {
    return 'Matched: $name ✓';
  }

  @override
  String get routeSnapNewStopHint => 'New stop — name?';

  @override
  String get routeSnapPending => 'Dey match…';

  @override
  String get routePriceKeypadTitle => 'Set price reach end';

  @override
  String get routePriceKeypadSet => 'Set';

  @override
  String get routePriceErrorNonMonotone =>
      'Price no suppose increase as you dey reach destination.';

  @override
  String get routePriceErrorLastNotZero => 'Last stop must be ₦0.';

  @override
  String get routePriceErrorEmpty => 'Add at least one stop wey get price.';

  @override
  String get routeLoadError => 'Routes no gree load.';

  @override
  String get routePublishError => 'Route no gree publish. Try again.';

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
  String get homeUnverifiedBanner => 'Finish verification to go online.';

  @override
  String get homeBatteryGuardBanner =>
      'Battery don low — location update don slow to save power.';

  @override
  String get homeLedgerBlockedBanner =>
      'Matching don pause — settle your balance to go online.';

  @override
  String get homeSelectPark => 'At: choose park ▾';

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
      'Choose park before you go online for park.';

  @override
  String get homeErrorLocation => 'On location to go online.';

  @override
  String get homeParkPickerTitle => 'Parks wey near';

  @override
  String get homeParkPickerEmpty => 'No park near.';

  @override
  String homeParkDistance(int meters) {
    return '$meters m away';
  }

  @override
  String get homeParkSomewhereElse => 'I dey another place';

  @override
  String get incomingRequestTitle => 'New request';

  @override
  String incomingRequestCountdown(int seconds) {
    return '${seconds}s';
  }

  @override
  String incomingRequestRiderLine(String name, String rating, int trips) {
    return '$name · $rating · $trips trips';
  }

  @override
  String get incomingRequestPickup => 'Pickup';

  @override
  String get incomingRequestRoamingPickup => 'Passenger location';

  @override
  String get incomingRequestRoamingPickupMeta => 'Road hail — meet for pin';

  @override
  String incomingRequestCascade(int attempt, int max) {
    return 'Retry $attempt of $max';
  }

  @override
  String get incomingRequestDropoff => 'Drop-off';

  @override
  String incomingRequestPickupMeta(int distance, int eta) {
    return '$distance m · $eta min';
  }

  @override
  String incomingRequestFareLine(String amount, String tierLabel) {
    return 'Passenger go pay $amount · $tierLabel';
  }

  @override
  String incomingRequestAlongFee(String amount, String percent) {
    return 'Along fee $amount · $percent%, e go add for drop';
  }

  @override
  String get incomingRequestLoadDefault => 'Passenger get load';

  @override
  String incomingRequestLoadDetail(String size, String note) {
    return '$size load — $note';
  }

  @override
  String get incomingRequestWomenOnly => 'Women-only match';

  @override
  String get incomingRequestApproachBandUnder2 => 'under 2 min';

  @override
  String get incomingRequestApproachBandM2_5 => '2–5 min';

  @override
  String get incomingRequestApproachBandOver5 => '5+ min';

  @override
  String get incomingRequestAccept => 'Accept';

  @override
  String get incomingRequestDecline => 'No gree';

  @override
  String get declineReasonTitle => 'Why you no gree?';

  @override
  String get declineReasonNoRoomForLoad => 'No space for load';

  @override
  String get declineReasonTooFar => 'E too far';

  @override
  String get declineReasonEndingShift => 'I dey close work';

  @override
  String get declineReasonOther => 'Other';

  @override
  String get fareTierStandard => 'Normal price';

  @override
  String get fareTierCommunity => 'Wetin people dey pay';

  @override
  String get fareTierProfile => 'Driver price';

  @override
  String get fareTierEstimate => 'Estimate — agree price';

  @override
  String pricingRiderOffer(String amount) {
    return 'Passenger offer $amount';
  }

  @override
  String get pricingLapsed =>
      'No agreement — passenger fit choose another motor';

  @override
  String get pricingOutOfRange => 'Motor don pass — price talk don close';

  @override
  String get pricingDeclined => 'You no gree this fare';

  @override
  String get pricingDismiss => 'Back to map';

  @override
  String get manifestTitle => 'Trips wey dey on';

  @override
  String get manifestEmpty => 'No passenger accept yet';

  @override
  String manifestBoarding(String stage) {
    return 'Boarding: $stage';
  }

  @override
  String manifestStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get manifestMarkBoarded => 'Don enter';

  @override
  String manifestOpen(int count) {
    return 'Trips wey dey on ($count)';
  }

  @override
  String get activeTripStart => 'Start trip';

  @override
  String get activeTripComplete => 'Finish trip';

  @override
  String activeTripBoardAlight(String board, String alight) {
    return '$board → $alight';
  }

  @override
  String activeTripWalkEta(int minutes) {
    return '$minutes min waka';
  }

  @override
  String get activeTripStalledCaption => 'e no dey come near';

  @override
  String get activeTripRelease => 'Release';

  @override
  String get activeTripReport => 'Report';

  @override
  String get sosTeamAlerted => 'Ready to call 112';

  @override
  String get sosSharingDetails => 'Share your live location with your people';

  @override
  String sosCallEmergency(String number) {
    return 'Call $number';
  }

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
  String get reportIncidentSubmit => 'Send report';

  @override
  String get reportIncidentPickCategory => 'Pick one category';

  @override
  String get reportIncidentDescriptionRequired => 'Add small explanation';

  @override
  String get reportIncidentSubmitted => 'Report don save for this phone';

  @override
  String get incidentCategorySafety => 'Safety worry';

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
  String get accountProfileHeading => 'PROFILE';

  @override
  String get accountProfileUnknown => 'Driver';

  @override
  String get accountVerified => 'Verified';

  @override
  String get accountUnverified => 'Never verify';

  @override
  String get accountVehicleHeading => 'MOTOR';

  @override
  String get accountVehicleActiveHint => 'Motor wey dey work';

  @override
  String get accountVehicleEmpty => 'Add your motor';

  @override
  String get accountVehicleSwitchHint => 'Contact support to change motor';

  @override
  String get accountDocumentsHeading => 'PAPERS';

  @override
  String get accountDocumentsAllApproved => 'All papers don approve';

  @override
  String get accountDocumentsPending => 'Papers dey wait for check';

  @override
  String get accountDocumentsNeedsAttention => 'Some papers need attention';

  @override
  String get accountDocumentsIncomplete => 'Papers never complete';

  @override
  String get accountDocumentsUnknown => 'Paper status no dey';

  @override
  String get accountPayoutHeading => 'PAYOUT';

  @override
  String get accountPayoutBank => 'Payout bank';

  @override
  String accountPayoutConfigured(String last4) {
    return 'Bank wey end with $last4';
  }

  @override
  String get accountPayoutNotConfigured => 'Set your payout bank';

  @override
  String get accountPreferencesHeading => 'WETIN YOU LIKE';

  @override
  String get accountCityLabel => 'Operating city';

  @override
  String get accountCityHint => 'Map, parks and demand go use dis city';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountLanguageValue => 'Naija Pidgin';

  @override
  String get accountSafetyHeading => 'SAFETY';

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
  String get homeLedgerBlockedTitle => 'Matching don pause';

  @override
  String homeLedgerBlockedBalance(String amount) {
    return 'Balance $amount';
  }

  @override
  String homeLedgerBlockedThreshold(String amount) {
    return 'Block limit $amount';
  }

  @override
  String get settleCta => 'Settle';

  @override
  String get settleTitle => 'Settle balance';

  @override
  String settleCurrentBalance(String amount) {
    return 'Balance now: $amount';
  }

  @override
  String get settleAmountLabel => 'Amount to pay';

  @override
  String get settleChannelBank => 'Bank transfer';

  @override
  String get settleChannelUssd => 'USSD';

  @override
  String get settleChannelCard => 'Card';

  @override
  String get settleChannelAgent => 'Pay agent';

  @override
  String get settleAgentCodeTitle => 'Your agent code';

  @override
  String settleAgentExpires(String time) {
    return 'E go expire $time';
  }

  @override
  String get settleNearbyAgentsTitle => 'Agents wey near';

  @override
  String settleNearbyAgentDistance(int distance) {
    return '$distance m away';
  }

  @override
  String get settleDone => 'Done';

  @override
  String get earningsLedgerSection => 'Balance activity';

  @override
  String get earningsTripsSection => 'TRIPS';

  @override
  String get earningsLedgerEmpty => 'No record yet';

  @override
  String get earningsTripsCaption =>
      'Cash wey you collect direct — e no join your Along balance';

  @override
  String get earningsTripsEmpty => 'No cash trip finish today';

  @override
  String earningsTripsTodaySummary(int count, String amount) {
    return '$count trips today · $amount collected';
  }

  @override
  String get standingLink => 'Standing';

  @override
  String get standingTitle => 'Your standing';

  @override
  String standingBalanceAt(String amount) {
    return 'Balance when e change: $amount';
  }

  @override
  String standingBlockThreshold(String amount) {
    return 'Matching go pause if you owe pass $amount';
  }

  @override
  String standingGraceDeadline(String date) {
    return 'Grace deadline: $date';
  }

  @override
  String get standingRestoreHint =>
      'Pay pass the warn limit to get good standing back';

  @override
  String get standingHistoryTitle => 'HISTORY';

  @override
  String get standingHistoryEmpty => 'No standing change yet';

  @override
  String get guarantorLink => 'Add guarantor';

  @override
  String get guarantorTitle => 'Guarantor';

  @override
  String get guarantorExplainer =>
      'We go tell your guarantor if your balance never settle after grace time. We no go ever remove money from am.';

  @override
  String get guarantorTypeDriver => 'Fellow driver';

  @override
  String get guarantorTypeOwner => 'Motor owner';

  @override
  String get guarantorNameLabel => 'Full name';

  @override
  String get guarantorPhoneLabel => 'Phone number';

  @override
  String get guarantorSubmit => 'Add guarantor';

  @override
  String get guarantorSuccess => 'Guarantor don add — dem go get confirm link';

  @override
  String get extendTripTitle => 'Extend trip';

  @override
  String get extendTripSearchHint => 'Where now?';

  @override
  String extendTripDestination(String destination) {
    return 'Dey continue go $destination';
  }

  @override
  String get extendTripPropose => 'Propose to passenger';

  @override
  String get incomingExtensionTitle => 'Extension request';

  @override
  String get incomingExtensionDecline => 'No gree';

  @override
  String get incomingExtensionAccept => 'Accept';

  @override
  String incomingRiderExtensionBody(String destination, String delta) {
    return 'Passenger wan continue go $destination for +$delta';
  }

  @override
  String get tripCompleteTitle => 'Trip don finish';

  @override
  String tripCompleteFareLine(String amount) {
    return 'Fare $amount — passenger go pay you cash';
  }

  @override
  String tripCompleteAlongFeeLine(String amount) {
    return 'Along fee $amount — e don enter your balance';
  }

  @override
  String tripCompleteNewBalance(String amount) {
    return 'New balance $amount';
  }

  @override
  String get tripCompleteCashQuestion => 'You don collect the cash?';

  @override
  String get tripCompleteYes => 'Yes';

  @override
  String get tripCompleteDifferent => 'Different amount';

  @override
  String get tripCompleteDifferentPrompt => 'How much you collect?';

  @override
  String get tripCompleteRateTitle => 'Rate your passenger';

  @override
  String get tripCompleteDone => 'Done';

  @override
  String get requestPayment => 'Request payment';

  @override
  String tripCompleteDigitalLine(String amount) {
    return 'Paid online · $amount don enter your bank';
  }

  @override
  String tripCompleteDigitalFeeLine(String amount) {
    return 'Along fee $amount don comot already';
  }

  @override
  String get myQrTitle => 'My QR code';

  @override
  String get myQrAccountSubtitle => 'Share your code for online payment';

  @override
  String get myQrDigitalDisabledBanner =>
      'Online payment never start — your QR na only for setup and test.';

  @override
  String get myQrPayoutPrompt => 'Set payout bank';

  @override
  String get myQrPayoutHint =>
      'Add your bank account so passengers fit pay you online. Along no dey hold your money.';

  @override
  String get myQrSetupPayout => 'Set payout bank';

  @override
  String get myQrPayoutComingSoon =>
      'Payout setup go open from Account once online payment start.';

  @override
  String get myQrShare => 'Share as picture';

  @override
  String get myQrOrderSticker => 'Order sticker';

  @override
  String myQrStickerStatus(String status) {
    return 'Sticker request: $status';
  }

  @override
  String get myQrVerifySticker => 'Check my sticker';

  @override
  String get myQrVerifyMatch => 'Sticker match your code and plate';

  @override
  String get myQrVerifyMismatch => 'This sticker no match your account';

  @override
  String get myQrVerifyInvalid => 'No be Along QR code';

  @override
  String get myQrVerifyTimeout => 'Scan time don finish — try again';

  @override
  String get myQrPauseDigital => 'Pause online payment';

  @override
  String get myQrPauseDigitalHint =>
      'Passengers go see cash only while e pause';

  @override
  String get myQrPausedBanner =>
      'Online payment don pause — passengers see cash only';

  @override
  String get myQrRotate => 'Change code';

  @override
  String get myQrRotateConfirmTitle => 'Change QR code?';

  @override
  String get myQrRotateConfirmBody =>
      'Your stickers now go stop to work. Ops go print new ones.';

  @override
  String get myQrRotateCancel => 'Cancel';

  @override
  String get myQrRotateConfirm => 'Change';

  @override
  String get paymentRequestTitle => 'Payment request';

  @override
  String paymentRequestForRider(String riderName) {
    return 'For $riderName';
  }

  @override
  String paymentRequestCountdown(int seconds) {
    return 'E go expire in ${seconds}s';
  }

  @override
  String get paymentRequestWaiting => 'Dey wait for payment…';

  @override
  String paymentRequestPaidLine(String amount) {
    return 'Paid $amount ✓';
  }

  @override
  String paymentRequestBankLine(String amount) {
    return '$amount to your bank';
  }

  @override
  String get paymentRequestDone => 'Done';

  @override
  String get paymentRequestExpired => 'This QR don expire — make new one';

  @override
  String get paymentRequestDigitalDisabled => 'Online payment never start';

  @override
  String get paymentRequestTokenError =>
      'We no fit confirm payment QR — try again';

  @override
  String get earningsDigitalSection => 'Digital payments';

  @override
  String get earningsDigitalCaption =>
      'Paid straight to your bank — e no join your Along balance';

  @override
  String get earningsDigitalEmpty => 'No online payment yet';

  @override
  String earningsDigitalRow(String source) {
    return 'Online · $source';
  }

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
  String get buildMyDayTitle => 'Build my day';

  @override
  String get buildMyDayStart => 'Save and use this day';

  @override
  String get buildMyDayCorridor => 'Corridor';

  @override
  String get saveLayout => 'Save layout';

  @override
  String get layoutName => 'Layout name';

  @override
  String get addRow => 'Add row';

  @override
  String get addSeat => 'Add seat';

  @override
  String get removeRow => 'Remove row';

  @override
  String get overCapacityNote =>
      'This one pass the usual seat count. We don save am and flag am for check.';

  @override
  String get seatMapTitle => 'Seat map';

  @override
  String get seatFull => 'Don full';

  @override
  String get seatEmpty => 'Empty';

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
  String get rideRulesHeading => 'Ride rules';

  @override
  String get customRuleHint => 'Rule title';

  @override
  String get customRuleBody => 'Wetin passengers suppose know';

  @override
  String get customRuleSave => 'Add my rule';

  @override
  String get holdMinutes => 'Hold minutes';

  @override
  String get capMax => 'Seat limit';

  @override
  String get deleteRule => 'Remove rule';

  @override
  String get dayNeedsCorridor => 'Choose corridor';

  @override
  String get seatStale => 'Seat map don pass one minute';

  @override
  String get shiftStart => 'Work start';

  @override
  String get shiftEnd => 'Work end';

  @override
  String get homeLabel => 'Stop wey dey go house';

  @override
  String get walkExtension => 'Extra hold minutes for passenger wey dey waka';

  @override
  String get seatLuggage => 'load';

  @override
  String get voiceCommandHint => 'Talk accept, full, or back left seat free';

  @override
  String get conductorOpen => 'Conductor code';

  @override
  String get conductorTitle => 'Conductor';

  @override
  String get conductorCode => 'Code from driver';

  @override
  String get conductorJoin => 'Open seat map';

  @override
  String get ghostSeatTitle => 'Seat still taken after drop?';

  @override
  String get ghostSeatFree => 'Free am';

  @override
  String freeSeatCount(int count) {
    return '$count free';
  }

  @override
  String get restTitle => 'Rest';

  @override
  String get restDriveMinutes => 'Drive minutes before rest';

  @override
  String get restMinutes => 'Rest minutes';

  @override
  String get restSave => 'Save';

  @override
  String get restStart => 'Start rest';

  @override
  String get restFinish => 'Finish rest';

  @override
  String get restPriority =>
      'You go first for jobs until your rest time finish';

  @override
  String get marketplaceTitle => 'Today';

  @override
  String get marketplaceGoal => 'Today target';

  @override
  String get marketplaceEarned => 'Don collect';

  @override
  String get marketplaceTypical => 'Usual seat fare';

  @override
  String marketplaceSeats(int count) {
    return '$count seats remain';
  }

  @override
  String get marketplaceGoalMet => 'Target don reach';

  @override
  String get marketplaceSave => 'Save';

  @override
  String get marketplaceCorridor => 'Corridor wey you dey watch';

  @override
  String get marketplaceRequests => 'Requests';

  @override
  String get marketplaceAddCorridor => 'Add am';

  @override
  String marketplaceTip(String corridor) {
    return 'Join queue go $corridor';
  }

  @override
  String get marketplaceFuel => 'Price per litre';

  @override
  String get marketplaceFuelLabel => 'Pump';

  @override
  String get marketplaceFuelSave => 'Save price';

  @override
  String get marketplaceEventName => 'Event name';

  @override
  String get marketplaceEventHours => 'Hours wey the point go open';

  @override
  String get marketplaceEventSave => 'Open the point';

  @override
  String activeTripMessageRider(String name) {
    return 'Send message give $name';
  }

  @override
  String get activeTripMessageRiderUnknown => 'Send message give rider';

  @override
  String get tripEtaCalculating => 'We dey calculate…';

  @override
  String tripEtaPickup(String label) {
    return 'Pickup $label';
  }

  @override
  String get drivePhasePickup => 'Pickup';

  @override
  String get drivePhaseBoard => 'Enter';

  @override
  String get drivePhaseDrop => 'Drop';

  @override
  String activeTripPickUpTitle(String name) {
    return 'Carry $name';
  }

  @override
  String activeTripOnBoardTitle(String name) {
    return '$name don enter';
  }

  @override
  String activeTripDropTitle(String name) {
    return 'Drop $name';
  }

  @override
  String get activeTripRiderFallback => 'your passenger';

  @override
  String get activeTripBoardNaMe => 'Enter with Na Me';

  @override
  String get activeTripEnterPin => 'Put pickup PIN';

  @override
  String get activeTripPinShort => 'PIN';

  @override
  String get activeTripMessageShort => 'Message';

  @override
  String get activeTripSeatsShort => 'Seats';

  @override
  String get activeTripExtendShort => 'Extend';

  @override
  String get activeTripReportShort => 'Report';

  @override
  String get activeTripFareLabel => 'Passenger go pay';

  @override
  String activeTripFeeCaption(String amount, String percent) {
    return 'Along fee $amount ($percent%)';
  }

  @override
  String incomingAcceptFare(String amount) {
    return 'Accept · $amount';
  }

  @override
  String incomingFareCaption(String tierLabel) {
    return 'Passenger go pay · $tierLabel';
  }

  @override
  String get homeOfflineTitle => 'You no dey online';

  @override
  String get homeOnlineTitle => 'You dey online';

  @override
  String get homeOfflineHint => 'Go online make request dey come near you.';

  @override
  String get homeOnlineHint => 'Request go show here. Accept with one tap.';

  @override
  String get homeGoOnline => 'GO';

  @override
  String get homeGoOffline => 'Comot online';

  @override
  String get homeModeAtPark => 'For park';

  @override
  String get homeModeRoaming => 'Dey waka';

  @override
  String get homeModeFull => 'Don full';

  @override
  String homeTodayEarned(String amount) {
    return 'Today · $amount';
  }

  @override
  String homeTodayTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
      zero: 'No trip yet',
    );
    return '$_temp0';
  }

  @override
  String get homeShortcutsTitle => 'Your day';

  @override
  String get homeDirectionShortOnRoute => 'For my route';

  @override
  String get homeDirectionShortNone => 'Any side';

  @override
  String get homeTileDemand => 'Demand';

  @override
  String get tripCompleteCashHero => 'Collect cash';

  @override
  String get tripCompleteRowFare => 'Fare';

  @override
  String get tripCompleteRowFee => 'Along fee (to balance)';

  @override
  String get tripCompleteRowBalance => 'New balance';

  @override
  String tripCompleteYesAmount(String amount) {
    return 'Yes, I collect $amount';
  }

  @override
  String get settleSubtitle => 'Your Along account';

  @override
  String get settleOwedLabel => 'You dey owe Along';

  @override
  String get settleCreditLabel => 'Your balance';

  @override
  String settleThreshold(String amount) {
    return 'Matching go pause if you owe pass $amount';
  }

  @override
  String get settleMethodTitle => 'Pay with';

  @override
  String settleSubmit(String amount) {
    return 'Settle $amount';
  }

  @override
  String get settleChannelBankDetail => 'Transfer go your Along account';

  @override
  String get settleChannelUssdDetail => 'Dial code, no need data';

  @override
  String get settleChannelCardDetail => 'ATM card';

  @override
  String get settleChannelAgentDetail => 'Pay cash for Along agent';

  @override
  String earningsBalanceAfter(String amount) {
    return 'Balance $amount';
  }

  @override
  String get ratingTagSafeDriving => 'Safe driving';

  @override
  String get ratingTagFairFare => 'Fair fare';

  @override
  String get ratingTagCleanVehicle => 'Clean motor';

  @override
  String get ratingTagPolite => 'Get respect';

  @override
  String get ratingTagOnTime => 'On time';

  @override
  String get ratingTagReady => 'Ready for pickup';

  @override
  String get ratingTagPaidPromptly => 'Pay sharp sharp';

  @override
  String get guarantorWhoTitle => 'Who go stand for you';

  @override
  String get guarantorDetailsTitle => 'Their details';

  @override
  String get seatToolsTitle => 'Quick tools';

  @override
  String get seatBoardEmptyBody =>
      'Plan your day to set your motor seats. Then you fit mark who dey inside for here.';

  @override
  String get mpGoalSection => 'Today target';

  @override
  String get mpDemandSection => 'Where passengers dey';

  @override
  String get mpFuelSection => 'Fuel price';

  @override
  String get mpEventSection => 'Events near you';

  @override
  String seatBoardSubtitle(int count) {
    return '$count free · touch seat to change am';
  }

  @override
  String get mpSubtitle => 'Set target, see where passengers dey, share tips.';

  @override
  String get mpGoalEmpty => 'Set target to see how many seats remain';

  @override
  String get mpMoreSection => 'Share with drivers';

  @override
  String get mpFuelDetail => 'Today pump price near you';

  @override
  String get mpEventDetail => 'Open pickup point for crowd';

  @override
  String get restSubtitle =>
      'Rest well after long driving. Full rest go move you up for queue.';

  @override
  String get restStatusDriving => 'For road';

  @override
  String restStatusResting(String time) {
    return 'Resting since $time';
  }

  @override
  String restPlan(int rest, int drive) {
    return '$rest min rest every $drive min';
  }

  @override
  String get restPlanEmpty => 'Set how long you go drive before rest';

  @override
  String get restRhythmSection => 'Your rhythm';

  @override
  String get conductorSubtitle => 'Help driver keep seats correct.';

  @override
  String get conductorHowTo =>
      'Driver go open Seat map → Conductor code come read the 8-character code give you.';

  @override
  String get restDriveShort => 'Drive (min)';

  @override
  String get restBreakShort => 'Rest (min)';

  @override
  String get mpTargetShort => 'Target';

  @override
  String get mpEarnedShort => 'Don make';

  @override
  String get daySubtitle =>
      'Pick where you go work, set your seats and the rules passengers go see.';

  @override
  String daySeatsCount(int count) {
    return '$count seats';
  }

  @override
  String get dayRouteOptional => 'Route (if you want)';

  @override
  String get dayHoursSection => 'Your hours';

  @override
  String get daySeatsSection => 'Seats';

  @override
  String get dayRemove => 'Remove';

  @override
  String get dayAddRule => 'Add rule';

  @override
  String get dayRuleRow => 'E concern';

  @override
  String dayRowN(int n) {
    return 'Row $n';
  }

  @override
  String get dayRuleDetails => 'Rule details';

  @override
  String get dayRuleDetailsBody => 'Hold time, extra waka, seat limit, wording';

  @override
  String get dayCustomRule => 'Write your own rule';

  @override
  String get dayCustomRuleBody => 'Passengers go see am before dem book';

  @override
  String get howItWorks => 'How e dey work';

  @override
  String get conductorStep1 => 'Collect the code';

  @override
  String get conductorStep1Body => 'Driver go share am from im seat map';

  @override
  String get conductorStep2 => 'Join the bus';

  @override
  String get conductorStep2Body => 'You go see the same seats live';

  @override
  String get conductorStep3 => 'Update seats';

  @override
  String get conductorStep3Body => 'Tap seat when passenger enter or comot';

  @override
  String get seatEmptyStep1 => 'Pick your motor';

  @override
  String get seatEmptyStep1Body => 'We go draw im seats';

  @override
  String get seatEmptyStep2 => 'Choose corridor';

  @override
  String get seatEmptyStep2Body =>
      'Passengers for there go see your free seats';

  @override
  String get seatEmptyStep3 => 'Fill seats as you dey go';

  @override
  String get seatEmptyStep3Body => 'Tap seat to mark am taken or free';

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
  String connNeedsConnection(int count) {
    return 'No network · $count to do again when network dey';
  }

  @override
  String connOfflineMixed(int queued, int needs) {
    return 'No network · $queued go send · $needs to do again';
  }

  @override
  String get homeOnlineNoSignal => 'Online · no network';

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
  String get authStory1H => 'Drive with Along.';

  @override
  String get authStory1B => 'Passengers go find you for park and for road.';

  @override
  String get authStory2H => 'Your price, your route.';

  @override
  String get authStory2B =>
      'Set price for each stop and collect your money sharp sharp.';

  @override
  String get authStory3H => 'Safe for every trip.';

  @override
  String get authStory3B => 'Verified passengers and SOS just one hold away.';

  @override
  String get permTitle => 'Ready to drive';

  @override
  String get permLocationBody =>
      'Show passengers where you dey when you dey online.';

  @override
  String get permNotifBody => 'Hear about new requests and payment.';

  @override
  String get permCameraBody => 'Snap your documents and scan QR code.';
}
