// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Yoruba (`yo`).
class AppLocalizationsYo extends AppLocalizations {
  AppLocalizationsYo([String locale = 'yo']) : super(locale);

  @override
  String get driverBrandingLine => 'Wá Along pẹ̀lú';

  @override
  String get phoneEntryTitle => 'Wá Along pẹ̀lú';

  @override
  String get phoneEntrySubtitle =>
      'A ó fi kóòdù ránṣẹ́ sí nọ́mbà yìí kí ọjọ́ rẹ jẹ́ tìrẹ.';

  @override
  String get continueButton => 'Tẹ̀síwájú';

  @override
  String get legalPrefix => 'Tí o bá tẹ̀síwájú, o gbà sí ';

  @override
  String get termsLink => 'Àwọn òfin';

  @override
  String get legalMiddle => ' àti ';

  @override
  String get privacyLink => 'Ìlànà Ìpamọ́';

  @override
  String otpTitle(String phone) {
    return 'Tẹ kóòdù oní-nọ́mbà 6 tí a fi ránṣẹ́ sí $phone';
  }

  @override
  String get wrongNumber => 'Nọ́mbà tí kò tọ́?';

  @override
  String get resendCode => 'Tún kóòdù ránṣẹ́';

  @override
  String resendCountdown(int seconds) {
    return 'Tún ránṣẹ́ ní ${seconds}s';
  }

  @override
  String get errorInvalidPhone => 'Tẹ nọ́mbà Nàìjíríà tó péye';

  @override
  String get errorWrongOtp => 'Kóòdù kò tọ́ — tún gbìyànjú';

  @override
  String get errorExpiredOtp => 'Kóòdù ti parí — béèrè tuntun';

  @override
  String errorRateLimited(int seconds) {
    return 'Ìgbìyànjú ti pọ̀ jù. Tún gbìyànjú ní ${seconds}s';
  }

  @override
  String get errorGeneric => 'Nǹkan kan ṣẹlẹ̀. Jọ̀wọ́ tún gbìyànjú.';

  @override
  String get errorAuthNotConfigured =>
      'Ẹ̀dà yìí kò so mọ́ Along. Tún staging APK kọ́ pẹ̀lú env/staging.json.';

  @override
  String get errorValidation => 'Jọ̀wọ́ ṣàyẹ̀wò àwọn àyè kí o tún gbìyànjú.';

  @override
  String get errorPlateConflict => 'A ti forúkọ nọ́mbà ọkọ̀ yìí sílẹ̀ tẹ́lẹ̀.';

  @override
  String get profileTitle => 'Àpèjúwe rẹ';

  @override
  String get profileSubtitle => 'Sọ díẹ̀ nípa ara rẹ fún wa';

  @override
  String get nameLabel => 'Orúkọ kíkún';

  @override
  String get nameHint => 'Orúkọ rẹ';

  @override
  String get cityLabel => 'Ìlú';

  @override
  String get genderLabel => 'Akọ tàbí abo (àṣàyàn)';

  @override
  String get genderFemale => 'Obìnrin';

  @override
  String get genderMale => 'Ọkùnrin';

  @override
  String get genderOther => 'Mi ò fẹ́ sọ';

  @override
  String get photoOptional => 'Fi fọ́tò kún (àṣàyàn)';

  @override
  String get vehicleTitle => 'Ọkọ̀ rẹ';

  @override
  String get vehicleSubtitle => 'Báwo ni o ṣe máa wakọ̀ lórí Along?';

  @override
  String get plateLabel => 'Nọ́mbà ọkọ̀';

  @override
  String get plateHint => 'àpẹẹrẹ ABC-123-XY';

  @override
  String get seatsLabel => 'Ìjókòó';

  @override
  String get colorLabel => 'Àwọ̀';

  @override
  String get makeModelLabel => 'Ilé-iṣẹ́ àti irú';

  @override
  String get ownerQuestion => 'Ṣé ọkọ̀ rẹ nìyí?';

  @override
  String get ownerYes => 'Bẹ́ẹ̀ ni, tèmi ni';

  @override
  String get ownerNo => 'Rárá, ti ẹlòmíràn ni';

  @override
  String get ownerNameLabel => 'Orúkọ ẹni tó ni ín';

  @override
  String get ownerPhoneLabel => 'Fóònù ẹni tó ni ín';

  @override
  String get documentsTitle => 'Jẹ́rìí àwọn ìwé rẹ';

  @override
  String get documentsSubtitle => 'Gbé ìwé kọ̀ọ̀kan sókè láti bẹ̀rẹ̀ wíwakọ̀';

  @override
  String get docStatusNotStarted => 'Kò tíì bẹ̀rẹ̀';

  @override
  String get docStatusPending => 'Ó ń dúró';

  @override
  String get docStatusApproved => 'A ti fọwọ́ sí i';

  @override
  String get docStatusRejected => 'A kọ̀ ọ́';

  @override
  String get saveAndContinueLater => 'Fi pamọ́ kí o tẹ̀síwájú nígbà mìíràn';

  @override
  String captureTitle(String document) {
    return 'Ya $document';
  }

  @override
  String get captureGuide => 'Fi ìwé náà sínú férémù';

  @override
  String get takePhoto => 'Ya àwòrán';

  @override
  String get retakePhoto => 'Tún yà á';

  @override
  String get submitDocument => 'Fi ìwé ránṣẹ́';

  @override
  String get ocrReviewTitle => 'Ṣàyẹ̀wò àlàyé tí a mú jáde';

  @override
  String get ocrReviewSubtitle => 'Jẹ́rìí àyè kọ̀ọ̀kan kí o tó fi ránṣẹ́';

  @override
  String ocrSuggestedValue(String value) {
    return 'Àbá: $value';
  }

  @override
  String get ocrConfirmField => 'Lo èyí';

  @override
  String get ocrFieldConfirmed => 'A ti jẹ́rìí';

  @override
  String get ocrNoAutoFillNote =>
      'A kì í kún nọ́mbà ìdánimọ̀ fúnra rẹ̀ — tẹ jẹ́rìí fún àyè kọ̀ọ̀kan.';

  @override
  String get pendingTitle => 'Ìjẹ́rìí ń lọ lọ́wọ́';

  @override
  String get pendingHero => 'À ń ṣàyẹ̀wò àwọn ìwé rẹ';

  @override
  String get pendingExpectedGeneric => 'Ó sábà máa ń gba ọjọ́ iṣẹ́ 1–3';

