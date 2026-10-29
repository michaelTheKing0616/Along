// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hausa (`ha`).
class AppLocalizationsHa extends AppLocalizations {
  AppLocalizationsHa([String locale = 'ha']) : super(locale);

  @override
  String get phoneEntryTitle => 'Yi tafiya. Yadda kake so.';

  @override
  String get phoneEntrySubtitle =>
      'Za mu tura lamba zuwa wannan lambar don hawan ya zama naka.';

  @override
  String get continueButton => 'Ci gaba';

  @override
  String get legalPrefix => 'Idan ka ci gaba, ka amince da ';

  @override
  String get termsLink => 'Sharuɗɗa';

  @override
  String get legalMiddle => ' da ';

  @override
  String get privacyLink => 'Manufar Sirri';

  @override
  String otpTitle(String phone) {
    return 'Shigar da lambar lamba 6 da aka tura zuwa $phone';
  }

  @override
  String get wrongNumber => 'Lambar ba daidai ba?';

  @override
  String get resendCode => 'Sake tura lamba';

  @override
  String resendCountdown(int seconds) {
    return 'Sake tura cikin ${seconds}s';
  }

  @override
  String get nameTitle => 'Me direbobi za su kira ka?';

  @override
  String get nameHint => 'Sunanka';

  @override
  String get skip => 'Tsallake';

  @override
  String get errorInvalidPhone => 'Shigar da lambar Najeriya mai inganci';

  @override
  String errorRateLimited(int seconds) {
    return 'Ƙoƙari ya yi yawa. Sake gwadawa cikin ${seconds}s';
  }

  @override
  String get errorWrongOtp => 'Lambar ba daidai ba — sake gwadawa';

  @override
  String get errorExpiredOtp => 'Lambar ta ƙare — nemi sabuwa';

  @override
  String get errorGeneric => 'Wani abu ya faru. Da fatan a sake gwadawa.';

  @override
  String get errorAuthNotConfigured =>
      'Wannan ginin ba a haɗa shi da Along ba. Sake gina staging APK da env/staging.json.';

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
  String get homeVehicles => 'Motoci';

  @override
  String get homeRecenter => 'Koma tsakiya';

  @override
  String get guardianIntro =>
      'Duba lafiyarka a wannan tafiya, sai lokacin da ka nema.';

  @override
  String get homeLocationDeniedBanner => 'Kunna wuri don ganin motoci kusa';

  @override
  String get homeChooseOnMap => 'Zaɓa a taswira';

  @override
  String get homeNearbyTitle => 'Kusa';

  @override
  String homeNearbyRow(
    String countBucket,
    String mode,
    String heading,
    int minutes,
  ) {
    return '$countBucket $mode kusa · zuwa $heading · ~$minutes min';
  }

  @override
  String get modeKeke => 'keke';

  @override
  String get searchTitle => 'Ina za ka?';

  @override
  String get searchRecentsTitle => 'Na kwanan nan';

  @override
  String get searchResultsTitle => 'Sakamako';

  @override
  String get searchOfflineHint =>
      'Babu intanet · ana nema a wuraren da aka adana';

  @override
  String get cachedOptionsStaleBadge => 'An adana · ƙila ya tsufa';

  @override
  String get adjustPickupTitle => 'Gyara wurin ɗauka';

  @override
  String adjustPickupBoardingAt(String stageName) {
    return 'Hawa a: $stageName';
  }

  @override
  String get adjustPickupConfirm => 'Tabbatar da wuri';

  @override
  String get tripOptionsHeading => 'Zaɓi yadda za ka tafi';

  @override
  String get tripOptionsDegradedBanner => 'Babu lokutan kai tsaye';

  @override
  String get tripOptionsSlowerDirectCaption => 'Ya fi hanyoyin sauyawa jinkiri';

  @override
  String get tripOptionsAgreePrice => 'Yarda da farashi';

  @override
  String get pricingTitle => 'Farashin Along';

  @override
  String get pricingLapsed => 'Babu yarjejeniya — gwada wata mota';

  @override
  String get pricingOutOfRange => 'Motar ta wuce';

  @override
  String get pricingDeclined => 'An ƙi tayin';

