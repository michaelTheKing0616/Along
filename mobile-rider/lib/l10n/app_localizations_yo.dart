// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Yoruba (`yo`).
class AppLocalizationsYo extends AppLocalizations {
  AppLocalizationsYo([String locale = 'yo']) : super(locale);

  @override
  String get phoneEntryTitle => 'Rìn kiri. Bí o ṣe fẹ́.';

  @override
  String get phoneEntrySubtitle =>
      'A ó fi kóòdù ránṣẹ́ sí nọ́mbà yìí kí ìrìn náà jẹ́ tìrẹ.';

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
  String get nameTitle => 'Kí ni àwọn awakọ̀ yóò máa pè ọ́?';

  @override
  String get nameHint => 'Orúkọ rẹ';

  @override
  String get skip => 'Fò';

  @override
  String get errorInvalidPhone => 'Tẹ nọ́mbà Nàìjíríà tó péye';

  @override
  String errorRateLimited(int seconds) {
    return 'Ìgbìyànjú ti pọ̀ jù. Tún gbìyànjú ní ${seconds}s';
  }

  @override
  String get errorWrongOtp => 'Kóòdù kò tọ́ — tún gbìyànjú';

  @override
  String get errorExpiredOtp => 'Kóòdù ti parí — béèrè tuntun';

  @override
  String get errorGeneric => 'Nǹkan kan ṣẹlẹ̀. Jọ̀wọ́ tún gbìyànjú.';

  @override
  String get errorAuthNotConfigured =>
      'Ẹ̀dà yìí kò so mọ́ Along. Tún staging APK kọ́ pẹ̀lú env/staging.json.';

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
  String get homeMenu => 'Àkójọ';

  @override
  String get homeVehicles => 'Àwọn ọkọ̀';

  @override
  String get homeRecenter => 'Padà sí àárín';

  @override
  String get guardianIntro =>
      'Àyẹ̀wò lórí ìrìn yìí, nígbà tí o bá béèrè nìkan.';

  @override
  String get homeLocationDeniedBanner => 'Tan ibùdó láti rí ọkọ̀ tó wà nítòsí';

  @override
  String get homeChooseOnMap => 'Yàn lórí máàpù';

  @override
  String get homeNearbyTitle => 'Nítòsí';

  @override
  String homeNearbyRow(
    String countBucket,
    String mode,
    String heading,
    int minutes,
  ) {
    return '$countBucket $mode nítòsí · ń lọ $heading · ~$minutes ìṣ';
  }

  @override
  String get modeKeke => 'kẹ̀kẹ́';

  @override
  String get searchTitle => 'Níbo ni?';

  @override
  String get searchRecentsTitle => 'Àìpẹ́';

  @override
  String get searchResultsTitle => 'Àbájáde';

  @override
  String get searchOfflineHint => 'Kò sí ìntánẹ́ẹ̀tì · ń wá ibi tí a fi pamọ́';

  @override
  String get cachedOptionsStaleBadge => 'A fi pamọ́ · ó lè ti pẹ́';

  @override
  String get adjustPickupTitle => 'Ṣàtúnṣe ibi ìgbé';

  @override
  String adjustPickupBoardingAt(String stageName) {
    return 'Wíwọ ọkọ̀ ní: $stageName';
  }

  @override
  String get adjustPickupConfirm => 'Jẹ́rìí ibi náà';

  @override
  String get tripOptionsHeading => 'Yan bí o ṣe máa lọ';

  @override
  String get tripOptionsDegradedBanner => 'Àkókò tààrà kò sí';

  @override
  String get tripOptionsSlowerDirectCaption => 'Ó lọ́ra ju ọ̀nà ìyípadà lọ';

  @override
  String get tripOptionsAgreePrice => 'Gbà owó';

  @override
  String get pricingTitle => 'Owó Along';

  @override
  String get pricingLapsed => 'Kò sí àdéhùn — gbìyànjú ọkọ̀ mìíràn';

  @override
  String get pricingOutOfRange => 'Ọkọ̀ ti kọjá';

  @override
  String get pricingDeclined => 'A kọ ìfilọ̀';

  @override
  String pricingDriverOffer(String amount) {
    return 'Awakọ̀ fi $amount lọ̀';
  }

  @override
  String get hailSearchTitle => 'Níbo lò ń lọ?';

  @override
  String get requestUndoMessage => 'Ń béèrè…';

  @override
  String get loadFlagTitle => 'Ṣé o gbé ẹrù?';

  @override
  String get loadFlagSizeSmall => 'Kékeré';

  @override
  String get loadFlagSizeMedium => 'Àárín';

  @override
  String get loadFlagSizeLarge => 'Ńlá';

  @override
  String get loadFlagNoteHint => 'Àkọsílẹ̀ àṣàyàn (lẹ́tà 140)';

  @override
  String get loadFlagRememberDay => 'Rántí fún òní';

  @override
  String get loadFlagCapacityWarning => 'Ọ̀nà yìí lè máà gba ẹrù rẹ';

  @override
  String get loadFlagRequestAnyway => 'Béèrè bẹ́ẹ̀ náà';

  @override
  String get loadFlagDone => 'Ó ti parí';

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
  String get coverageGapTitle => 'Kò tíì sí ọ̀nà tí a yà síbí';