  @override
  String pendingExpectedHours(int hours) {
    return 'A retí ní wákàtí $hours';
  }

  @override
  String get pendingWhatNext =>
      'A ó sọ fún ọ nígbà tí a bá fọwọ́ sí i. O lè ṣètò ọ̀nà rẹ bí o ṣe ń dúró.';

  @override
  String get setupRouteCta => 'Ṣètò ọ̀nà rẹ bí o ṣe ń dúró';

  @override
  String get routesListTitle => 'Àwọn ọ̀nà rẹ';

  @override
  String get routesAddRoute => 'Fi ọ̀nà kún';

  @override
  String get routesEmptyTitle => 'Ṣètò ọ̀nà rẹ pẹ̀lú ìtẹ̀ díẹ̀';

  @override
  String get routesEmptyBody =>
      'Tẹ àwọn ibùdó àti owó rẹ jáde kí èrò lè rí ọ ní ọ̀nà rẹ.';

  @override
  String get routeSuggestedCardTitle => 'Ọ̀nà tí a dábàá';

  @override
  String routeSuggestedCardBody(String mode, int stopCount) {
    return 'A rí ọ̀nà $mode rẹ tó ní ibùdó $stopCount.';
  }

  @override
  String get routeSuggestedCardCta => 'Tẹ láti ṣàyẹ̀wò kí o tẹ̀ ẹ́ jáde';

  @override
  String routeUnnamedProfile(String mode) {
    return 'Ọ̀nà $mode';
  }

  @override
  String routeStopsCount(int count) {
    return 'Ibùdó $count';
  }

  @override
  String routeLoadSurchargeLabel(String amount) {
    return 'Owó àfikún ẹrù: $amount';
  }

  @override
  String get routeLoadSurchargeOptional => 'Owó àfikún ẹrù (àṣàyàn)';

  @override
  String get routeLoadSurchargeHint => 'àpẹẹrẹ 50';

  @override
  String get routeFastSetupTitle => 'Ìṣètò ọ̀nà';

  @override
  String get routeFastSetupQuestion => 'Ṣé ọ̀nà rẹ nìyí?';

  @override
  String routeFastSetupSubtitle(int count) {
    return 'A rí ibùdó $count láti ọ̀nà rẹ';
  }

  @override
  String get routeYesPublish => 'Bẹ́ẹ̀ ni, tẹ̀ ẹ́ jáde';

  @override
  String get routeEditPrices => 'Ṣàtúnṣe owó';

  @override
  String get routeDrawManually => 'Rárá, yà á fúnra mi';

  @override
  String get routeDrawTitle => 'Yà ọ̀nà rẹ';

  @override
  String get routeDrawHint => 'Tẹ máàpù láti fi ibùdó kún';

  @override
  String get routeDrawEmptyStops => 'Fi ó kéré tán ibùdó méjì kún';

  @override
  String get routePublish => 'Tẹ̀ ẹ́ jáde';

  @override
  String routePriceToEnd(String amount) {
    return 'Dé òpin: $amount';
  }

  @override
  String routeSnapMatched(String name) {
    return 'Ó bá mu: $name ✓';
  }

  @override
  String get routeSnapNewStopHint => 'Ibùdó tuntun — orúkọ?';

  @override
  String get routeSnapPending => 'Ń ṣe ìbámu…';

  @override
  String get routePriceKeypadTitle => 'Ṣètò owó dé òpin';

  @override
  String get routePriceKeypadSet => 'Ṣètò';

  @override
  String get routePriceErrorNonMonotone =>
      'Owó kò gbọdọ̀ pọ̀ sí i bí a ṣe ń súnmọ́ ibi tí a ń lọ.';

  @override
  String get routePriceErrorLastNotZero => 'Ibùdó ìkẹyìn gbọdọ̀ jẹ́ ₦0.';

  @override
  String get routePriceErrorEmpty => 'Fi ó kéré tán ibùdó kan tó ní owó kún.';

  @override
  String get routeLoadError => 'A kò lè gbé àwọn ọ̀nà wá.';

  @override
  String get routePublishError => 'A kò lè tẹ ọ̀nà jáde. Tún gbìyànjú.';

  @override
  String get back => 'Padà';

  @override
  String get navHome => 'Ilé';

  @override
  String get navRoutes => 'Àwọn ọ̀nà';

  @override
  String get navEarnings => 'Owó';

  @override
  String get navAccount => 'Àkọọlẹ';

  @override
  String get homeUnverifiedBanner => 'Parí ìjẹ́rìí láti bẹ̀rẹ̀ iṣẹ́.';

  @override
  String get homeBatteryGuardBanner =>
      'Bátìrì ti lọ sílẹ̀ — a dín ìmúdójúìwọ̀n ibùdó kù láti fi agbára pamọ́.';

  @override
  String get homeLedgerBlockedBanner =>
      'A dá ìbámu dúró — san gbèsè rẹ láti bẹ̀rẹ̀ iṣẹ́.';

  @override
  String get homeSelectPark => 'Ní: yan ibùdókọ̀ ▾';

  @override
  String homeAtPark(String parkName) {
    return 'Ní: $parkName ▾';
  }

  @override
  String get homeDirectionOnRoute => 'Ìtọ́sọ́nà: lójú ọ̀nà mi ▾';

  @override
  String get homeDirectionNone => 'Ìtọ́sọ́nà: kò sí ▾';

  @override
  String get homeErrorSelectPark => 'Yan ibùdókọ̀ kí o tó bẹ̀rẹ̀ iṣẹ́ níbẹ̀.';

  @override
  String get homeErrorLocation => 'Tan ibùdó láti bẹ̀rẹ̀ iṣẹ́.';

  @override
  String get homeParkPickerTitle => 'Ibùdókọ̀ nítòsí';

  @override
  String get homeParkPickerEmpty => 'Kò sí ibùdókọ̀ nítòsí.';

  @override
  String homeParkDistance(int meters) {
    return '$meters m sí ibí';
  }

  @override
  String get homeParkSomewhereElse => 'Mo wà níbòmíràn';

  @override
  String get incomingRequestTitle => 'Ìbéèrè tuntun';

  @override
  String incomingRequestCountdown(int seconds) {
    return '${seconds}s';
  }

  @override
  String incomingRequestRiderLine(String name, String rating, int trips) {
    return '$name · $rating · ìrìn $trips';
  }

  @override
  String get incomingRequestPickup => 'Gbígbé';