  @override
  String pricingDriverOffer(String amount) {
    return 'Direba ya ba da $amount';
  }

  @override
  String get hailSearchTitle => 'Ina za ka?';

  @override
  String get requestUndoMessage => 'Ana nema…';

  @override
  String get loadFlagTitle => 'Kana ɗauke da kaya?';

  @override
  String get loadFlagSizeSmall => 'Ƙarami';

  @override
  String get loadFlagSizeMedium => 'Matsakaici';

  @override
  String get loadFlagSizeLarge => 'Babba';

  @override
  String get loadFlagNoteHint => 'Bayani na zaɓi (haruffa 140)';

  @override
  String get loadFlagRememberDay => 'Tuna don yau';

  @override
  String get loadFlagCapacityWarning =>
      'Wannan hanyar ƙila ba za ta ɗauki kayanka ba';

  @override
  String get loadFlagRequestAnyway => 'Nema duk da haka';

  @override
  String get loadFlagDone => 'An gama';

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
  String get coverageGapTitle => 'Babu hanyoyin da aka zana a nan tukuna';

  @override
  String coverageGapNearestBoarding(String name, String distance) {
    return 'Tasha mafi kusa: $name · $distance';
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
  String get coverageGapVehiclesNone => 'Motoci kusa: babu';

  @override
  String coverageGapVehiclesNearby(int count) {
    return 'Motoci kusa: $count';
  }

  @override
  String get coverageGapWalkThere => 'Tafi da ƙafa';

  @override
  String get coverageGapTellUs => 'Faɗa mana game da wannan yanki';

  @override
  String get coverageGapThanks => 'Na gode — mun rubuta rahotonka';

  @override
  String get tripOptionsWhy => 'Me ya sa?';

  @override
  String get tripOptionsWhyTitle => 'Dalilin shawarar';

  @override
  String get tripOptionsWhyFare => 'Kuɗin mota';

  @override
  String get tripOptionsWhyTime => 'Lokaci';

  @override
  String get tripOptionsWhyEffort => 'Wahala';

  @override
  String get tripOptionsShowLegs => 'Nuna sassa';

  @override
  String get tripOptionsHideLegs => 'Ɓoye sassa';

  @override
  String tripOptionsRequestLeg(int leg, String fare) {
    return 'Nemi sashi $leg · $fare';
  }

  @override
  String get transferTitle => 'Sashi na gaba';

  @override
  String get transferNextLegTitle => 'Sashi na gaba';

  @override
  String transferSupply(String bucket) {
    return '$bucket ana lodi';
  }

  @override
  String get transferRequestNextLeg => 'Nemi sashi na gaba';

  @override
  String get transferChangePlan => 'Canza shiri';

  @override
  String get transferWalkLoading => 'Ana lodi kwatancen tafiya da ƙafa…';

  @override
  String get wayfindingTitle => 'Kwatance tafiya da ƙafa';

  @override
  String get wayfindingModeText => 'Rubutu';

  @override
  String get wayfindingModeMap => 'Taswira';

  @override
  String get wayfindingModeAudio => 'Sauti';

  @override
  String get wayfindingPlay => 'Kunna';

  @override
  String get wayfindingPause => 'Dakata';

  @override
  String get wayfindingArrived => 'An iso';

  @override
  String get wayfindingDegraded => 'Kwatance ƙila ba daidai ba ne';

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
  String get extendTripTitle => 'Tsawaita tafiya';

  @override
  String get extendTripSearchHint => 'Ina yanzu?';

  @override
  String extendTripDestination(String destination) {
    return 'Ana ci gaba zuwa $destination';
  }

  @override
  String get extendTripSend => 'Tura wa direba';

  @override
  String get incomingExtensionTitle => 'Buƙatar tsawaitawa';

  @override
  String incomingExtensionBody(String destination, String delta) {
    return 'Direba yana so a ci gaba zuwa $destination kan +$delta';
  }

  @override
  String get incomingExtensionAccept => 'Karɓa';

  @override
  String get incomingExtensionDecline => 'Ƙi';

  @override
  String get payDriverTitle => 'Biya direba';

  @override
  String payDriverCta(String amount) {
    return 'Biya $amount';
  }

  @override
  String get payDriverAmountLocked => 'An kulle kuɗin ga wannan tafiya';

  @override
  String get payDriverMethodSaved => 'Visa ···4242';

  @override
  String payDriverPending(String amount) {
    return 'Tura $amount a manhajar bankinka';
  }

  @override
  String get payDriverCopyAccount => 'Kwafi lamba';

  @override
  String get payDriverAccountCopied => 'An kwafi lambar asusu';

  @override
  String get payDriverWaitingTransfer => 'Ana jiran turawarka';

  @override
  String get payDriverOtherAmount => 'Wani';

  @override
  String get payDriverOtherHint => 'Shigar da kuɗi';

  @override
  String payDriverExpires(int seconds) {
    return 'Zai ƙare cikin ${seconds}s';
  }

  @override
  String get payDriverOpenCheckout => 'Buɗe shafin banki';

  @override
  String get payDriverMethodTransfer => 'Turawar banki';

  @override
  String get payDriverMethodUssd => 'USSD';

  @override
  String get payDriverChangeMethod => 'Canza';

  @override
  String payDriverCashOnly(String name) {
    return '$name tsabar kuɗi kawai yake karɓa';
  }

  @override
  String get payDriverInactive => 'Wannan lambar ba ta aiki yanzu';

  @override
  String get payDriverDifferentDriver =>
      'Tafiyarka ta yanzu tana tare da wani direba';

  @override
  String get payDriverConfirmOther =>
      'Ba direban tafiyata ba ne — biya duk da haka';

  @override
  String get payDriverFailed => 'Biyan bai yi nasara ba';

  @override
  String get payDriverRetry => 'Sake gwadawa';

  @override
  String get payDriverSuccessTitle => 'An biya';

  @override
  String payDriverSuccessItemised(
    String driverAmount,
    String name,
    String feeAmount,
  ) {
    return '$driverAmount ga $name · $feeAmount kuɗin Along';
  }

  @override
  String get payDriverHistoryOptIn => 'Ƙara wannan tafiya a tarihinka?';

  @override
  String get scanToPayTitle => 'Duba don biya';

  @override
  String get scanEnterCode => 'Shigar da lamba maimakon haka';

  @override
  String get scanEnterCodePrompt => 'Shigar da lambar direba';

  @override
  String get scanCodeHint => 'Lamba mai haruffa 8';

  @override
  String get scanCodeSubmit => 'Ci gaba';

  @override
  String get scanBackToCamera => 'Koma kyamara';

  @override
  String get scanNotAlong => 'Ba lambar Along ba ce';

  @override
  String get payMethodsTitle => 'Hanyoyin biya';

  @override
  String get payMethodsDefault => 'Na asali';

  @override
  String get payMethodsSetDefault => 'Sanya a matsayin asali';

  @override
  String get payMethodsRemove => 'Cire';

  @override
  String get payMethodsAdd => 'Ƙara kati';

  @override
  String get payMethodsTransferDefault => 'Biya da turawa a matsayin asali';

  @override
  String get activeTripScan => 'Duba';

  @override
  String get tripsEmpty => 'Babu tafiyar da aka kammala tukuna.';

  @override
  String get tripDetailTitle => 'Bayanan tafiya';

  @override
  String get tripDetailMissing => 'Ba a sami tafiyar ba';

  @override
  String get tripDetailShareReceipt => 'Raba rasit';

  @override
  String get tripDetailReceiptCopied => 'An kwafi rasit';

  @override
  String get sosTeamAlerted => 'A shirye don kiran 112';

  @override
  String get sosSharingDetails => 'Raba wurinka kai tsaye da abokan hulɗarka';

  @override
  String sosCallEmergency(String number) {
    return 'Kira $number';
  }

  @override
  String get sosShareWithContact => 'Raba da abokin hulɗa';

  @override
  String get sosHoldToCancel => 'Riƙe don soke';

  @override
  String get sosRaising => 'Ana buɗe kiran 112…';

  @override
  String get sosRaiseFailed => 'Ba a iya buɗe kiran 112 ba';

  @override
  String get sosRetry => 'Sake gwadawa';

  @override
  String get reportIncidentTitle => 'Kai rahoton abin da ya faru';

  @override
  String get reportIncidentCategoryHeading => 'Me ya faru?';

  @override
  String get reportIncidentDescriptionHeading => 'Ƙara mana bayani';

  @override
  String get reportIncidentDescriptionHint =>
      'Bayyana abin da ya faru (cikakken bayani yana taimakawa)';

  @override
  String get reportIncidentAttachPhoto => 'Haɗa hoto';

  @override
  String get reportIncidentSubmit => 'Aika rahoto';

  @override
  String get reportIncidentPickCategory => 'Zaɓi rukuni';

  @override
  String get reportIncidentDescriptionRequired => 'Ƙara taƙaitaccen bayani';

  @override
  String get reportIncidentSubmitted => 'An adana rahoto a wannan wayar';

  @override
  String get incidentCategorySafety => 'Tsaro';

  @override
  String get incidentCategoryFareDispute => 'Saɓani kan kuɗi';

  @override
  String get incidentCategoryVehicleQuality => 'Yanayin mota';

  @override
  String get incidentCategoryDriverBehavior => 'Halin direba';

  @override
  String get incidentCategoryLostItem => 'Abin da ya ɓace';

  @override
  String get incidentCategoryOther => 'Wani';

  @override
  String get shareTripTitle => 'Raba tafiya kai tsaye';

  @override
  String get shareTripCreateLink => 'Ƙirƙiri hanyar haɗi';

  @override
  String get shareTripCopy => 'Kwafi hanyar haɗi';

  @override
  String get shareTripSms => 'SMS';

  @override
  String get shareTripCopied => 'An kwafi hanyar haɗi';

  @override
  String get shareTripExpiryNote =>
      'Hanyoyin haɗi suna ƙarewa idan tafiyarka ta ƙare';

  @override
  String get shareTripActiveHeading => 'Rabawa masu aiki';

  @override
  String get shareTripAnonymousContact => 'Abokin hulɗa da aka raba';

  @override
  String shareTripExpires(String date) {
    return 'Zai ƙare $date';
  }

  @override
  String shareTripSmsBody(String url) {
    return 'Bi tafiyata ta Along: $url';
  }

  @override
  String get accountProfileHeading => 'BAYANAN KAI';

  @override
  String get accountPreferencesHeading => 'ZAƁUƁUKA';

  @override
  String get accountCityLabel => 'Birnin gida';

  @override
  String get accountCityHint =>
      'Taswira da bincike suna amfani da wannan birni idan wuri bai samu ba';

  @override
  String get accountPaymentHeading => 'BIYA';

  @override
  String get accountSafetyHeading => 'TSARO';

  @override
  String get accountWayfindingLabel => 'Yanayin jagora';

  @override
  String get accountSortLabel => 'Tsarin jera tafiya';

  @override
  String get accountWomenOnlyLabel => 'Haɗawa da mata kawai';

  @override
  String get accountWomenOnlyHint => 'Fifita direbobi mata idan akwai';

  @override
  String get accountPaymentCashDefault => 'Tsabar kuɗi';

  @override
  String get accountPaymentCashHint => 'Hanyar biya ta asali don tafiyar Along';

  @override
  String get accountSafetyHowSos => 'Yadda SOS ke aiki';

  @override
  String get accountSafetyHowSosBody =>
      'Riƙe SOS don kiran 112 da raba wurinka da abokan hulɗa';

  @override
  String get accountHelp => 'Taimako';

  @override
  String get accountLegal => 'Doka';

  @override
  String get accountSignOut => 'Fita';

  @override
  String get homePlanYourDay => 'Tsara ranarka';

  @override
  String get dayPlannerTitle => 'Shirin yau';

  @override
  String get dayPlannerEmpty => 'Babu tasha a shirinka tukuna';

  @override
  String get dayPlannerNotBookedHint =>
      'An tsara tashoshi — haɗawa yana farawa idan ka danna Haɗa yanzu. Babu abin da aka keɓe tun da wuri.';

  @override
  String get dayPlannerLoadToggle => 'Kaya yau';

  @override
  String get dayPlannerMatchNow => 'Haɗa yanzu';

  @override
  String get dayPlannerPrepare => 'Shirya';

  @override
  String get dayPlannerAddStop => 'Ƙara tasha';

  @override
  String get dayPlannerStopDone => 'An gama';

  @override
  String dayPlannerStopInProgress(int minutes) {
    return 'Ana ci · ETA $minutes min';
  }

  @override
  String get dayPlannerStopReady => 'A shirye — danna Haɗa yanzu a ƙasa';

  @override
  String get dayPlannerStopPrepareHint => 'Danna Shirya idan ka shirya';

  @override
  String get dayPlannerStopPending => 'Na gaba';

  @override
  String get dayPlannerStopSkipped => 'An tsallake';

  @override
  String get itineraryEntryTitle => 'Tsara ranarka';

  @override
  String get itineraryEntryStructured => 'Tashoshi';

  @override
  String get itineraryEntryNaturalLanguage => 'Bayyana';

  @override
  String get itineraryEntryStopHint => 'Ina za ka?';

  @override
  String get itineraryEntryAddRow => 'Ƙara wata tasha';

  @override
  String get itineraryEntryDescribeDay => 'Bayyana ranarka';

  @override
  String get itineraryEntryNlHint =>
      'misali kai yara makaranta, sai aiki, sai kasuwa';

  @override
  String get itineraryEntryMicTitle => 'Faɗi tashoshinka';

  @override
  String get itineraryEntryMicHint => 'Yi magana ko rubuta tashoshinka…';

  @override
  String get itineraryEntryParse => 'Duba tashoshi';

  @override
  String get itineraryEntryProposalTitle => 'Mun ji';

  @override
  String get itineraryEntryUnresolved => 'Yana buƙatar sunan wuri';

  @override
  String get itineraryEntryLooksRight => 'Ya yi daidai';

  @override
  String get itineraryEntrySavePlan => 'Adana shiri';

  @override
  String get sosQueued =>
      'An adana a wannan wayar. Kira 112 idan ka dawo kan layi.';

  @override
  String get sosLiveLink => 'Kwafi hanyar wuri kai tsaye';

  @override
  String get sosLiveLinkCopied => 'An kwafi hanyar wuri kai tsaye';

  @override
  String get sosContactsHeading => 'Faɗa wa wanda ka amince da shi';

  @override
  String sosContactWhatsapp(String name) {
    return 'WhatsApp $name';
  }

  @override
  String sosContactSms(String name) {
    return 'Tura saƙo ga $name';
  }

  @override
  String get emergencyContactsHeading => 'ABOKAN HULƊA NA GAGGAWA';

  @override
  String get emergencyContactsHint =>
      'Muna sanar da waɗannan mutane idan ka danna SOS. Har zuwa 5. WhatsApp ko saƙo zai buɗe a wayarka.';

  @override
  String get emergencyContactsEmpty => 'Babu abokan hulɗa na gaggawa tukuna';

  @override
  String get emergencyContactName => 'Suna';

  @override
  String get emergencyContactPhone => 'Waya';

  @override
  String get emergencyContactAdd => 'Ƙara abokin hulɗa';

  @override
  String emergencyContactRemove(String name) {
    return 'Cire $name';
  }

  @override
  String get emergencyContactInvalidPhone =>
      'Yi amfani da lamba kamar +2348012345678';

  @override
  String get emergencyContactLimit => 'Za ka iya adana har abokan hulɗa 5';

  @override
  String get emergencyContactSaveFailed =>
      'Ba a iya adana wannan abokin hulɗa ba';

  @override
  String get vehiclesTitle => 'Motoci';

  @override
  String freeSeatCount(int count) {
    return '$count babu kowa';
  }

  @override
  String get seatStale => 'Taswirar kujeru ta wuce minti ɗaya';

  @override
  String get filterRulesHint => 'Nemi dokokin direba';

  @override
  String get seatTaken => 'An ɗauki wannan kujera yanzu';

  @override
  String get acknowledgeToClaim => 'Na yarda';

  @override
  String get noVehicles => 'Babu motar da ta dace da waɗannan dokoki';

  @override
  String get seatFree => 'fanko';

  @override
  String get seatOccupied => 'an zauna';

  @override
  String get seatHeld => 'an riƙe';

  @override
  String get seatBlocked => 'an toshe';

  @override
  String get seatDriver => 'direba';

  @override
  String get seatLuggage => 'kaya';

  @override
  String get voiceBookingHint => 'Faɗe shi, misali Wuse zuwa Berger';

  @override
  String get textMapTitle => 'Motoci kusa';

  @override
  String get textMapEmpty => 'Babu motoci a wannan hanya tukuna';

  @override
  String get plateCheck => 'Na ga wannan lamba';

  @override
  String get plateMatches => 'Lambar ta dace';

  @override
  String get plateScan => 'Duba lamba';

  @override
  String get plateScanHint => 'Sanya lambar mota cikin firam';

  @override
  String get plateScanDenied =>
      'Kyamara a kashe take. Za ka iya tabbatar da lambar mota da kanka.';

  @override
  String get plateScanMismatch =>
      'Wannan lambar ba ta dace da wadda aka yi rajista ba.';

  @override
  String get plateScanReport => 'Kai rahoto';

  @override
  String get plateScanSos => 'SOS';

  @override
  String get plateScanTorch => 'Haske';

  @override
  String get plateScanContinue => 'Ci gaba';

  @override
  String get guardianTitle => 'Mai tsaro';

  @override
  String get guardianEnabled => 'Duba lafiya a wannan tafiya';

  @override
  String get guardianOffRoute => 'Mitoci daga hanya';

  @override
  String get guardianLongStop => 'Mintunan dogon tsayawa';

  @override
  String get guardianCheckIn => 'Mintunan dubawa';

  @override
  String get guardianSafeWord => 'Kalmar tsaro';

  @override
  String get guardianSave => 'Adana';

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
  String get tripMessagesTitle => 'Aika wa direba saƙo';

  @override
  String get tripMessagesClosed => 'An rufe wannan hira.';

  @override
  String get tripMessagesDriver => 'Direba';

  @override
  String get tripMessagesRider => 'Kai';

  @override
  String get tripMessagesHint => 'Bayani game da abin da aka bari';

  @override
  String get tripMessagesSend => 'Aika';

  @override
  String get holdNotOffered => 'Wannan direba bai kunna riƙe kujera ba';

  @override
  String get walkExtension => 'Mintunan da kake buƙata don tafiya';

  @override
  String get stageRadarTitle => 'Allon tasha';

  @override
  String get stageRadarLeaving => 'Na gaba da tashi';

  @override
  String stageRadarSeats(int free, int total) {
    return '$free cikin $total fanko';
  }

  @override
  String get stageRadarEmpty => 'Babu motar da ke lodi a nan tukuna';

  @override
  String get stageRadarVerified => 'An tabbatar';

  @override
  String get stageRadarFavourite => 'Adana direba';

  @override
  String get fareShieldTitle => 'Kuɗi na adalci';

  @override
  String get fareShieldQuiet =>
      'Tafiye-tafiye ba su isa a wannan hanya ba tukuna';

  @override
  String get fareShieldDispute => 'Wannan kuɗi ya yi yawa';

  @override
  String fareShieldAnchored(int seconds) {
    return 'Tayi ɗaya, a buɗe na daƙiƙa $seconds';
  }

  @override
  String get fareHistoryTitle => 'Bisa sa\'a';

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

  @override
  String get walletPassHow => 'Yadda yake aiki';

  @override
  String get walletPassStep1 => 'Zaɓi tsari a sama';

  @override
  String get walletPassStep2 =>
      'Biya sau ɗaya daga kuɗin Along ɗinka. Ba a buƙatar kati';

  @override
  String walletPassStep3(int days) {
    return 'Zai ci gaba da aiki na kwanaki $days daga yau';
  }

  @override
  String get walletPassDetails => 'Bayani';

  @override
  String get walletPassRowRides => 'Hawa';

  @override
  String get walletPassRowValid => 'Yana aiki har';

  @override
  String get walletPassRowPaid => 'An biya da';

  @override
  String get walletPassRowPaidValue => 'Kuɗin Along';

  @override
  String get sosTitle => 'Tsaro';

  @override
  String get sosStatusSending => 'Ana sanar da ƙungiyar tsaro ta Along…';

  @override
  String sosStatusSent(String time) {
    return 'An sanar da ƙungiyar tsaro · $time';
  }

  @override
  String get sosStatusQueued =>
      'Babu sigina · an ajiye, za a tura idan ya dawo';

  @override
  String get sosStatusFailed => 'Ba a tura ba · kira 112 yanzu';

  @override
  String get sosHoldHint => 'Riƙe don kira';

  @override
  String get sosMapLive => 'Kai tsaye';

  @override
  String get sosContactsTitle => 'Lambobi';

  @override
  String get sosNoContacts => 'Babu amintattun lambobi tukuna';

  @override
  String get sosAddContact => 'Ƙara';

  @override
  String get sosShareLive => 'Raba tafiya kai tsaye';

  @override
  String get sosImSafe => 'Ina lafiya';

  @override
  String get sosImSafeTitle => 'Soke faɗakarwar?';

  @override
  String get sosImSafeBody =>
      'Ƙungiyar tsaro za ta daina bin tafiyar nan. Soke kawai idan kana lafiya.';

  @override
  String get sosImSafeConfirm => 'Eh, ina lafiya';

  @override
  String get sosKeepAlert => 'Bar faɗakarwa';

  @override
  String sosReach(String name) {
    return 'Tuntuɓi $name';
  }

  @override
  String get guardianShareSubtitle =>
      'Bari wanda ka amince da shi ya bi tafiyar nan';

  @override
  String guardianShareWatching(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mutane $count na ganin tafiyar nan',
      one: 'Mutum 1 na ganin tafiyar nan',
    );
    return '$_temp0';
  }