  @override
  String coverageGapNearestBoarding(String name, String distance) {
    return 'Ibùdókọ̀ tó súnmọ́ jù: $name · $distance';
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
  String get coverageGapVehiclesNone => 'Ọkọ̀ nítòsí: kò sí';

  @override
  String coverageGapVehiclesNearby(int count) {
    return 'Ọkọ̀ nítòsí: $count';
  }

  @override
  String get coverageGapWalkThere => 'Rìn lọ síbẹ̀';

  @override
  String get coverageGapTellUs => 'Sọ fún wa nípa àgbègbè yìí';

  @override
  String get coverageGapThanks => 'Ẹ ṣé — a ti kọ ìròyìn rẹ sílẹ̀';

  @override
  String get tripOptionsWhy => 'Kí ló dé?';

  @override
  String get tripOptionsWhyTitle => 'Ìdí tí a fi dábàá';

  @override
  String get tripOptionsWhyFare => 'Owó ọkọ̀';

  @override
  String get tripOptionsWhyTime => 'Àkókò';

  @override
  String get tripOptionsWhyEffort => 'Ìsapá';

  @override
  String get tripOptionsShowLegs => 'Fi àwọn ẹsẹ̀ hàn';

  @override
  String get tripOptionsHideLegs => 'Fi àwọn ẹsẹ̀ pamọ́';

  @override
  String tripOptionsRequestLeg(int leg, String fare) {
    return 'Béèrè ẹsẹ̀ $leg · $fare';
  }

  @override
  String get transferTitle => 'Ẹsẹ̀ tó kàn';

  @override
  String get transferNextLegTitle => 'Ẹsẹ̀ tó kàn';

  @override
  String transferSupply(String bucket) {
    return '$bucket ń kó èrò';
  }

  @override
  String get transferRequestNextLeg => 'Béèrè ẹsẹ̀ tó kàn';

  @override
  String get transferChangePlan => 'Yí ètò padà';

  @override
  String get transferWalkLoading => 'Ń gbé ìtọ́sọ́nà ìrìn wá…';

  @override
  String get wayfindingTitle => 'Ìtọ́sọ́nà ìrìn ẹsẹ̀';

  @override
  String get wayfindingModeText => 'Ọ̀rọ̀';

  @override
  String get wayfindingModeMap => 'Máàpù';

  @override
  String get wayfindingModeAudio => 'Ohùn';

  @override
  String get wayfindingPlay => 'Ṣe é';

  @override
  String get wayfindingPause => 'Dánudúró';

  @override
  String get wayfindingArrived => 'O ti dé';

  @override
  String get wayfindingDegraded => 'Ìtọ́sọ́nà lè má péye';

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
  String get activeTripExtend => 'Fi kún un';

  @override
  String get activeTripShare => 'Pín';

  @override
  String get activeTripReport => 'Fi ẹ̀sùn sùn';

  @override
  String get tripCompleteTitle => 'Ìrìn-àjò ti parí';

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
  String get extendTripTitle => 'Fa ìrìn gùn';

  @override
  String get extendTripSearchHint => 'Ibo ni báyìí?';

  @override
  String extendTripDestination(String destination) {
    return 'Ń tẹ̀síwájú sí $destination';
  }

  @override
  String get extendTripSend => 'Fi ránṣẹ́ sí awakọ̀';

  @override
  String get incomingExtensionTitle => 'Ìbéèrè ìfagùn';

  @override
  String incomingExtensionBody(String destination, String delta) {
    return 'Awakọ̀ dábàá láti tẹ̀síwájú sí $destination fún +$delta';
  }

  @override
  String get incomingExtensionAccept => 'Gbà';

  @override
  String get incomingExtensionDecline => 'Kọ̀';

  @override
  String get payDriverTitle => 'San owó awakọ̀';

  @override
  String payDriverCta(String amount) {
    return 'San $amount';
  }

  @override
  String get payDriverAmountLocked => 'Owó yìí ti di ti ìrìn yìí';

  @override
  String get payDriverMethodSaved => 'Visa ···4242';

  @override
  String payDriverPending(String amount) {
    return 'Fi $amount ránṣẹ́ nínú áàpù báǹkì rẹ';
  }

  @override
  String get payDriverCopyAccount => 'Da nọ́mbà kọ';

  @override
  String get payDriverAccountCopied => 'A ti da nọ́mbà àkáǹtì kọ';

  @override
  String get payDriverWaitingTransfer => 'Ń dúró de owó tí o fi ránṣẹ́';

  @override
  String get payDriverOtherAmount => 'Òmíràn';

  @override
  String get payDriverOtherHint => 'Tẹ iye owó';

  @override
  String payDriverExpires(int seconds) {
    return 'Yóò parí ní ${seconds}s';
  }

  @override
  String get payDriverOpenCheckout => 'Ṣí ojú-ìwé báǹkì';

  @override
  String get payDriverMethodTransfer => 'Ìfiránṣẹ́ báǹkì';

  @override
  String get payDriverMethodUssd => 'USSD';

  @override
  String get payDriverChangeMethod => 'Yí padà';

  @override
  String payDriverCashOnly(String name) {
    return '$name ń gba owó ọwọ́ nìkan';
  }

  @override
  String get payDriverInactive => 'Kóòdù yìí kò ṣiṣẹ́ mọ́';

  @override
  String get payDriverDifferentDriver =>
      'Ìrìn rẹ lọ́wọ́ wà pẹ̀lú awakọ̀ mìíràn';

  @override
  String get payDriverConfirmOther => 'Kì í ṣe awakọ̀ ìrìn mi — san bẹ́ẹ̀ náà';

  @override
  String get payDriverFailed => 'Ìsanwó kùnà';

  @override
  String get payDriverRetry => 'Tún gbìyànjú';

  @override
  String get payDriverSuccessTitle => 'A ti san án';

  @override
  String payDriverSuccessItemised(
    String driverAmount,
    String name,
    String feeAmount,
  ) {
    return '$driverAmount fún $name · $feeAmount owó Along';
  }

  @override
  String get payDriverHistoryOptIn => 'Fi ìrìn yìí kún ìtàn rẹ?';

  @override
  String get scanToPayTitle => 'Ṣàyẹ̀wò láti sanwó';

  @override
  String get scanEnterCode => 'Tẹ kóòdù dípò';

  @override
  String get scanEnterCodePrompt => 'Tẹ kóòdù awakọ̀';

  @override
  String get scanCodeHint => 'Kóòdù oní-lẹ́tà 8';

  @override
  String get scanCodeSubmit => 'Tẹ̀síwájú';

  @override
  String get scanBackToCamera => 'Padà sí kámẹ́rà';

  @override
  String get scanNotAlong => 'Kì í ṣe kóòdù Along';

  @override
  String get payMethodsTitle => 'Ọ̀nà ìsanwó';

  @override
  String get payMethodsDefault => 'Àkọ́kọ́';

  @override
  String get payMethodsSetDefault => 'Ṣe é ní àkọ́kọ́';

  @override
  String get payMethodsRemove => 'Yọ kúrò';

  @override
  String get payMethodsAdd => 'Fi káàdì kún';

  @override
  String get payMethodsTransferDefault => 'Máa sanwó pẹ̀lú ìfiránṣẹ́';

  @override
  String get activeTripScan => 'Ṣàyẹ̀wò';

  @override
  String get tripsEmpty => 'Kò tíì sí ìrìn tó parí.';

  @override
  String get tripDetailTitle => 'Àlàyé ìrìn';

  @override
  String get tripDetailMissing => 'A kò rí ìrìn náà';

  @override
  String get tripDetailShareReceipt => 'Pín rìsíìtì';

  @override
  String get tripDetailReceiptCopied => 'A ti da rìsíìtì kọ';

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
  String get sosShareWithContact => 'Pín pẹ̀lú olùbásọ̀rọ̀';

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
  String get reportIncidentAttachPhoto => 'So fọ́tò mọ́ ọn';

  @override
  String get reportIncidentSubmit => 'Fi ìròyìn ránṣẹ́';

  @override
  String get reportIncidentPickCategory => 'Yan ẹ̀ka kan';

  @override
  String get reportIncidentDescriptionRequired => 'Fi àlàyé kúkúrú kún';

  @override
  String get reportIncidentSubmitted => 'A ti fi ìròyìn pamọ́ sórí fóònù yìí';

  @override
  String get incidentCategorySafety => 'Ààbò';

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
  String get shareTripTitle => 'Pín ìrìn lọ́wọ́';

  @override
  String get shareTripCreateLink => 'Ṣe ìjápọ̀';

  @override
  String get shareTripCopy => 'Da ìjápọ̀ kọ';

  @override
  String get shareTripSms => 'SMS';

  @override
  String get shareTripCopied => 'A ti da ìjápọ̀ kọ';

  @override
  String get shareTripExpiryNote => 'Ìjápọ̀ máa parí nígbà tí ìrìn rẹ bá parí';

  @override
  String get shareTripActiveHeading => 'Ìpín tó ń ṣiṣẹ́';

  @override
  String get shareTripAnonymousContact => 'Olùbásọ̀rọ̀ tí a pín';

  @override
  String shareTripExpires(String date) {
    return 'Yóò parí $date';
  }

  @override
  String shareTripSmsBody(String url) {
    return 'Tọpa ìrìn Along mi: $url';
  }

  @override
  String get accountProfileHeading => 'ÀPÈJÚWE';

  @override
  String get accountPreferencesHeading => 'ÀṢÀYÀN';

  @override
  String get accountCityLabel => 'Ìlú ilé';

  @override
  String get accountCityHint =>
      'Maapu àti wíwá n lo ìlú yìí nígbà tí a kò leè rí ibùdó';

  @override
  String get accountPaymentHeading => 'ÌSANWÓ';

  @override
  String get accountSafetyHeading => 'ÀÀBÒ';

  @override
  String get accountWayfindingLabel => 'Ọ̀nà ìtọ́sọ́nà';

  @override
  String get accountSortLabel => 'Ètò ìtòlẹ́sẹẹsẹ ìrìn';

  @override
  String get accountWomenOnlyLabel => 'Ìbámu obìnrin nìkan';

  @override
  String get accountWomenOnlyHint =>
      'Fẹ́ràn awakọ̀ obìnrin nígbà tí wọ́n bá wà';

  @override
  String get accountPaymentCashDefault => 'Owó ọwọ́';

  @override
  String get accountPaymentCashHint => 'Ọ̀nà ìsanwó àkọ́kọ́ fún ìrìn Along';

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
  String get homePlanYourDay => 'Ṣètò ọjọ́ rẹ';

  @override
  String get dayPlannerTitle => 'Ètò òní';

  @override
  String get dayPlannerEmpty => 'Kò tíì sí ibùdó nínú ètò rẹ';

  @override
  String get dayPlannerNotBookedHint =>
      'A ti ṣètò ibùdó — ìbámu ń bẹ̀rẹ̀ nígbà tí o bá tẹ Bá mu báyìí. Kò sí ohun tí a fi pamọ́ ṣáájú.';

  @override
  String get dayPlannerLoadToggle => 'Ẹrù òní';

  @override
  String get dayPlannerMatchNow => 'Bá mu báyìí';

  @override
  String get dayPlannerPrepare => 'Múra';

  @override
  String get dayPlannerAddStop => 'Fi ibùdó kún';

  @override
  String get dayPlannerStopDone => 'Ó ti parí';

  @override
  String dayPlannerStopInProgress(int minutes) {
    return 'Ń lọ lọ́wọ́ · ETA $minutes ìṣ';
  }

  @override
  String get dayPlannerStopReady => 'Ó ṣetán — tẹ Bá mu báyìí nísàlẹ̀';

  @override
  String get dayPlannerStopPrepareHint => 'Tẹ Múra nígbà tí o bá ṣetán';

  @override
  String get dayPlannerStopPending => 'Èyí tó kàn';

  @override
  String get dayPlannerStopSkipped => 'A fò ó';

  @override
  String get itineraryEntryTitle => 'Ṣètò ọjọ́ rẹ';

  @override
  String get itineraryEntryStructured => 'Àwọn ibùdó';

  @override
  String get itineraryEntryNaturalLanguage => 'Ṣàpèjúwe';

  @override
  String get itineraryEntryStopHint => 'Ibo ni?';

  @override
  String get itineraryEntryAddRow => 'Fi ibùdó mìíràn kún';

  @override
  String get itineraryEntryDescribeDay => 'Ṣàpèjúwe ọjọ́ rẹ';

  @override
  String get itineraryEntryNlHint =>
      'àpẹẹrẹ kó àwọn ọmọ lọ sí ilé-ìwé, lẹ́yìn náà iṣẹ́, lẹ́yìn náà ọjà';

  @override
  String get itineraryEntryMicTitle => 'Sọ àwọn ibùdó rẹ';

  @override
  String get itineraryEntryMicHint => 'Sọ̀rọ̀ tàbí kọ àwọn ibùdó rẹ…';

  @override
  String get itineraryEntryParse => 'Wo àwọn ibùdó';

  @override
  String get itineraryEntryProposalTitle => 'Ohun tí a gbọ́';

  @override
  String get itineraryEntryUnresolved => 'Ó nílò orúkọ ibì kan';

  @override
  String get itineraryEntryLooksRight => 'Ó tọ́';

  @override
  String get itineraryEntrySavePlan => 'Fi ètò pamọ́';

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
  String get vehiclesTitle => 'Àwọn ọkọ̀';

  @override
  String freeSeatCount(int count) {
    return '$count ṣófo';
  }

  @override
  String get seatStale => 'Máàpù ìjókòó ti ju ìṣẹ́jú kan lọ';

  @override
  String get filterRulesHint => 'Wá òfin awakọ̀';

  @override
  String get seatTaken => 'Wọ́n ṣẹ̀ṣẹ̀ gba ìjókòó yẹn';

  @override
  String get acknowledgeToClaim => 'Mo gbà';

  @override
  String get noVehicles => 'Kò sí ọkọ̀ tó bá òfin wọ̀nyí mu';

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
  String get seatLuggage => 'ẹrù';

  @override
  String get voiceBookingHint => 'Sọ ọ́, fún àpẹẹrẹ Wuse sí Berger';

  @override
  String get textMapTitle => 'Ọkọ̀ nítòsí';

  @override
  String get textMapEmpty => 'Kò tíì sí ọkọ̀ ní ọ̀nà yìí';

  @override
  String get plateCheck => 'Mo rí nọ́mbà yìí';

  @override
  String get plateMatches => 'Nọ́mbà bá a mu';

  @override
  String get plateScan => 'Ṣàyẹ̀wò nọ́mbà';

  @override
  String get plateScanHint => 'Fi nọ́mbà ọkọ̀ sínú férémù';

  @override
  String get plateScanDenied =>
      'Kámẹ́rà ti pa. O ṣì lè jẹ́rìí nọ́mbà ọkọ̀ fúnra rẹ.';

  @override
  String get plateScanMismatch => 'Nọ́mbà yìí kò bá èyí tí a forúkọ sílẹ̀ mu.';

  @override
  String get plateScanReport => 'Jábọ̀';

  @override
  String get plateScanSos => 'SOS';

  @override
  String get plateScanTorch => 'Iná';

  @override
  String get plateScanContinue => 'Tẹ̀síwájú';

  @override
  String get guardianTitle => 'Olùṣọ́';

  @override
  String get guardianEnabled => 'Ṣàyẹ̀wò ìrìn yìí';

  @override
  String get guardianOffRoute => 'Mítà kúrò lọ́nà';

  @override
  String get guardianLongStop => 'Ìṣẹ́jú ìdúró gígùn';

  @override
  String get guardianCheckIn => 'Ìṣẹ́jú àyẹ̀wò';

  @override
  String get guardianSafeWord => 'Ọ̀rọ̀ ààbò';

  @override
  String get guardianSave => 'Fi pamọ́';

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
  String get tripMessagesTitle => 'Fi ọ̀rọ̀ ránṣẹ́ sí awakọ̀';

  @override
  String get tripMessagesClosed => 'A ti pa ìjíròrò yìí.';

  @override
  String get tripMessagesDriver => 'Awakọ̀';

  @override
  String get tripMessagesRider => 'Ìwọ';

  @override
  String get tripMessagesHint => 'Àkọsílẹ̀ nípa ohun tí o fi sílẹ̀';

  @override
  String get tripMessagesSend => 'Fi ránṣẹ́';

  @override
  String get holdNotOffered => 'Awakọ̀ yìí kò tan ìdìmú ìjókòó';

  @override
  String get walkExtension => 'Ìṣẹ́jú tí o nílò láti rìn';

  @override
  String get stageRadarTitle => 'Pátákó ibùdókọ̀';

  @override
  String get stageRadarLeaving => 'Ó ń lọ tẹ̀lé';

  @override
  String stageRadarSeats(int free, int total) {
    return '$free nínú $total ṣófo';
  }

  @override
  String get stageRadarEmpty => 'Kò tíì sí ọkọ̀ tó ń kó èrò níbí';

  @override
  String get stageRadarVerified => 'A ti jẹ́rìí';

  @override
  String get stageRadarFavourite => 'Fi awakọ̀ pamọ́';

  @override
  String get fareShieldTitle => 'Owó ọkọ̀ tó tọ́';

  @override
  String get fareShieldQuiet => 'Ìrìn kò tíì tó ní ọ̀nà yìí';

  @override
  String get fareShieldDispute => 'Owó yìí ti pọ̀ jù';

  @override
  String fareShieldAnchored(int seconds) {
    return 'Ìfilọ̀ kan, ó ṣí fún ìṣẹ́jú-àáyá $seconds';
  }

  @override
  String get fareHistoryTitle => 'Ní wákàtí';

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
    return '$first–$last';
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

  @override
  String get tripEtaCalculating => 'À ń ṣírò…';

  @override
  String get activeTripCall => 'Pè é';

  @override
  String get activeTripSos => 'Di mú fún SOS';

  @override
  String get activeTripNaMe => 'Fi Na Me hàn';

  @override
  String get tripCompleteSettleQuestion => 'Ṣé o ti san owó yìí?';

  @override
  String tripCompletePayHint(String driver) {
    return 'San owó fún $driver nínú áàpù, tàbí sọ fún wa pé o san owó lọ́wọ́.';
  }

  @override
  String get meetVehicleNaMeShow => 'Gbé e sókè kí awakọ̀ rẹ lè rí ọ';

  @override
  String get reportIncidentSubtitle =>
      'Sọ ohun tó ṣẹlẹ̀ fún wa. Ẹgbẹ́ ààbò wa ń ka gbogbo ìròyìn.';

  @override
  String get shareTripRevoke => 'Dá pínpín dúró';

  @override
  String tripsRowDetail(String first, String second) {
    return '$first · $second';
  }

  @override
  String get tripDriverFallback => 'Awakọ̀ rẹ';

  @override
  String get tripsLoadFailed =>
      'A kò lè gbé àwọn ìrìn rẹ wá. Gbìyànjú lẹ́ẹ̀kan sí i.';

  @override
  String get tripHoldForSos => 'Dì í mú fún SOS';

  @override
  String get tripNaMe => 'Èmi Nìyí';

  @override
  String get tripCall112 => 'Pe 112';

  @override
  String get tripSignalSent => 'Ti fi ránṣẹ́';

  @override
  String get fareTierVerified => 'Owó ọkọ̀ déédé';

  @override
  String get fareTierCrowd => 'Owó tí àwọn èèyàn ń san';

  @override
  String get fareTierCandidate => 'Kò tíì dájú';

  @override
  String get fareTierEstimate => 'Ìfojúdíwọ̀n, ẹ fohùn ṣọ̀kan';

  @override
  String get receiptExtension => 'Ìfàgùn ìrìn';

  @override
  String receiptIncludesFee(String amount) {
    return 'Ó ní owó Along $amount nínú';
  }

  @override
  String get receiptShareHeader => 'Ìwé owó ìrìn Along';

  @override
  String get tripStatusCompleted => 'Ti parí';

  @override
  String get extendTripNowFare => 'Owó ọkọ̀ lọ́wọ́lọ́wọ́';

  @override
  String get extendTripNewTotal => 'Àpapọ̀ tuntun';

  @override
  String get extendTripDriverConfirms =>
      'Awakọ̀ rẹ yóò fọwọ́ sí i kí ohunkóhun tó yí padà';

  @override
  String get scanToPayHint => 'Dojú kámẹ́rà kọ koodu Along awakọ̀';

  @override
  String get scanTorch => 'Iná tọ́ọ̀ṣì';

  @override
  String get payMethodsSubtitle => 'Yan bí o ṣe ń sanwó fún awakọ̀';

  @override
  String get payMethodsSectionDefault => 'Sanwó fún awakọ̀ pẹ̀lú';

  @override
  String get payMethodsTransferHint =>
      'Sanwó láti inú app báńkì rẹ, kò sí kádì';

  @override
  String get payMethodsCards => 'Àwọn kádì tí a fipamọ́';

  @override
  String get payMethodsCardsEmpty => 'Kò sí kádì tí a fipamọ́ síbẹ̀';

  @override
  String get payMethodsSecure =>
      'Orúkọ kádì àti nọ́mbà 4 tó kẹ́yìn nìkan la ń tọ́jú';

  @override
  String wayfindingTo(String place) {
    return 'Sí $place';
  }

  @override
  String wayfindingSummary(String distance, int minutes) {
    return '$distance · ìrìn ìṣẹ́jú $minutes';
  }

  @override
  String get wayfindingAudioPlaying => 'Ohùn ń ṣiṣẹ́';

  @override
  String get wayfindingNowPlaying => 'Ń ṣiṣẹ́ báyìí';

  @override
  String get wayfindingYouAreHere => 'O wà níbí';

  @override
  String wayfindingStepOf(int step, int total) {
    return 'Ìgbésẹ̀ $step nínú $total';
  }

  @override
  String get wayfindingIveArrived => 'Mo ti dé';

  @override
  String get scanFitHint => 'Fi koodu sí àárín àwọn igun';

  @override
  String get scanFound => 'A ti rí koodu';

  @override
  String get requestingNextTitle => 'Ohun tó kàn';

  @override
  String get requestingStepSent =>
      'A ti fi ìbéèrè ránṣẹ́ sí awakọ̀ tó wà nítòsí';

  @override
  String get requestingStepAccept => 'Awakọ̀ gbà á, o máa rí nọ́ńbà ọkọ̀ rẹ̀';

  @override
  String requestingStepMeet(String place) {
    return 'Pàdé wọn ní $place';
  }

  @override
  String get tripGlanceTitle => 'Ìrìnàjò rẹ';

  @override
  String tripGlanceWalk(String place) {
    return 'Rìn lọ sí $place';
  }

  @override
  String get tripGlanceWait => 'Dúró de ọkọ̀ rẹ';

  @override
  String tripGlanceRide(String place) {
    return 'Wọ ọkọ̀ lọ sí $place';
  }

  @override
  String tripGlanceMinutes(int minutes) {
    return 'ìṣẹ́jú $minutes';
  }

  @override
  String get tripsSummaryTitle => 'Ìrìnàjò àìpẹ́';

  @override
  String tripsSummaryCount(int count) {
    return 'Ìrìnàjò $count';
  }

  @override
  String tripsSummarySpent(String amount) {
    return 'O ti san $amount';
  }

  @override
  String get tripsEmptyHint =>
      'Ìrìnàjò tí o bá ṣe pẹ̀lú Along máa hàn níbí, pẹ̀lú ìwé ẹ̀rí.';

  @override
  String get tripsEmptyCta => 'Ṣètò ìrìnàjò';

  @override
  String get scanCodeWhereTitle => 'Ibi tí o ti máa rí i';

  @override
  String get scanCodeWhereBody =>
      'Kóòdù oní lẹ́tà 8 wà lábẹ́ QR lórí sítíkà awakọ̀, tàbí ní kí ó ṣí My QR.';

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
  String get searchPausedTitle => 'Ìwádìí dúró';

  @override
  String get searchPausedBody =>
      'Íntánẹ́ẹ̀tì já. Àwọn ibi tí a fipamọ́ àti máàpù ṣì ń ṣiṣẹ́.';

  @override
  String get searchEmptyTitle => 'A kò rí ibìkan';

  @override
  String get searchEmptyBody =>
      'Gbìyànjú àmì-ilẹ̀, ọjà tàbí ibùdókọ̀ tó wà nítòsí.';

  @override
  String get searchEmptyOfflineBody =>
      'O kò sí lórí íntánẹ́ẹ̀tì, ibi tí a fipamọ́ nìkan ló ń hàn. Fi pin sí i dípò.';

  @override
  String connNeedsConnection(int count) {
    return 'Kò sí íntánẹ́ẹ̀tì · $count láti tún ṣe lórí ayélujára';
  }

  @override
  String connOfflineMixed(int queued, int needs) {
    return 'Kò sí íntánẹ́ẹ̀tì · $queued láti fi ránṣẹ́ · $needs láti tún ṣe';
  }

  @override
  String get walletTitle => 'Àpamọ́wọ́';

  @override
  String get walletSubtitle => 'Owó Along';

  @override
  String get walletBalance => 'Iye tó kù';

  @override
  String get walletBalanceNote => 'Ó wà nínú Along';

  @override
  String get walletAddCredit => 'Fi owó kún';

  @override
  String get walletCustom => 'Tìrẹ';

  @override
  String get walletHistory => 'Ìtàn';

  @override
  String get walletHistoryEmpty =>
      'Kò sí owó síbẹ̀. Ìfikún, owó ọkọ̀ àti ìdápadà yóò hàn níbí.';

  @override
  String get walletAddCustom => 'Fi iye tí o fẹ́ kún';

  @override
  String walletAdd(String amount) {
    return 'Fi $amount kún';
  }

  @override
  String get walletTopUp => 'Ìfikún';

  @override
  String get walletFare => 'Owó ọkọ̀';

  @override
  String get walletRefund => 'Ìdápadà';

  @override
  String get walletToday => 'Lónìí';

  @override
  String get walletYesterday => 'Àná';

  @override
  String get walletUnavailable => 'Àpamọ́wọ́ kò ṣí';

  @override
  String get walletUnavailableBody =>
      'Owó rẹ wà láìléwu. Ṣàyẹ̀wò íntánẹ́ẹ̀tì kí o tún gbìyànjú.';

  @override
  String get walletRetry => 'Tún gbìyànjú';

  @override
  String get walletCustomTitle => 'Èló ni?';

  @override
  String get walletCustomHint => '₦100 sí ₦50,000';

  @override
  String get walletCustomTooSmall => 'Ó kéré tán ₦100';

  @override
  String get walletCustomTooLarge => 'Ó pọ̀ jù ₦50,000';

  @override
  String get walletCancel => 'Fagilé';

  @override
  String walletAdded(String amount) {
    return 'A ti fi $amount kún';
  }

  @override
  String get walletTopUpFailed => 'Kò sí ohun tí a fi kún. Tún gbìyànjú.';

  @override
  String get walletActionTopUp => 'Fi owó kún';

  @override
  String get walletActionSend => 'Fi ránṣẹ́';

  @override
  String get walletActionPass => 'Pass';

  @override
  String get walletActionSplit => 'Pín';

  @override
  String get walletActivity => 'Ìṣe';

  @override
  String get walletEarlier => 'Tẹ́lẹ̀';

  @override
  String get walletActivityEmpty =>
      'Kò sí ìṣe síbẹ̀. Fi owó kún láti rìn láìsí owó ọwọ́.';

  @override
  String walletBalanceSemantics(String amount) {
    return 'Iye tó kù $amount';
  }

  @override
  String walletSentTo(String name) {
    return 'Sí $name';
  }

  @override
  String walletReceivedFrom(String name) {
    return 'Láti ọ̀dọ̀ $name';
  }

  @override
  String get walletSent => 'Ti fi ránṣẹ́';

  @override
  String get walletReceived => 'Ti gbà';

  @override
  String get walletPassEntry => 'Along Pass';

  @override
  String get walletSplitPaid => 'Ti san ìpín';

  @override
  String get walletSplitReceived => 'Ti gba ìpín';

  @override
  String walletOwedTitle(String name, String amount) {
    return '$name béèrè $amount';
  }

  @override
  String get walletOwedBody => 'Ìpín rẹ nínú ìrìn àjọpín';

  @override
  String get walletOwedPay => 'San';

  @override
  String get walletOwedDecline => 'Kọ̀';

  @override
  String walletOwedPaidSnack(String amount) {
    return 'Ti san $amount';
  }

  @override
  String get walletOwedDeclinedSnack => 'A kọ ìbéèrè';

  @override
  String get walletInsufficient => 'Owó kò tó. Kọ́kọ́ fi owó kún.';

  @override
  String get walletActionFailed =>
      'Kò parí. Gbìyànjú lẹ́ẹ̀kan sí i — a kò ní gbà lẹ́ẹ̀mejì.';

  @override
  String get walletSendTitle => 'Fi owó ránṣẹ́';

  @override
  String get walletSendSubtitle => 'Sí arìnrìn-àjò Along mìíràn';

  @override
  String get walletSendPhone => 'Nọ́mbà fóònù';

  @override
  String get walletSendPhoneHint => '0803 123 4567';

  @override
  String get walletSendPhoneInvalid => 'Tẹ nọ́mbà fóònù Nàìjíríà';

  @override
  String get walletSendAmount => 'Iye';

  @override
  String get walletSendTooSmall => 'Fi ₦50 ránṣẹ́ ó kéré tán';

  @override
  String get walletSendTooLarge => 'Má ṣe ju ₦50,000 lọ';

  @override
  String get walletSendOverBalance => 'Ó ju iye tó kù lọ';

  @override
  String walletSendCta(String amount) {
    return 'Fi $amount ránṣẹ́';
  }

  @override
  String get walletSendCtaEmpty => 'Fi ránṣẹ́';

  @override
  String get walletSendNotFound => 'Kò sí arìnrìn-àjò Along tó ní nọ́mbà yẹn';

  @override
  String walletSentSnack(String amount) {
    return 'Ti fi $amount ránṣẹ́';
  }

  @override
  String walletAvailable(String amount) {
    return 'Ó wà $amount';
  }

  @override
  String get walletPassTitle => 'Along Pass';

  @override
  String get walletPassSubtitle => 'Ìrìn tí o ti san ṣáájú láti owó rẹ';

  @override
  String walletPassPrice(String amount) {
    return '$amount lóṣooṣù';
  }

  @override
  String get walletPassBody =>
      'Ìsanwó kan láti inú wọ́lẹ́ẹ̀tì rẹ. Kò sí káàdì, kò sí owó ọwọ́ ní ẹnu ọ̀nà.';

  @override
  String walletPassCta(String amount) {
    return 'Ra pass · $amount';
  }

  @override
  String get walletPassBought => 'Pass ń ṣiṣẹ́ · Ó parí';

  @override
  String walletPassShort(String amount) {
    return 'Fi $amount sí i láti rà á';
  }

  @override
  String get walletSplitTitle => 'Pín owó ọkọ̀';

  @override
  String get walletSplitSubtitle => 'Béèrè ìpín lọ́wọ́ àwọn alábàárìn';

  @override
  String get walletSplitFare => 'Owó ọkọ̀';

  @override
  String get walletSplitYou => 'Ìwọ';

  @override
  String walletSplitCoRider(int n) {
    return 'Alábàárìn $n';
  }

  @override
  String get walletSplitAdd => 'Fi alábàárìn kún';

  @override
  String get walletSplitRemove => 'Yọ kúrò';

  @override
  String walletSplitEach(String amount) {
    return '$amount ẹnì kọ̀ọ̀kan';
  }

  @override
  String walletSplitCta(String amount) {
    return 'Béèrè $amount ẹnì kọ̀ọ̀kan';
  }

  @override
  String get walletSplitCtaEmpty => 'Béèrè ìpín';

  @override
  String get walletSplitFareInvalid => 'Tẹ owó ọkọ̀, ó kéré tán ₦100';

  @override
  String walletSplitSentSnack(int count) {
    return 'A béèrè lọ́wọ́ alábàárìn $count';
  }

  @override
  String get walletSplitNotFound =>
      'Ọ̀kan nínú nọ́mbà yẹn kò tíì wà lórí Along';

  @override
  String get walletSplitNote =>
      'Wọn yóò san láti inú wọ́lẹ́ẹ̀tì wọn. Ìwọ yóò máa san awakọ̀ bí ti tẹ́lẹ̀.';

  @override
  String get accountWallet => 'Wọ́lẹ́ẹ̀tì';

  @override
  String get accountWalletHint => 'Fi owó kún, fi ránṣẹ́, pass, pín owó ọkọ̀';

  @override
  String get walletPassPlanWeek => 'Ọ̀sẹ̀';

  @override
  String get walletPassPlanPack => 'Ìrìn 5';

  @override
  String get walletPassPlanMonth => 'Oṣù';

  @override
  String walletPassRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ìrìn $count',
      one: 'Ìrìn 1',
    );
    return '$_temp0';
  }

  @override
  String walletPassValidity(int days) {
    return 'Ó wúlò fún ọjọ́ $days';
  }

  @override
  String walletPassPerRide(String amount) {
    return '$amount ìrìn kan';
  }

  @override
  String get walletPassVersus => 'Ní ìfiwéra pẹ̀lú owó ìrìn kọ̀ọ̀kan';

  @override
  String walletPassSingleRow(int count, String fare) {
    return '$count × $fare kọ̀ọ̀kan';
  }

  @override
  String get walletPassPassRow => 'Pass';

  @override
  String walletPassSave(String amount) {
    return 'O fi $amount pamọ́';
  }

  @override
  String get walletPassNoSave => 'Kò sí ìfipamọ́ ní owó ìrìn rẹ tó wọ́pọ̀';

  @override
  String get walletPassNoHistory =>
      'Ìfipamọ́ yóò hàn lẹ́yìn owó ìrìn àkọ́kọ́ láti wallet';

  @override
  String walletPassUsualFare(String amount) {
    return 'Owó ìrìn rẹ tó wọ́pọ̀ jẹ́ $amount';
  }

  @override
  String walletPassActive(String date) {
    return 'Ó ń ṣiṣẹ́ títí $date';
  }

  @override
  String walletSplitNotFoundNumber(String phone) {
    return '$phone kò sí lórí Along síbẹ̀';
  }

  @override
  String get walletSplitNotOnAlong => 'Kò sí lórí Along síbẹ̀';

  @override
  String get walletSplitRequests => 'Àwọn ìbéèrè rẹ';

  @override
  String get walletSplitPending => 'Ń dúró';

  @override
  String get walletSplitPaidStatus => 'Ti san';

  @override
  String get walletSplitDeclined => 'Kọ̀';

  @override
  String get walletPassSaveLabel => 'Ìfipamọ́ rẹ';

  @override
  String get walletPassHow => 'Bí ó ṣe ń ṣiṣẹ́';

  @override
  String get walletPassStep1 => 'Yan ètò lókè';

  @override
  String get walletPassStep2 => 'San lẹ́ẹ̀kan láti owó Along rẹ. Kò nílò káàdì';

  @override
  String walletPassStep3(int days) {
    return 'Yóò ṣiṣẹ́ fún ọjọ́ $days láti òní';
  }

  @override
  String get walletPassDetails => 'Àlàyé';

  @override
  String get walletPassRowRides => 'Ìrìn';

  @override
  String get walletPassRowValid => 'Wúlò títí';

  @override
  String get walletPassRowPaid => 'A san pẹ̀lú';

  @override
  String get walletPassRowPaidValue => 'Owó Along';

  @override
  String get sosTitle => 'Ààbò';

  @override
  String get sosStatusSending => 'À ń sọ fún ẹgbẹ́ ààbò Along…';

  @override
  String sosStatusSent(String time) {
    return 'A ti sọ fún ẹgbẹ́ ààbò · $time';
  }

  @override
  String get sosStatusQueued =>
      'Kò sí àmì · a ti fi pamọ́, yóò lọ tí ó bá padà';

  @override
  String get sosStatusFailed => 'Kò lọ · pe 112 báyìí';

  @override
  String get sosHoldHint => 'Di mú láti pè';

  @override
  String get sosMapLive => 'Láàyè';

  @override
  String get sosContactsTitle => 'Àwọn olùbásọ̀rọ̀';

  @override
  String get sosNoContacts => 'Kò sí olùbásọ̀rọ̀ tí o gbẹ́kẹ̀lé síbẹ̀';

  @override
  String get sosAddContact => 'Fi kún';

  @override
  String get sosShareLive => 'Pín ìrìn àjò láàyè';

  @override
  String get sosImSafe => 'Mo wà láìléwu';

  @override
  String get sosImSafeTitle => 'Fagilé ìkìlọ̀ náà?';

  @override
  String get sosImSafeBody =>
      'Ẹgbẹ́ ààbò yóò dẹ́kun títẹ̀lé ìrìn àjò yìí. Fagilé nìkan tí o bá wà láìléwu.';

  @override
  String get sosImSafeConfirm => 'Bẹ́ẹ̀ni, mo wà láìléwu';

  @override
  String get sosKeepAlert => 'Fi ìkìlọ̀ sílẹ̀';

  @override
  String sosReach(String name) {
    return 'Kàn sí $name';
  }

  @override
  String get guardianShareSubtitle =>
      'Jẹ́ kí ẹni tí o gbẹ́kẹ̀lé tẹ̀lé ìrìn àjò yìí';

  @override
  String guardianShareWatching(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ènìyàn $count ń rí ìrìn àjò yìí',
      one: 'Ènìyàn 1 ń rí ìrìn àjò yìí',
    );
    return '$_temp0';
  }

  @override
  String get guardianShareWho => 'Ta ló lè tẹ̀lé';

  @override
  String get guardianShareNoContacts =>
      'Fi olùbásọ̀rọ̀ kan kún láti pín pẹ̀lú ìfọwọ́kàn kan';

  @override
  String get guardianShareAddContact => 'Fi olùbásọ̀rọ̀ kún';

  @override
  String get guardianSharePlate => 'Pín nọ́mbà ọkọ̀';

  @override
  String get guardianShareLocation => 'Pín ibi tí o wà láàyè';

  @override
  String get guardianShareExpiry => 'Dúró lẹ́yìn';

  @override
  String get guardianShare30 => 'Ìṣẹ́jú 30';

  @override
  String get guardianShare60 => 'Wákàtí 1';

  @override
  String get guardianShareTripEnd => 'Ìrìn parí';

  @override
  String guardianShareCta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pín pẹ̀lú ènìyàn $count',
      one: 'Pín pẹ̀lú ènìyàn 1',
      zero: 'Ṣe ìjápọ̀ ìpín',
    );
    return '$_temp0';
  }

  @override
  String get guardianShareStop => 'Dẹ́kun pípín';

  @override
  String guardianShareUntil(String time) {
    return 'Títí di $time';
  }

  @override
  String get guardianShareWhatsapp => 'WhatsApp';

  @override
  String get guardianShareOffline =>
      'Pípín nílò ìsopọ̀. SOS ṣì ń ṣiṣẹ́ láìsí ìsopọ̀.';

  @override
  String get guardianShareFailed =>
      'Kò lè bẹ̀rẹ̀ pípín. Gbìyànjú lẹ́ẹ̀kan sí i.';

  @override
  String get guardianShareStopped => 'A ti dẹ́kun pípín';

  @override
  String get guardianShareNoTrip => 'Pípín ń bẹ̀rẹ̀ nígbà tí o bá wà nínú ìrìn';

  @override
  String get reportIncidentPhotosHeading => 'Àwòrán';

  @override
  String get reportIncidentPhotosNote =>
      'Títí di 4 · ẹgbẹ́ ààbò wa nìkan ló ń rí wọn';

  @override
  String get reportIncidentAddPhoto => 'Fi àwòrán kún';

  @override
  String get reportIncidentTakePhoto => 'Ya àwòrán';

  @override
  String get reportIncidentChoosePhoto => 'Yan láti inú àwòrán';

  @override
  String reportIncidentRemovePhoto(int n) {
    return 'Yọ àwòrán $n kúrò';
  }

  @override
  String reportIncidentUploading(int done, int total) {
    return 'À ń fi àwòrán $done nínú $total ránṣẹ́';
  }

  @override
  String get reportIncidentSent =>
      'A ti fi ìròyìn ránṣẹ́. Ẹgbẹ́ ààbò wa yóò tẹ̀lé e.';

  @override
  String get reportIncidentQueued =>
      'Kò sí àmì. A ti fi ìròyìn pamọ́, yóò lọ tí ó bá padà.';

  @override
  String get reportIncidentFailed =>
      'Kò lè fi ìròyìn ránṣẹ́. Gbìyànjú lẹ́ẹ̀kan sí i.';

  @override
  String get reportIncidentPhotoError => 'Kò lè fi àwòrán náà kún';

  @override
  String optionCardRouteLine(String board, String alight) {
    return 'Wọ̀ ní $board → $alight';
  }
}