  @override
  String get incomingRequestRoamingPickup => 'Ibi tí èrò wà';

  @override
  String get incomingRequestRoamingPickupMeta => 'Ìdá ọkọ̀ dúró — pàdé ní àmì';

  @override
  String incomingRequestCascade(int attempt, int max) {
    return 'Ìgbìyànjú $attempt nínú $max';
  }

  @override
  String get incomingRequestDropoff => 'Ibi ìsọ̀kalẹ̀';

  @override
  String incomingRequestPickupMeta(int distance, int eta) {
    return '$distance m · $eta ìṣ';
  }

  @override
  String incomingRequestFareLine(String amount, String tierLabel) {
    return 'Èrò yóò san $amount · $tierLabel';
  }

  @override
  String incomingRequestAlongFee(String amount, String percent) {
    return 'Owó Along $amount · $percent%';
  }

  @override
  String get incomingRequestLoadDefault => 'Èrò ní ẹrù';

  @override
  String incomingRequestLoadDetail(String size, String note) {
    return 'Ẹrù $size — $note';
  }

  @override
  String get incomingRequestWomenOnly => 'Ìbámu obìnrin nìkan';

  @override
  String get incomingRequestApproachBandUnder2 => 'kò tó ìṣ 2';

  @override
  String get incomingRequestApproachBandM2_5 => 'ìṣ 2–5';

  @override
  String get incomingRequestApproachBandOver5 => 'ìṣ 5+';

  @override
  String get incomingRequestAccept => 'Gbà';

  @override
  String get incomingRequestDecline => 'Kọ̀';

  @override
  String get declineReasonTitle => 'Kí ló dé tí o fi kọ̀?';

  @override
  String get declineReasonNoRoomForLoad => 'Kò sí àyè fún ẹrù';

  @override
  String get declineReasonTooFar => 'Ó jìnnà jù';

  @override
  String get declineReasonEndingShift => 'Mo ń parí iṣẹ́';

  @override
  String get declineReasonOther => 'Òmíràn';

  @override
  String get fareTierStandard => 'Owó ọkọ̀ déédé';

  @override
  String get fareTierCommunity => 'Owó tí àwọn èèyàn ń san';

  @override
  String get fareTierProfile => 'Owó awakọ̀';

  @override
  String get fareTierEstimate => 'Ìṣirò — gbà owó';

  @override
  String pricingRiderOffer(String amount) {
    return 'Èrò fi $amount lọ̀';
  }

  @override
  String get pricingLapsed => 'Kò sí àdéhùn — èrò lè yan ọkọ̀ mìíràn';

  @override
  String get pricingOutOfRange => 'Ọkọ̀ ti kọjá — ìdúnàádúrà ti parí';

  @override
  String get pricingDeclined => 'O kọ owó yìí';

  @override
  String get pricingDismiss => 'Padà sí máàpù';

  @override
  String get manifestTitle => 'Ìrìn tó ń lọ';

  @override
  String get manifestEmpty => 'Kò tíì sí èrò tí a gbà';

  @override
  String manifestBoarding(String stage) {
    return 'Wíwọ̀: $stage';
  }

  @override
  String manifestStatus(String status) {
    return 'Ipò: $status';
  }

  @override
  String get manifestMarkBoarded => 'Ó ti wọlé';

  @override
  String manifestOpen(int count) {
    return 'Ìrìn tó ń lọ ($count)';
  }

  @override
  String get activeTripStart => 'Bẹ̀rẹ̀ ìrìn';

  @override
  String get activeTripComplete => 'Parí ìrìn';

  @override
  String activeTripBoardAlight(String board, String alight) {
    return '$board → $alight';
  }

  @override
  String activeTripWalkEta(int minutes) {
    return 'Ìrìn ẹsẹ̀ ìṣ $minutes';
  }

  @override
  String get activeTripStalledCaption => 'kò súnmọ́ sí i';

  @override
  String get activeTripRelease => 'Tú sílẹ̀';

  @override
  String get activeTripReport => 'Fi ẹ̀sùn sùn';

  @override
  String get sosTeamAlerted => 'Ṣetán láti pe 112';

  @override
  String get sosSharingDetails =>
      'Pín ibi tí o wà lọ́wọ́ pẹ̀lú àwọn olùbásọ̀rọ̀ rẹ';

  @override
  String sosCallEmergency(String number) {
    return 'Pe $number';
  }

  @override
  String get sosHoldToCancel => 'Di mú láti fagilé';

  @override
  String get sosRaising => 'Ń ṣí ìpè 112…';

  @override
  String get sosRaiseFailed => 'A kò lè ṣí ìpè 112';

  @override
  String get sosRetry => 'Tún gbìyànjú';

  @override
  String get reportIncidentTitle => 'Jábọ̀ ìṣẹ̀lẹ̀';

  @override
  String get reportIncidentCategoryHeading => 'Kí ló ṣẹlẹ̀?';

  @override
  String get reportIncidentDescriptionHeading => 'Sọ sí i fún wa';

  @override
  String get reportIncidentDescriptionHint =>
      'Ṣàlàyé ohun tó ṣẹlẹ̀ (àlàyé ń ṣèrànwọ́)';

  @override
  String get reportIncidentSubmit => 'Fi ìròyìn ránṣẹ́';

  @override
  String get reportIncidentPickCategory => 'Yan ẹ̀ka kan';

  @override
  String get reportIncidentDescriptionRequired => 'Fi àlàyé kúkúrú kún';

  @override
  String get reportIncidentSubmitted => 'A ti fi ìròyìn pamọ́ sórí fóònù yìí';

  @override
  String get incidentCategorySafety => 'Ọ̀ràn ààbò';

  @override
  String get incidentCategoryFareDispute => 'Àríyànjiyàn owó ọkọ̀';

  @override
  String get incidentCategoryVehicleQuality => 'Ipò ọkọ̀';

  @override
  String get incidentCategoryDriverBehavior => 'Ìwà awakọ̀';

  @override
  String get incidentCategoryLostItem => 'Ohun tó sọnù';

  @override
  String get incidentCategoryOther => 'Òmíràn';

  @override
  String get accountProfileHeading => 'ÀPÈJÚWE';

  @override
  String get accountProfileUnknown => 'Awakọ̀';

  @override
  String get accountVerified => 'A ti jẹ́rìí';

  @override
  String get accountUnverified => 'A kò tíì jẹ́rìí';

  @override
  String get accountVehicleHeading => 'ỌKỌ̀';