  @override
  String get guardianShareWho => 'Wa zai iya bi';

  @override
  String get guardianShareNoContacts =>
      'Ƙara amintaccen lamba don rabawa da taɓawa ɗaya';

  @override
  String get guardianShareAddContact => 'Ƙara lamba';

  @override
  String get guardianSharePlate => 'Raba lambar mota';

  @override
  String get guardianShareLocation => 'Raba wuri kai tsaye';

  @override
  String get guardianShareExpiry => 'Tsaya bayan';

  @override
  String get guardianShare30 => 'Minti 30';

  @override
  String get guardianShare60 => 'Awa 1';

  @override
  String get guardianShareTripEnd => 'Ƙarshen tafiya';

  @override
  String guardianShareCta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Raba da mutane $count',
      one: 'Raba da mutum 1',
      zero: 'Ƙirƙiri hanyar rabawa',
    );
    return '$_temp0';
  }

  @override
  String get guardianShareStop => 'Daina rabawa';

  @override
  String guardianShareUntil(String time) {
    return 'Har zuwa $time';
  }

  @override
  String get guardianShareWhatsapp => 'WhatsApp';

  @override
  String get guardianShareOffline =>
      'Rabawa na buƙatar intanet. SOS na aiki ba tare da intanet ba.';

  @override
  String get guardianShareFailed => 'Ba a iya fara rabawa ba. Sake gwadawa.';

  @override
  String get guardianShareStopped => 'An daina rabawa';

  @override
  String get guardianShareNoTrip => 'Rabawa na farawa idan kana cikin tafiya';

  @override
  String get reportIncidentPhotosHeading => 'Hotuna';

  @override
  String get reportIncidentPhotosNote => 'Har 4 · ƙungiyar tsaro kawai ke gani';

  @override
  String get reportIncidentAddPhoto => 'Ƙara hoto';

  @override
  String get reportIncidentTakePhoto => 'Ɗauki hoto';

  @override
  String get reportIncidentChoosePhoto => 'Zaɓi daga hotuna';

  @override
  String reportIncidentRemovePhoto(int n) {
    return 'Cire hoto $n';
  }

  @override
  String reportIncidentUploading(int done, int total) {
    return 'Ana tura hoto $done cikin $total';
  }

  @override
  String get reportIncidentSent => 'An tura rahoto. Ƙungiyar tsaro za ta biyo.';

  @override
  String get reportIncidentQueued =>
      'Babu sigina. An ajiye rahoto, za a tura idan ya dawo.';

  @override
  String get reportIncidentFailed => 'Ba a iya tura rahoton ba. Sake gwadawa.';

  @override
  String get reportIncidentPhotoError => 'Ba a iya ƙara hoton ba';
}
