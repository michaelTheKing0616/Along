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
  String get phoneEntrySubtitle =>
      'We text a code to this number so your day stays yours.';

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
  String get errorAuthNotConfigured =>
      'This build is not connected to Along. Rebuild the staging APK with env/staging.json.';

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
  String get incomingRequestRoamingPickup => 'Rider location';

  @override
  String get incomingRequestRoamingPickupMeta => 'Cell hail — meet at pin';

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
    return 'Rider pays $amount · $tierLabel';
  }

  @override
  String incomingRequestAlongFee(String amount, String percent) {
    return 'Along fee $amount · $percent%, added at drop-off';
  }

  @override
  String get incomingRequestLoadDefault => 'Passenger flagged load';

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
  String get incomingRequestDecline => 'Decline';

  @override
  String get declineReasonTitle => 'Why are you declining?';

  @override
  String get declineReasonNoRoomForLoad => 'No room for load';

  @override
  String get declineReasonTooFar => 'Too far';

  @override
  String get declineReasonEndingShift => 'Ending shift';

  @override
  String get declineReasonOther => 'Other';

  @override
  String get fareTierStandard => 'Standard fare';

  @override
  String get fareTierCommunity => 'Community fare';

  @override
  String get fareTierProfile => 'Driver price';

  @override
  String get fareTierEstimate => 'Estimate — agree price';

  @override
  String pricingRiderOffer(String amount) {
    return 'Rider offered $amount';
  }

  @override
  String get pricingLapsed => 'No agreement — rider may choose another vehicle';

  @override
  String get pricingOutOfRange => 'Vehicle has passed — negotiation closed';

  @override
  String get pricingDeclined => 'You declined this fare';

  @override
  String get pricingDismiss => 'Back to map';

  @override
  String get manifestTitle => 'Active trips';

  @override
  String get manifestEmpty => 'No accepted riders yet';

  @override
  String manifestBoarding(String stage) {
    return 'Boarding: $stage';
  }

  @override
  String manifestStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get manifestMarkBoarded => 'Boarded';

  @override
  String manifestOpen(int count) {
    return 'Active trips ($count)';
  }

  @override
  String get activeTripStart => 'Start trip';

  @override
  String get activeTripComplete => 'Complete trip';

  @override
  String activeTripBoardAlight(String board, String alight) {
    return '$board → $alight';
  }

  @override
  String activeTripWalkEta(int minutes) {
    return '$minutes min walk';
  }

  @override
  String get activeTripStalledCaption => 'not moving closer';

  @override
  String get activeTripRelease => 'Release';

  @override
  String get activeTripReport => 'Report';

  @override
  String get sosTeamAlerted => 'Ready to call 112';

  @override
  String get sosSharingDetails => 'Share your live location with your contacts';

  @override
  String sosCallEmergency(String number) {
    return 'Call $number';
  }

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
  String get incidentCategorySafety => 'Safety concern';

  @override
  String get incidentCategoryFareDispute => 'Fare dispute';

  @override
  String get incidentCategoryVehicleQuality => 'Vehicle quality';

  @override
  String get incidentCategoryDriverBehavior => 'Driver behavior';

  @override
  String get incidentCategoryLostItem => 'Lost item';

  @override
  String get incidentCategoryOther => 'Other';

  @override
  String get accountProfileHeading => 'PROFILE';

  @override
  String get accountProfileUnknown => 'Driver';

  @override
  String get accountVerified => 'Verified';

  @override
  String get accountUnverified => 'Unverified';

  @override
  String get accountVehicleHeading => 'VEHICLE';

  @override
  String get accountVehicleActiveHint => 'Active vehicle';

  @override
  String get accountVehicleEmpty => 'Add your vehicle';

  @override
  String get accountVehicleSwitchHint =>
      'Contact support to switch active vehicle';

  @override
  String get accountDocumentsHeading => 'DOCUMENTS';

  @override
  String get accountDocumentsAllApproved => 'All documents approved';

  @override
  String get accountDocumentsPending => 'Documents pending review';

  @override
  String get accountDocumentsNeedsAttention => 'Some documents need attention';

  @override
  String get accountDocumentsIncomplete => 'Documents incomplete';

  @override
  String get accountDocumentsUnknown => 'Document status unavailable';

  @override
  String get accountPayoutHeading => 'PAYOUT';

  @override
  String get accountPayoutBank => 'Payout bank';

  @override
  String accountPayoutConfigured(String last4) {
    return 'Bank ending $last4';
  }

  @override
  String get accountPayoutNotConfigured => 'Set up your payout bank';

  @override
  String get accountPreferencesHeading => 'PREFERENCES';

  @override
  String get accountCityLabel => 'Operating city';

  @override
  String get accountCityHint => 'Map, parks, and demand use this city';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountLanguageValue => 'English';

  @override
  String get accountSafetyHeading => 'SAFETY';

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
  String get homeLedgerBlockedTitle => 'Matching paused';

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
    return 'Current balance: $amount';
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
  String get settleChannelAgent => 'Pay an agent';

  @override
  String get settleAgentCodeTitle => 'Your agent code';

  @override
  String settleAgentExpires(String time) {
    return 'Expires $time';
  }

  @override
  String get settleNearbyAgentsTitle => 'Nearby agents';

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
  String get earningsLedgerEmpty => 'No ledger entries yet';

  @override
  String get earningsTripsCaption =>
      'Cash you collected directly — not part of your Along balance';

  @override
  String get earningsTripsEmpty => 'No completed cash trips today';

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
    return 'Balance at transition: $amount';
  }

  @override
  String standingBlockThreshold(String amount) {
    return 'Matching pauses if you owe more than $amount';
  }

  @override
  String standingGraceDeadline(String date) {
    return 'Grace deadline: $date';
  }

  @override
  String get standingRestoreHint =>
      'Settle above the warn threshold to restore good standing';

  @override
  String get standingHistoryTitle => 'HISTORY';

  @override
  String get standingHistoryEmpty => 'No standing changes yet';

  @override
  String get guarantorLink => 'Add a guarantor';

  @override
  String get guarantorTitle => 'Guarantor';

  @override
  String get guarantorExplainer =>
      'Your guarantor is notified if your balance stays unsettled after the grace period. Nothing is ever deducted from them.';

  @override
  String get guarantorTypeDriver => 'Fellow driver';

  @override
  String get guarantorTypeOwner => 'Vehicle owner';

  @override
  String get guarantorNameLabel => 'Full name';

  @override
  String get guarantorPhoneLabel => 'Phone number';

  @override
  String get guarantorSubmit => 'Add guarantor';

  @override
  String get guarantorSuccess =>
      'Guarantor added — they will receive an acknowledgement link';

  @override
  String get extendTripTitle => 'Extend trip';

  @override
  String get extendTripSearchHint => 'Where to now?';

  @override
  String extendTripDestination(String destination) {
    return 'Continuing to $destination';
  }

  @override
  String get extendTripPropose => 'Propose to rider';

  @override
  String get incomingExtensionTitle => 'Extension request';

  @override
  String get incomingExtensionDecline => 'Decline';

  @override
  String get incomingExtensionAccept => 'Accept';

  @override
  String incomingRiderExtensionBody(String destination, String delta) {
    return 'Rider proposes continuing to $destination for +$delta';
  }

  @override
  String get tripCompleteTitle => 'Trip complete';

  @override
  String tripCompleteFareLine(String amount) {
    return 'Fare $amount — rider pays you in cash';
  }

  @override
  String tripCompleteAlongFeeLine(String amount) {
    return 'Along fee $amount — posted to your balance';
  }

  @override
  String tripCompleteNewBalance(String amount) {
    return 'New balance $amount';
  }

  @override
  String get tripCompleteCashQuestion => 'Confirm cash received?';

  @override
  String get tripCompleteYes => 'Yes';

  @override
  String get tripCompleteDifferent => 'Different amount';

  @override
  String get tripCompleteDifferentPrompt => 'How much did you receive?';

  @override
  String get tripCompleteRateTitle => 'Rate your rider';

  @override
  String get tripCompleteDone => 'Done';

  @override
  String get requestPayment => 'Request payment';

  @override
  String tripCompleteDigitalLine(String amount) {
    return 'Paid digitally · $amount sent to your bank';
  }

  @override
  String tripCompleteDigitalFeeLine(String amount) {
    return 'Along fee $amount already deducted';
  }

  @override
  String get myQrTitle => 'My QR code';

  @override
  String get myQrAccountSubtitle => 'Share your code for digital payments';

  @override
  String get myQrDigitalDisabledBanner =>
      'Digital payments are not live yet — your QR is for setup and testing only.';

  @override
  String get myQrPayoutPrompt => 'Set up payout bank';

  @override
  String get myQrPayoutHint =>
      'Add your bank account so riders can pay you digitally. Along never holds your money.';

  @override
  String get myQrSetupPayout => 'Set up payout bank';

  @override
  String get myQrPayoutComingSoon =>
      'Payout setup opens from Account once digital payments go live.';

  @override
  String get myQrShare => 'Share as image';

  @override
  String get myQrOrderSticker => 'Order printed sticker';

  @override
  String myQrStickerStatus(String status) {
    return 'Sticker request: $status';
  }

  @override
  String get myQrVerifySticker => 'Verify my sticker';

  @override
  String get myQrVerifyMatch => 'Sticker matches your code and plate';

  @override
  String get myQrVerifyMismatch => 'This sticker does not match your account';

  @override
  String get myQrVerifyInvalid => 'Not a valid Along QR code';

  @override
  String get myQrVerifyTimeout => 'Scan timed out — try again';

  @override
  String get myQrPauseDigital => 'Pause digital payments';

  @override
  String get myQrPauseDigitalHint => 'Riders will see cash only while paused';

  @override
  String get myQrPausedBanner =>
      'Digital payments are paused — riders see cash only';

  @override
  String get myQrRotate => 'Rotate code';

  @override
  String get myQrRotateConfirmTitle => 'Rotate QR code?';

  @override
  String get myQrRotateConfirmBody =>
      'Your current stickers will stop working. Ops will need to print new ones.';

  @override
  String get myQrRotateCancel => 'Cancel';

  @override
  String get myQrRotateConfirm => 'Rotate';

  @override
  String get paymentRequestTitle => 'Payment request';

  @override
  String paymentRequestForRider(String riderName) {
    return 'For $riderName';
  }

  @override
  String paymentRequestCountdown(int seconds) {
    return 'Expires in ${seconds}s';
  }

  @override
  String get paymentRequestWaiting => 'Waiting for payment…';

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
  String get paymentRequestExpired => 'This QR has expired — create a new one';

  @override
  String get paymentRequestDigitalDisabled =>
      'Digital payments are not enabled yet';

  @override
  String get paymentRequestTokenError =>
      'Could not verify payment QR — try again';

  @override
  String get earningsDigitalSection => 'Digital payments';

  @override
  String get earningsDigitalCaption =>
      'Paid straight to your bank — not part of your Along balance';

  @override
  String get earningsDigitalEmpty => 'No digital payments yet';

  @override
  String earningsDigitalRow(String source) {
    return 'Digital · $source';
  }

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
      'This is over the usual seat count. It is saved and flagged for review.';

  @override
  String get seatMapTitle => 'Seat map';

  @override
  String get seatFull => 'Full';

  @override
  String get seatEmpty => 'Empty';

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
  String get rideRulesHeading => 'Ride rules';

  @override
  String get customRuleHint => 'Rule title';

  @override
  String get customRuleBody => 'What riders should know';

  @override
  String get customRuleSave => 'Add my rule';

  @override
  String get holdMinutes => 'Hold minutes';

  @override
  String get capMax => 'Seat cap';

  @override
  String get deleteRule => 'Remove rule';

  @override
  String get dayNeedsCorridor => 'Choose a corridor';

  @override
  String get seatStale => 'Seat map is more than a minute old';

  @override
  String get shiftStart => 'Shift starts';

  @override
  String get shiftEnd => 'Shift ends';

  @override
  String get homeLabel => 'Home-bound stop';

  @override
  String get walkExtension => 'Extra hold minutes for a walking rider';

  @override
  String get seatLuggage => 'luggage';

  @override
  String get voiceCommandHint => 'Say accept, full, or seat back left free';

  @override
  String get conductorOpen => 'Conductor code';

  @override
  String get conductorTitle => 'Conductor';

  @override
  String get conductorCode => 'Code from the driver';

  @override
  String get conductorJoin => 'Open the seat map';

  @override
  String get ghostSeatTitle => 'Still taken after the drop?';

  @override
  String get ghostSeatFree => 'Free it';

  @override
  String freeSeatCount(int count) {
    return '$count free';
  }

  @override
  String get restTitle => 'Rest';

  @override
  String get restDriveMinutes => 'Drive minutes before a rest';

  @override
  String get restMinutes => 'Rest minutes';

  @override
  String get restSave => 'Save';

  @override
  String get restStart => 'Start rest';

  @override
  String get restFinish => 'Finish rest';

  @override
  String get restPriority => 'Priority dispatch until your rest window ends';

  @override
  String get marketplaceTitle => 'Today';

  @override
  String get marketplaceGoal => 'Daily target';

  @override
  String get marketplaceEarned => 'Already earned';

  @override
  String get marketplaceTypical => 'Usual seat fare';

  @override
  String marketplaceSeats(int count) {
    return '$count seats to go';
  }

  @override
  String get marketplaceGoalMet => 'Target reached';

  @override
  String get marketplaceSave => 'Save';

  @override
  String get marketplaceCorridor => 'Corridor you watch';

  @override
  String get marketplaceRequests => 'Requests';

  @override
  String get marketplaceAddCorridor => 'Add';

  @override
  String marketplaceTip(String corridor) {
    return 'Queue toward $corridor';
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
  String get marketplaceEventHours => 'Hours the point stays open';

  @override
  String get marketplaceEventSave => 'Open the point';

  @override
  String activeTripMessageRider(String name) {
    return 'Message $name';
  }

  @override
  String get activeTripMessageRiderUnknown => 'Message rider';

  @override
  String get tripEtaCalculating => 'Calculating…';

  @override
  String tripEtaPickup(String label) {
    return 'Pickup $label';
  }

  @override
  String get drivePhasePickup => 'Pickup';

  @override
  String get drivePhaseBoard => 'Board';

  @override
  String get drivePhaseDrop => 'Drop';

  @override
  String activeTripPickUpTitle(String name) {
    return 'Pick up $name';
  }

  @override
  String activeTripOnBoardTitle(String name) {
    return '$name is on board';
  }

  @override
  String activeTripDropTitle(String name) {
    return 'Drop $name';
  }

  @override
  String get activeTripRiderFallback => 'your rider';

  @override
  String get activeTripBoardNaMe => 'Board with Na Me';

  @override
  String get activeTripEnterPin => 'Enter pickup PIN';

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
  String get activeTripFareLabel => 'Rider pays';

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
    return 'Rider pays · $tierLabel';
  }

  @override
  String get homeOfflineTitle => 'You\'re offline';

  @override
  String get homeOnlineTitle => 'You\'re online';

  @override
  String get homeOfflineHint => 'Go online to get requests near you.';

  @override
  String get homeOnlineHint => 'Requests pop up here. Accept in one tap.';

  @override
  String get homeGoOnline => 'GO';

  @override
  String get homeGoOffline => 'Go offline';

  @override
  String get homeModeAtPark => 'At park';

  @override
  String get homeModeRoaming => 'Roaming';

  @override
  String get homeModeFull => 'Full';

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
      zero: 'No trips yet',
    );
    return '$_temp0';
  }

  @override
  String get homeShortcutsTitle => 'Your day';

  @override
  String get homeDirectionShortOnRoute => 'On my route';

  @override
  String get homeDirectionShortNone => 'Any direction';

  @override
  String get homeTileDemand => 'Demand';

  @override
  String get tripCompleteCashHero => 'Collect in cash';

  @override
  String get tripCompleteRowFare => 'Fare';

  @override
  String get tripCompleteRowFee => 'Along fee (to balance)';

  @override
  String get tripCompleteRowBalance => 'New balance';

  @override
  String tripCompleteYesAmount(String amount) {
    return 'Yes, I got $amount';
  }

  @override
  String get settleSubtitle => 'Your Along account';

  @override
  String get settleOwedLabel => 'You owe Along';

  @override
  String get settleCreditLabel => 'Your balance';

  @override
  String settleThreshold(String amount) {
    return 'Matching pauses if you owe more than $amount';
  }

  @override
  String get settleMethodTitle => 'Pay with';

  @override
  String settleSubmit(String amount) {
    return 'Settle $amount';
  }

  @override
  String get settleChannelBankDetail => 'Transfer to your Along account';

  @override
  String get settleChannelUssdDetail => 'Dial a code, no data needed';

  @override
  String get settleChannelCardDetail => 'Debit card';

  @override
  String get settleChannelAgentDetail => 'Pay cash at an Along agent';

  @override
  String earningsBalanceAfter(String amount) {
    return 'Balance $amount';
  }

  @override
  String get ratingTagSafeDriving => 'Safe driving';

  @override
  String get ratingTagFairFare => 'Fair fare';

  @override
  String get ratingTagCleanVehicle => 'Clean vehicle';

  @override
  String get ratingTagPolite => 'Polite';

  @override
  String get ratingTagOnTime => 'On time';

  @override
  String get ratingTagReady => 'Ready at pickup';

  @override
  String get ratingTagPaidPromptly => 'Paid promptly';

  @override
  String get guarantorWhoTitle => 'Who vouches for you';

  @override
  String get guarantorDetailsTitle => 'Their details';

  @override
  String get seatToolsTitle => 'Quick tools';

  @override
  String get seatBoardEmptyBody =>
      'Plan your day to set up your vehicle\'s seats. Then you can mark who\'s on board here.';

  @override
  String get mpGoalSection => 'Today\'s goal';

  @override
  String get mpDemandSection => 'Where riders are';

  @override
  String get mpFuelSection => 'Fuel price';

  @override
  String get mpEventSection => 'Events nearby';

  @override
  String seatBoardSubtitle(int count) {
    return '$count free · tap a seat to switch it';
  }

  @override
  String get mpSubtitle =>
      'Set a target, see where riders are, and share local tips.';

  @override
  String get mpGoalEmpty => 'Set a target to see how many seats to go';

  @override
  String get mpMoreSection => 'Share with drivers';

  @override
  String get mpFuelDetail => 'Today\'s pump price nearby';

  @override
  String get mpEventDetail => 'Open a pickup point for a crowd';

  @override
  String get restSubtitle =>
      'Take a proper break after a long stretch. A full rest moves you up the queue.';

  @override
  String get restStatusDriving => 'On the road';

  @override
  String restStatusResting(String time) {
    return 'Resting since $time';
  }

  @override
  String restPlan(int rest, int drive) {
    return '$rest min break every $drive min';
  }

  @override
  String get restPlanEmpty => 'Set how long you drive before a break';

  @override
  String get restRhythmSection => 'Your rhythm';

  @override
  String get conductorSubtitle => 'Help the driver keep seats up to date.';

  @override
  String get conductorHowTo =>
      'The driver opens Seat map → Conductor code and reads you the 8-character code.';

  @override
  String get restDriveShort => 'Drive (min)';

  @override
  String get restBreakShort => 'Break (min)';

  @override
  String get mpTargetShort => 'Target';

  @override
  String get mpEarnedShort => 'Earned';

  @override
  String get daySubtitle =>
      'Pick where you\'ll work, set your seats and the rules riders see.';

  @override
  String daySeatsCount(int count) {
    return '$count seats';
  }

  @override
  String get dayRouteOptional => 'Route (optional)';

  @override
  String get dayHoursSection => 'Your hours';

  @override
  String get daySeatsSection => 'Seats';

  @override
  String get dayRemove => 'Remove';

  @override
  String get dayAddRule => 'Add a rule';

  @override
  String get dayRuleRow => 'Applies to';

  @override
  String dayRowN(int n) {
    return 'Row $n';
  }

  @override
  String get dayRuleDetails => 'Rule details';

  @override
  String get dayRuleDetailsBody => 'Hold time, walk extra, seat cap, wording';

  @override
  String get dayCustomRule => 'Write your own rule';

  @override
  String get dayCustomRuleBody => 'Shown to riders before they book';
}