  @override
  String get accountVehicleActiveHint => 'Ọkọ̀ tó ń ṣiṣẹ́';

  @override
  String get accountVehicleEmpty => 'Fi ọkọ̀ rẹ kún';

  @override
  String get accountVehicleSwitchHint => 'Kàn sí ìrànlọ́wọ́ láti yí ọkọ̀ padà';

  @override
  String get accountDocumentsHeading => 'ÀWỌN ÌWÉ';

  @override
  String get accountDocumentsAllApproved => 'A ti fọwọ́ sí gbogbo ìwé';

  @override
  String get accountDocumentsPending => 'Ìwé ń dúró de àyẹ̀wò';

  @override
  String get accountDocumentsNeedsAttention => 'Àwọn ìwé kan nílò àkíyèsí';

  @override
  String get accountDocumentsIncomplete => 'Ìwé kò pé';

  @override
  String get accountDocumentsUnknown => 'Ipò ìwé kò sí';

  @override
  String get accountPayoutHeading => 'ÌSANWÓ';

  @override
  String get accountPayoutBank => 'Báǹkì ìgbowó';

  @override
  String accountPayoutConfigured(String last4) {
    return 'Báǹkì tó parí sí $last4';
  }

  @override
  String get accountPayoutNotConfigured => 'Ṣètò báǹkì ìgbowó';

  @override
  String get accountPreferencesHeading => 'ÀṢÀYÀN';

  @override
  String get accountCityLabel => 'Ìlú iṣẹ́';

  @override
  String get accountCityHint => 'Maapu, pákì àti ìbéèrè n lo ìlú yìí';

  @override
  String get accountLanguage => 'Èdè';

  @override
  String get accountLanguageValue => 'Yorùbá';

  @override
  String get accountSafetyHeading => 'ÀÀBÒ';

  @override
  String get accountSafetyHowSos => 'Bí SOS ṣe ń ṣiṣẹ́';

  @override
  String get accountSafetyHowSosBody =>
      'Di SOS mú láti pe 112 kí o sì pín ibi tí o wà';

  @override
  String get accountHelp => 'Ìrànlọ́wọ́';

  @override
  String get accountLegal => 'Òfin';

  @override
  String get accountSignOut => 'Jáde';

  @override
  String get homeLedgerBlockedTitle => 'A dá ìbámu dúró';

  @override
  String homeLedgerBlockedBalance(String amount) {
    return 'Iye tó kù $amount';
  }

  @override
  String homeLedgerBlockedThreshold(String amount) {
    return 'Ààlà ìdènà $amount';
  }

  @override
  String get settleCta => 'Sanwó';

  @override
  String get settleTitle => 'San gbèsè';

  @override
  String settleCurrentBalance(String amount) {
    return 'Ìyókù lọ́wọ́lọ́wọ́: $amount';
  }

  @override
  String get settleAmountLabel => 'Owó tí o máa san';

  @override
  String get settleChannelBank => 'Ìfiránṣẹ́ báǹkì';

  @override
  String get settleChannelUssd => 'USSD';

  @override
  String get settleChannelCard => 'Káàdì';

  @override
  String get settleChannelAgent => 'San fún aṣojú';

  @override
  String get settleAgentCodeTitle => 'Kóòdù aṣojú rẹ';

  @override
  String settleAgentExpires(String time) {
    return 'Yóò parí $time';
  }

  @override
  String get settleNearbyAgentsTitle => 'Aṣojú nítòsí';

  @override
  String settleNearbyAgentDistance(int distance) {
    return '$distance m sí ibí';
  }

  @override
  String get settleDone => 'Ó ti parí';

  @override
  String get earningsLedgerSection => 'Ìṣe ìyókù owó';

  @override
  String get earningsTripsSection => 'ÌRÌN';

  @override
  String get earningsLedgerEmpty => 'Kò tíì sí àkọsílẹ̀';

  @override
  String get earningsTripsCaption =>
      'Owó ọwọ́ tí o gbà tààrà — kò sí nínú ìyókù Along rẹ';

  @override
  String get earningsTripsEmpty => 'Kò sí ìrìn owó ọwọ́ tó parí lónìí';

  @override
  String earningsTripsTodaySummary(int count, String amount) {
    return 'Ìrìn $count lónìí · a gbà $amount';
  }

  @override
  String get standingLink => 'Ipò';

  @override
  String get standingTitle => 'Ipò rẹ';

  @override
  String standingBalanceAt(String amount) {
    return 'Ìyókù nígbà ìyípadà: $amount';
  }

  @override
  String standingBlockThreshold(String amount) {
    return 'Ìbámu dúró tí gbèsè bá ju $amount lọ';
  }

  @override
  String standingGraceDeadline(String date) {
    return 'Ọjọ́ ìparí àánú: $date';
  }

  @override
  String get standingRestoreHint =>
      'San ju ààlà ìkìlọ̀ lọ láti dá ipò rere padà';

  @override
  String get standingHistoryTitle => 'ÌTÀN';

  @override
  String get standingHistoryEmpty => 'Kò tíì sí ìyípadà ipò';

  @override
  String get guarantorLink => 'Fi onídùúró kún';

  @override
  String get guarantorTitle => 'Onídùúró';

  @override
  String get guarantorExplainer =>
      'A máa sọ fún onídùúró rẹ tí gbèsè rẹ kò bá sanwó lẹ́yìn àkókò àánú. A kì í gba nǹkan kan lọ́wọ́ rẹ̀.';

  @override
  String get guarantorTypeDriver => 'Awakọ̀ ẹgbẹ́';

  @override
  String get guarantorTypeOwner => 'Ẹni tó ni ọkọ̀';

  @override
  String get guarantorNameLabel => 'Orúkọ kíkún';

  @override
  String get guarantorPhoneLabel => 'Nọ́mbà fóònù';

  @override
  String get guarantorSubmit => 'Fi onídùúró kún';

  @override
  String get guarantorSuccess =>
      'A ti fi onídùúró kún — yóò gba ìjápọ̀ ìjẹ́wọ́';

  @override
  String get extendTripTitle => 'Fa ìrìn gùn';

  @override
  String get extendTripSearchHint => 'Ibo ni báyìí?';

  @override
  String extendTripDestination(String destination) {
    return 'Ń tẹ̀síwájú sí $destination';
  }

  @override
  String get extendTripPropose => 'Dábàá fún èrò';

  @override
  String get incomingExtensionTitle => 'Ìbéèrè ìfagùn';

  @override
  String get incomingExtensionDecline => 'Kọ̀';

  @override
  String get incomingExtensionAccept => 'Gbà';

  @override
  String incomingRiderExtensionBody(String destination, String delta) {
    return 'Èrò dábàá láti tẹ̀síwájú sí $destination fún +$delta';
  }

  @override
  String get tripCompleteTitle => 'Ìrìn-àjò ti parí';

  @override
  String tripCompleteFareLine(String amount) {
    return 'Owó $amount — èrò yóò san owó ọwọ́ fún ọ';
  }

  @override
  String tripCompleteAlongFeeLine(String amount) {
    return 'Owó Along $amount — a ti fi kún ìyókù rẹ';
  }

  @override
  String tripCompleteNewBalance(String amount) {
    return 'Ìyókù tuntun $amount';
  }

  @override
  String get tripCompleteCashQuestion => 'Jẹ́rìí pé o gba owó ọwọ́?';

  @override
  String get tripCompleteYes => 'Bẹ́ẹ̀ ni';

  @override
  String get tripCompleteDifferent => 'Iye owó mìíràn';

  @override
  String get tripCompleteDifferentPrompt => 'Èló ni o gbà?';

  @override
  String get tripCompleteRateTitle => 'Fún èrò rẹ ní máàkì';

  @override
  String get tripCompleteDone => 'Ó ti parí';

  @override
  String get requestPayment => 'Béèrè ìsanwó';

  @override
  String tripCompleteDigitalLine(String amount) {
    return 'A san án lórí ayélujára · $amount lọ sí báǹkì rẹ';
  }

  @override
  String tripCompleteDigitalFeeLine(String amount) {
    return 'A ti yọ owó Along $amount kúrò';
  }

  @override
  String get myQrTitle => 'Kóòdù QR mi';

  @override
  String get myQrAccountSubtitle => 'Pín kóòdù rẹ fún ìsanwó orí ayélujára';

  @override
  String get myQrDigitalDisabledBanner =>
      'Ìsanwó orí ayélujára kò tíì bẹ̀rẹ̀ — QR rẹ wà fún ìṣètò àti ìdánwò nìkan.';

  @override
  String get myQrPayoutPrompt => 'Ṣètò báǹkì ìgbowó';

  @override
  String get myQrPayoutHint =>
      'Fi àkáǹtì báǹkì rẹ kún kí èrò lè sanwó fún ọ lórí ayélujára. Along kì í di owó rẹ mú.';

  @override
  String get myQrSetupPayout => 'Ṣètò báǹkì ìgbowó';

  @override
  String get myQrPayoutComingSoon =>
      'Ìṣètò ìgbowó yóò ṣí láti Àkọọlẹ nígbà tí ìsanwó orí ayélujára bá bẹ̀rẹ̀.';

  @override
  String get myQrShare => 'Pín bí àwòrán';

  @override
  String get myQrOrderSticker => 'Béèrè sítíkà';

  @override
  String myQrStickerStatus(String status) {
    return 'Ìbéèrè sítíkà: $status';
  }

  @override
  String get myQrVerifySticker => 'Jẹ́rìí sítíkà mi';

  @override
  String get myQrVerifyMatch => 'Sítíkà bá kóòdù àti nọ́mbà ọkọ̀ rẹ mu';

  @override
  String get myQrVerifyMismatch => 'Sítíkà yìí kò bá àkọọlẹ rẹ mu';

  @override
  String get myQrVerifyInvalid => 'Kì í ṣe kóòdù QR Along';

  @override
  String get myQrVerifyTimeout => 'Àkókò àyẹ̀wò ti parí — tún gbìyànjú';

  @override
  String get myQrPauseDigital => 'Dá ìsanwó orí ayélujára dúró';

  @override
  String get myQrPauseDigitalHint => 'Èrò yóò rí owó ọwọ́ nìkan nígbà ìdádúró';

  @override
  String get myQrPausedBanner =>
      'A dá ìsanwó orí ayélujára dúró — èrò ń rí owó ọwọ́ nìkan';

  @override
  String get myQrRotate => 'Yí kóòdù padà';

  @override
  String get myQrRotateConfirmTitle => 'Yí kóòdù QR padà?';

  @override
  String get myQrRotateConfirmBody =>
      'Sítíkà rẹ lọ́wọ́ yóò dẹ́kun iṣẹ́. Ẹgbẹ́ iṣẹ́ yóò tẹ tuntun.';

  @override
  String get myQrRotateCancel => 'Fagilé';

  @override
  String get myQrRotateConfirm => 'Yí padà';

  @override
  String get paymentRequestTitle => 'Ìbéèrè ìsanwó';

  @override
  String paymentRequestForRider(String riderName) {
    return 'Fún $riderName';
  }

  @override
  String paymentRequestCountdown(int seconds) {
    return 'Yóò parí ní ${seconds}s';
  }

  @override
  String get paymentRequestWaiting => 'Ń dúró de ìsanwó…';

  @override
  String paymentRequestPaidLine(String amount) {
    return 'A san $amount ✓';
  }

  @override
  String paymentRequestBankLine(String amount) {
    return '$amount sí báǹkì rẹ';
  }

  @override
  String get paymentRequestDone => 'Ó ti parí';

  @override
  String get paymentRequestExpired => 'QR yìí ti parí — ṣe tuntun';

  @override
  String get paymentRequestDigitalDisabled =>
      'Ìsanwó orí ayélujára kò tíì bẹ̀rẹ̀';

  @override
  String get paymentRequestTokenError =>
      'A kò lè jẹ́rìí QR ìsanwó — tún gbìyànjú';

  @override
  String get earningsDigitalSection => 'Ìsanwó oní-nọ́ńbà';

  @override
  String get earningsDigitalCaption =>
      'A san án tààrà sí báǹkì rẹ — kò sí nínú ìyókù Along';

  @override
  String get earningsDigitalEmpty => 'Kò tíì sí ìsanwó orí ayélujára';

  @override
  String earningsDigitalRow(String source) {
    return 'Ayélujára · $source';
  }

  @override
  String get sosQueued =>
      'A ti fi pamọ́ sórí fóònù yìí. Pe 112 nígbà tí o bá padà sórí ayélujára.';

  @override
  String get sosLiveLink => 'Da ìjápọ̀ ibùdó lọ́wọ́ kọ';

  @override
  String get sosLiveLinkCopied => 'A ti da ìjápọ̀ ibùdó kọ';

  @override
  String get sosContactsHeading => 'Sọ fún ẹni tí o fọkàn tán';

  @override
  String sosContactWhatsapp(String name) {
    return 'WhatsApp $name';
  }

  @override
  String sosContactSms(String name) {
    return 'Fi ọ̀rọ̀ ránṣẹ́ sí $name';
  }

  @override
  String get emergencyContactsHeading => 'OLÙBÁSỌ̀RỌ̀ PÀJÁWÌRÌ';

  @override
  String get emergencyContactsHint =>
      'A máa sọ fún àwọn wọ̀nyí tí o bá tẹ SOS. Títí dé 5. WhatsApp tàbí ọ̀rọ̀ yóò ṣí lórí fóònù rẹ.';

  @override
  String get emergencyContactsEmpty => 'Kò tíì sí olùbásọ̀rọ̀ pàjáwìrì';

  @override
  String get emergencyContactName => 'Orúkọ';

  @override
  String get emergencyContactPhone => 'Fóònù';

  @override
  String get emergencyContactAdd => 'Fi olùbásọ̀rọ̀ kún';

  @override
  String emergencyContactRemove(String name) {
    return 'Yọ $name kúrò';
  }

  @override
  String get emergencyContactInvalidPhone => 'Lo nọ́mbà bí +2348012345678';

  @override
  String get emergencyContactLimit => 'O lè fi olùbásọ̀rọ̀ 5 pamọ́';

  @override
  String get emergencyContactSaveFailed => 'A kò lè fi olùbásọ̀rọ̀ yẹn pamọ́';

  @override
  String get buildMyDayTitle => 'Kọ́ ọjọ́ mi';

  @override
  String get buildMyDayStart => 'Fi pamọ́ kí o lo ọjọ́ yìí';

  @override
  String get buildMyDayCorridor => 'Ọ̀nà';

  @override
  String get saveLayout => 'Fi ìtò pamọ́';

  @override
  String get layoutName => 'Orúkọ ìtò';

  @override
  String get addRow => 'Fi ìlà kún';

  @override
  String get addSeat => 'Fi ìjókòó kún';

  @override
  String get removeRow => 'Yọ ìlà kúrò';

  @override
  String get overCapacityNote =>
      'Èyí ju iye ìjókòó tó wọ́pọ̀ lọ. A ti fi pamọ́, a sì sàmì sí i fún àyẹ̀wò.';

  @override
  String get seatMapTitle => 'Máàpù ìjókòó';

  @override
  String get seatFull => 'Ó ti kún';

  @override
  String get seatEmpty => 'Ṣófo';

  @override
  String get seatFree => 'ṣófo';

  @override
  String get seatOccupied => 'ẹnìkan wà';

  @override
  String get seatHeld => 'a dì í mú';

  @override
  String get seatBlocked => 'a dí i';

  @override
  String get seatDriver => 'awakọ̀';

  @override
  String get rideRulesHeading => 'Òfin ìrìn';

  @override
  String get customRuleHint => 'Àkọlé òfin';

  @override
  String get customRuleBody => 'Ohun tí èrò yẹ kí wọ́n mọ̀';

  @override
  String get customRuleSave => 'Fi òfin mi kún';

  @override
  String get holdMinutes => 'Ìṣẹ́jú ìdìmú';

  @override
  String get capMax => 'Ààlà ìjókòó';

  @override
  String get deleteRule => 'Yọ òfin kúrò';

  @override
  String get dayNeedsCorridor => 'Yan ọ̀nà';

  @override
  String get seatStale => 'Máàpù ìjókòó ti ju ìṣẹ́jú kan lọ';

  @override
  String get shiftStart => 'Iṣẹ́ ń bẹ̀rẹ̀';

  @override
  String get shiftEnd => 'Iṣẹ́ ń parí';

  @override
  String get homeLabel => 'Ibùdó ọ̀nà ilé';

  @override
  String get walkExtension => 'Ìṣẹ́jú ìdìmú àfikún fún èrò tó ń rìn';

  @override
  String get seatLuggage => 'ẹrù';

  @override
  String get voiceCommandHint => 'Sọ gbà, kún, tàbí ìjókòó ẹ̀yìn òsì ṣófo';

  @override
  String get conductorOpen => 'Kóòdù agbèrò';

  @override
  String get conductorTitle => 'Agbèrò';

  @override
  String get conductorCode => 'Kóòdù láti ọ̀dọ̀ awakọ̀';

  @override
  String get conductorJoin => 'Ṣí máàpù ìjókòó';

  @override
  String get ghostSeatTitle => 'Ṣì wà lọ́wọ́ lẹ́yìn ìsọ̀kalẹ̀?';

  @override
  String get ghostSeatFree => 'Ṣí i sílẹ̀';

  @override
  String freeSeatCount(int count) {
    return '$count ṣófo';
  }

  @override
  String get restTitle => 'Ìsinmi';

  @override
  String get restDriveMinutes => 'Ìṣẹ́jú wíwakọ̀ kí ìsinmi tó dé';

  @override
  String get restMinutes => 'Ìṣẹ́jú ìsinmi';

  @override
  String get restSave => 'Fi pamọ́';

  @override
  String get restStart => 'Bẹ̀rẹ̀ ìsinmi';

  @override
  String get restFinish => 'Parí ìsinmi';

  @override
  String get restPriority =>
      'Àkọ́kọ́ nínú iṣẹ́ títí àkókò ìsinmi rẹ yóò fi parí';

  @override
  String get marketplaceTitle => 'Lónìí';

  @override
  String get marketplaceGoal => 'Àfojúsùn òní';

  @override
  String get marketplaceEarned => 'Ó ti wọlé';

  @override
  String get marketplaceTypical => 'Owó ìjókòó tó wọ́pọ̀';

  @override
  String marketplaceSeats(int count) {
    return 'Ìjókòó $count ló kù';
  }

  @override
  String get marketplaceGoalMet => 'Àfojúsùn ti tẹ̀';

  @override
  String get marketplaceSave => 'Fi pamọ́';

  @override
  String get marketplaceCorridor => 'Ọ̀nà tí o ń wò';

  @override
  String get marketplaceRequests => 'Ìbéèrè';

  @override
  String get marketplaceAddCorridor => 'Fi kún';

  @override
  String marketplaceTip(String corridor) {
    return 'Tò lọ sí $corridor';
  }

  @override
  String get marketplaceFuel => 'Owó lítà kan';

  @override
  String get marketplaceFuelLabel => 'Ilé epo';

  @override
  String get marketplaceFuelSave => 'Fi owó pamọ́';

  @override
  String get marketplaceEventName => 'Orúkọ ayẹyẹ';

  @override
  String get marketplaceEventHours => 'Wákàtí tí ibẹ̀ yóò fi ṣí';

  @override
  String get marketplaceEventSave => 'Ṣí ibẹ̀';

  @override
  String activeTripMessageRider(String name) {
    return 'Fi ọ̀rọ̀ ránṣẹ́ sí $name';
  }

  @override
  String get activeTripMessageRiderUnknown => 'Fi ọ̀rọ̀ ránṣẹ́ sí èrò';

  @override
  String get tripEtaCalculating => 'À ń ṣírò…';

  @override
  String tripEtaPickup(String label) {
    return 'Ìgbéra $label';
  }

  @override
  String get drivePhasePickup => 'Gbígbé';

  @override
  String get drivePhaseBoard => 'Wọlé';

  @override
  String get drivePhaseDrop => 'Sọ̀kalẹ̀';

  @override
  String activeTripPickUpTitle(String name) {
    return 'Gbé $name';
  }

  @override
  String activeTripOnBoardTitle(String name) {
    return '$name ti wọlé';
  }

  @override
  String activeTripDropTitle(String name) {
    return 'Sọ $name kalẹ̀';
  }

  @override
  String get activeTripRiderFallback => 'èrò rẹ';

  @override
  String get activeTripBoardNaMe => 'Wọlé pẹ̀lú Na Me';

  @override
  String get activeTripEnterPin => 'Tẹ PIN gbígbé';

  @override
  String get activeTripPinShort => 'PIN';

  @override
  String get activeTripMessageShort => 'Ifiranṣẹ';

  @override
  String get activeTripSeatsShort => 'Ìjókòó';

  @override
  String get activeTripExtendShort => 'Fà á gùn';

  @override
  String get activeTripReportShort => 'Jábọ̀';

  @override
  String get activeTripFareLabel => 'Èrò yóò san';

  @override
  String activeTripFeeCaption(String amount, String percent) {
    return 'Owó Along $amount ($percent%)';
  }

  @override
  String incomingAcceptFare(String amount) {
    return 'Gbà · $amount';
  }

  @override
  String incomingFareCaption(String tierLabel) {
    return 'Èrò yóò san · $tierLabel';
  }

  @override
  String get homeOfflineTitle => 'O kò sí lórí ayélujára';

  @override
  String get homeOnlineTitle => 'O wà lórí ayélujára';

  @override
  String get homeOfflineHint => 'Lọ sórí ayélujára láti gba ìbéèrè nítòsí rẹ.';

  @override
  String get homeOnlineHint => 'Ìbéèrè yóò hàn níbí. Gbà pẹ̀lú ìfọwọ́kàn kan.';

  @override
  String get homeGoOnline => 'Ẹ JẸ́ Á LỌ';

  @override
  String get homeGoOffline => 'Kúrò lórí ayélujára';

  @override
  String get homeModeAtPark => 'Ní gáréèjì';

  @override
  String get homeModeRoaming => 'Ń rìn kiri';

  @override
  String get homeModeFull => 'Ó ti kún';

  @override
  String homeTodayEarned(String amount) {
    return 'Òní · $amount';
  }

  @override
  String homeTodayTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ìrìn àjò $count',
      one: 'Ìrìn àjò 1',
      zero: 'Kò sí ìrìn àjò síbẹ̀',
    );
    return '$_temp0';
  }

  @override
  String get homeShortcutsTitle => 'Ọjọ́ rẹ';

  @override
  String get homeDirectionShortOnRoute => 'Lójú ọ̀nà mi';

  @override
  String get homeDirectionShortNone => 'Ọ̀nà èyíkéyìí';

  @override
  String get homeTileDemand => 'Ìbéèrè';

  @override
  String get tripCompleteCashHero => 'Gba owó lọ́wọ́';

  @override
  String get tripCompleteRowFare => 'Owó ọkọ̀';

  @override
  String get tripCompleteRowFee => 'Owó Along (sí àkọọ́lẹ̀)';

  @override
  String get tripCompleteRowBalance => 'Àkọọ́lẹ̀ tuntun';

  @override
  String tripCompleteYesAmount(String amount) {
    return 'Bẹ́ẹ̀ni, mo gba $amount';
  }

  @override
  String get settleSubtitle => 'Àkọọ́lẹ̀ Along rẹ';

  @override
  String get settleOwedLabel => 'O jẹ Along ní gbèsè';

  @override
  String get settleCreditLabel => 'Ìyókù owó rẹ';

  @override
  String settleThreshold(String amount) {
    return 'Ìbámu dúró tí gbèsè bá ju $amount lọ';
  }

  @override
  String get settleMethodTitle => 'Sanwó pẹ̀lú';

  @override
  String settleSubmit(String amount) {
    return 'San $amount';
  }

  @override
  String get settleChannelBankDetail => 'Fi ránṣẹ́ sí àkọọ́lẹ̀ Along';

  @override
  String get settleChannelUssdDetail => 'Tẹ kóòdù, kò nílò dátà';

  @override
  String get settleChannelCardDetail => 'Káàdì ìsanwó';

  @override
  String get settleChannelAgentDetail => 'San owó níbi aṣojú Along';

  @override
  String earningsBalanceAfter(String amount) {
    return 'Ìyókù $amount';
  }

  @override
  String get ratingTagSafeDriving => 'Wíwakọ̀ láìléwu';

  @override
  String get ratingTagFairFare => 'Owó tó tọ́';

  @override
  String get ratingTagCleanVehicle => 'Ọkọ̀ tó mọ́';

  @override
  String get ratingTagPolite => 'Oníwà rere';

  @override
  String get ratingTagOnTime => 'Ní àkókò';

  @override
  String get ratingTagReady => 'Ṣetán níbi ìgbéra';

  @override
  String get ratingTagPaidPromptly => 'Sanwó kíákíá';

  @override
  String get guarantorWhoTitle => 'Ta ló máa ṣe onígbọ̀wọ́ rẹ';

  @override
  String get guarantorDetailsTitle => 'Àlàyé wọn';

  @override
  String get seatToolsTitle => 'Irinṣẹ́ kíákíá';

  @override
  String get seatBoardEmptyBody =>
      'Ṣètò ọjọ́ rẹ láti ṣètò ìjókòó ọkọ̀ rẹ. Lẹ́yìn náà o lè sàmì sí àwọn tó wà nínú rẹ̀ níbí.';

  @override
  String get mpGoalSection => 'Àfojúsùn òní';

  @override
  String get mpDemandSection => 'Ibi tí èrò wà';

  @override
  String get mpFuelSection => 'Iye epo';

  @override
  String get mpEventSection => 'Ìṣẹ̀lẹ̀ nítòsí';

  @override
  String seatBoardSubtitle(int count) {
    return '$count ṣófo · tẹ ìjókòó láti yí i padà';
  }

  @override
  String get mpSubtitle => 'Ṣètò àfojúsùn, wo ibi tí èrò wà, kí o pín ìmọ̀ràn.';

  @override
  String get mpGoalEmpty => 'Ṣètò àfojúsùn láti rí iye ìjókòó tó kù';

  @override
  String get mpMoreSection => 'Pín fún àwọn awakọ̀';

  @override
  String get mpFuelDetail => 'Iye epo òní nítòsí';

  @override
  String get mpEventDetail => 'Ṣí ibi ìgbérò fún èrò púpọ̀';

  @override
  String get restSubtitle =>
      'Sinmi dáadáa lẹ́yìn ìrìn gígùn. Ìsinmi kíkún ń gbé ọ sókè nínú ìlà.';

  @override
  String get restStatusDriving => 'Lójú ọ̀nà';

  @override
  String restStatusResting(String time) {
    return 'Ń sinmi láti $time';
  }

  @override
  String restPlan(int rest, int drive) {
    return 'Ìsinmi ìṣẹ́jú $rest ní gbogbo ìṣẹ́jú $drive';
  }

  @override
  String get restPlanEmpty => 'Ṣètò bí o ṣe ń wakọ̀ pẹ́ tó kí o tó sinmi';

  @override
  String get restRhythmSection => 'Ìlànà rẹ';

  @override
  String get conductorSubtitle =>
      'Ran awakọ̀ lọ́wọ́ láti mú ìjókòó dójú ìwọ̀n.';

  @override
  String get conductorHowTo =>
      'Awakọ̀ á ṣí Àwòrán ìjókòó → Kóòdù kọ́ndọ́ktọ̀ á sì ka kóòdù oní-lẹ́tà 8 fún ọ.';

  @override
  String get restDriveShort => 'Wakọ̀ (ìṣẹ́jú)';

  @override
  String get restBreakShort => 'Ìsinmi (ìṣẹ́jú)';

  @override
  String get mpTargetShort => 'Àfojúsùn';

  @override
  String get mpEarnedShort => 'Tí o rí';

  @override
  String get daySubtitle =>
      'Yan ibi tí o ó ti ṣiṣẹ́, ṣètò ìjókòó àti òfin tí èrò máa rí.';

  @override
  String daySeatsCount(int count) {
    return 'Ìjókòó $count';
  }

  @override
  String get dayRouteOptional => 'Ọ̀nà (àṣàyàn)';

  @override
  String get dayHoursSection => 'Wákàtí rẹ';

  @override
  String get daySeatsSection => 'Ìjókòó';

  @override
  String get dayRemove => 'Yọ kúrò';

  @override
  String get dayAddRule => 'Fi òfin kún';

  @override
  String get dayRuleRow => 'Kàn';

  @override
  String dayRowN(int n) {
    return 'Ìlà $n';
  }

  @override
  String get dayRuleDetails => 'Àlàyé òfin';

  @override
  String get dayRuleDetailsBody =>
      'Àkókò ìdádúró, ìrìn àfikún, ààlà ìjókòó, ọ̀rọ̀';

  @override
  String get dayCustomRule => 'Kọ òfin tìrẹ';

  @override
  String get dayCustomRuleBody => 'A ń fi hàn èrò kí wọ́n tó gbà';

  @override
  String get howItWorks => 'Bí ó ṣe ń ṣiṣẹ́';

  @override
  String get conductorStep1 => 'Gba kóòdù';

  @override
  String get conductorStep1Body => 'Awakọ̀ á pín in láti máàpù ìjókòó';

  @override
  String get conductorStep2 => 'Darapọ̀ mọ́ ọkọ̀';

  @override
  String get conductorStep2Body => 'O máa rí ìjókòó kan náà lẹ́sẹ̀kẹsẹ̀';

  @override
  String get conductorStep3 => 'Ṣàtúnṣe ìjókòó';

  @override
  String get conductorStep3Body => 'Tẹ ìjókòó nígbà tí èrò bá wọlé tàbí jáde';

  @override
  String get seatEmptyStep1 => 'Yan ọkọ̀ rẹ';

  @override
  String get seatEmptyStep1Body => 'A ó ya ìjókòó rẹ̀';

  @override
  String get seatEmptyStep2 => 'Yan ọ̀nà';

  @override
  String get seatEmptyStep2Body => 'Èrò lórí rẹ̀ á rí ìjókòó rẹ';

  @override
  String get seatEmptyStep3 => 'Kún ìjókòó bí o ṣe ń lọ';

  @override
  String get seatEmptyStep3Body => 'Tẹ ìjókòó láti sàmì sí i';

  @override
  String get connOffline => 'Kò sí íntánẹ́ẹ̀tì · o lè máa bá a lọ';

  @override
  String connOfflineQueued(int count) {
    return 'Kò sí íntánẹ́ẹ̀tì · $count ti fipamọ́ láti fi ránṣẹ́';
  }

  @override
  String get connReconnecting => 'Ń tún so pọ̀';

  @override
  String connSending(int count) {
    return 'Ń tún so pọ̀ · ń fi $count ránṣẹ́';
  }

  @override
  String get connRestored => 'Ti padà sórí íntánẹ́ẹ̀tì';

  @override
  String connRestoredSent(int count) {
    return 'Ti padà · a ti fi $count ránṣẹ́';
  }

  @override
  String get connRetry => 'Tún gbìyànjú';

  @override
  String connNeedsConnection(int count) {
    return 'Kò sí íntánẹ́ẹ̀tì · $count láti tún ṣe lórí ayélujára';
  }

  @override
  String connOfflineMixed(int queued, int needs) {
    return 'Kò sí íntánẹ́ẹ̀tì · $queued láti fi ránṣẹ́ · $needs láti tún ṣe';
  }

  @override
  String get homeOnlineNoSignal => 'Wà lórí ayélujára · kò sí àmì';
}
