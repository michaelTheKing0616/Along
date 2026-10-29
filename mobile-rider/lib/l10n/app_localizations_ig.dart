// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Igbo (`ig`).
class AppLocalizationsIg extends AppLocalizations {
  AppLocalizationsIg([String locale = 'ig']) : super(locale);

  @override
  String get phoneEntryTitle => 'Gagharị. N\'ụzọ gị.';

  @override
  String get phoneEntrySubtitle =>
      'Anyị ga-ezitere nọmba a koodu ka njem ahụ bụrụ nke gị.';

  @override
  String get continueButton => 'Gaa n\'ihu';

  @override
  String get legalPrefix => 'Ọ bụrụ na ị gaa n\'ihu, ị kwenyere na ';

  @override
  String get termsLink => 'Usoro';

  @override
  String get legalMiddle => ' na ';

  @override
  String get privacyLink => 'Iwu Nzuzo';

  @override
  String otpTitle(String phone) {
    return 'Tinye koodu ọnụọgụ 6 e zigara $phone';
  }

  @override
  String get wrongNumber => 'Nọmba ezighi ezi?';

  @override
  String get resendCode => 'Zigharịa koodu';

  @override
  String resendCountdown(int seconds) {
    return 'Zigharịa n\'ime ${seconds}s';
  }

  @override
  String get nameTitle => 'Kedu aha ndị ọkwọ ụgbọ ga-akpọ gị?';

  @override
  String get nameHint => 'Aha gị';

  @override
  String get skip => 'Hapụ';

  @override
  String get errorInvalidPhone => 'Tinye nọmba Naịjirịa ziri ezi';

  @override
  String errorRateLimited(int seconds) {
    return 'Ọ gafere ugboro. Nwaa ọzọ n\'ime ${seconds}s';
  }

  @override
  String get errorWrongOtp => 'Koodu ezighi ezi — nwaa ọzọ';

  @override
  String get errorExpiredOtp => 'Koodu agwụla — rịọ nke ọhụrụ';

  @override
  String get errorGeneric => 'Ihe adịghị mma mere. Biko nwaa ọzọ.';

  @override
  String get errorAuthNotConfigured =>
      'Ewu a ejikọghị na Along. Wughachi staging APK jiri env/staging.json.';

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
  String get homeVehicles => 'Ụgbọala';

  @override
  String get homeRecenter => 'Laghachi n\'etiti';

  @override
  String get guardianIntro => 'Nlele n\'njem a, naanị mgbe ị chọrọ ya.';

  @override
  String get homeLocationDeniedBanner => 'Gbanye ọnọdụ ka ịhụ ụgbọala dị nso';

  @override
  String get homeChooseOnMap => 'Họrọ na maapụ';

  @override
  String get homeNearbyTitle => 'Nso ebe a';

  @override
  String homeNearbyRow(
    String countBucket,
    String mode,
    String heading,
    int minutes,
  ) {
    return '$countBucket $mode nso · na-aga $heading · ~$minutes min';
  }

  @override
  String get modeKeke => 'keke';

  @override
  String get searchTitle => 'Ebee?';

  @override
  String get searchRecentsTitle => 'Nke na-adịbeghị anya';

  @override
  String get searchResultsTitle => 'Nsonaazụ';

  @override
  String get searchOfflineHint => 'Enweghị ịntanetị · na-achọ ebe echekwara';

  @override
  String get cachedOptionsStaleBadge => 'Echekwara · nwere ike ịbụ ochie';

  @override
  String get adjustPickupTitle => 'Gbanwee ebe nbuli';

  @override
  String adjustPickupBoardingAt(String stageName) {
    return 'Ịbanye na: $stageName';
  }

  @override
  String get adjustPickupConfirm => 'Kwado ebe';

  @override
  String get tripOptionsHeading => 'Họrọ ụzọ ị ga-esi gaa';

  @override
  String get tripOptionsDegradedBanner => 'Oge ndụ adịghị';

  @override
  String get tripOptionsSlowerDirectCaption => 'Ọ dị nwayọ karịa ụzọ mgbanwe';

  @override
  String get tripOptionsAgreePrice => 'Kwenye ọnụahịa';

  @override
  String get pricingTitle => 'Ọnụahịa Along';

  @override
  String get pricingLapsed => 'Enweghị nkwekọrịta — nwaa ụgbọala ọzọ';

  @override
  String get pricingOutOfRange => 'Ụgbọala agafeela';

  @override
  String get pricingDeclined => 'A jụrụ onyinye';

  @override
  String pricingDriverOffer(String amount) {
    return 'Ọkwọ ụgbọ nyere $amount';
  }

  @override
  String get hailSearchTitle => 'Ebee ka ị na-aga?';

  @override
  String get requestUndoMessage => 'Na-arịọ…';

  @override
  String get loadFlagTitle => 'Ị na-ebu ibu?';

  @override
  String get loadFlagSizeSmall => 'Obere';

  @override
  String get loadFlagSizeMedium => 'Etiti';

  @override
  String get loadFlagSizeLarge => 'Nnukwu';

  @override
  String get loadFlagNoteHint => 'Ndetu nhọrọ (mkpụrụedemede 140)';

  @override
  String get loadFlagRememberDay => 'Cheta maka taa';

  @override
  String get loadFlagCapacityWarning => 'Ụzọ a nwere ike ọ gaghị ebu ibu gị';

  @override
  String get loadFlagRequestAnyway => 'Rịọ n\'agbanyeghị';

  @override
  String get loadFlagDone => 'Emechaala';

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
  String get coverageGapTitle => 'Enweghị ụzọ e debere ebe a ugbu a';

  @override
  String coverageGapNearestBoarding(String name, String distance) {
    return 'Ebe mbata kacha nso: $name · $distance';
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
  String get coverageGapVehiclesNone => 'Ụgbọala nso: ọ dịghị';

  @override
  String coverageGapVehiclesNearby(int count) {
    return 'Ụgbọala nso: $count';
  }

  @override
  String get coverageGapWalkThere => 'Jee ije ebe ahụ';

  @override
  String get coverageGapTellUs => 'Gwa anyị maka ebe a';

  @override
  String get coverageGapThanks => 'Daalụ — anyị edeela akụkọ gị';

  @override
  String get tripOptionsWhy => 'Gịnị kpatara?';

  @override
  String get tripOptionsWhyTitle => 'Ihe mere a tụrụ aro ya';

  @override
  String get tripOptionsWhyFare => 'Ego ụgbọ';

  @override
  String get tripOptionsWhyTime => 'Oge';

  @override
  String get tripOptionsWhyEffort => 'Mgbalị';

  @override
  String get tripOptionsShowLegs => 'Gosi akụkụ';

  @override
  String get tripOptionsHideLegs => 'Zoo akụkụ';

  @override
  String tripOptionsRequestLeg(int leg, String fare) {
    return 'Rịọ akụkụ $leg · $fare';
  }

  @override
  String get transferTitle => 'Akụkụ ọzọ';

  @override
  String get transferNextLegTitle => 'Akụkụ ọzọ';

  @override
  String transferSupply(String bucket) {
    return '$bucket na-ebu';
  }

  @override
  String get transferRequestNextLeg => 'Rịọ akụkụ ọzọ';

  @override
  String get transferChangePlan => 'Gbanwee atụmatụ';

  @override
  String get transferWalkLoading => 'Na-ebuli ntụziaka ije…';

  @override
  String get wayfindingTitle => 'Ntụziaka ije ụkwụ';

  @override
  String get wayfindingModeText => 'Ederede';

  @override
  String get wayfindingModeMap => 'Maapụ';

  @override
  String get wayfindingModeAudio => 'Olu';

  @override
  String get wayfindingPlay => 'Kpọọ';

  @override
  String get wayfindingPause => 'Kwụsịtụ';

  @override
  String get wayfindingArrived => 'Erutela';

  @override
  String get wayfindingDegraded => 'Ntụziaka nwere ike ọ gaghị ezu oke';

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
  String get extendTripTitle => 'Gbatịa njem';

  @override
  String get extendTripSearchHint => 'Ebee ugbu a?';

  @override
  String extendTripDestination(String destination) {
    return 'Na-aga n\'ihu ruo $destination';
  }

  @override
  String get extendTripSend => 'Ziga ọkwọ ụgbọ';

  @override
  String get incomingExtensionTitle => 'Arịrịọ mgbatị';

  @override
  String incomingExtensionBody(String destination, String delta) {
    return 'Ọkwọ ụgbọ chọrọ ịga n\'ihu ruo $destination maka +$delta';
  }

  @override
  String get incomingExtensionAccept => 'Nabata';

  @override
  String get incomingExtensionDecline => 'Jụ';

  @override
  String get payDriverTitle => 'Kwụọ ọkwọ ụgbọ';

  @override
  String payDriverCta(String amount) {
    return 'Kwụọ $amount';
  }

  @override
  String get payDriverAmountLocked => 'Ego a kpọchiri maka njem a';

  @override
  String get payDriverMethodSaved => 'Visa ···4242';

  @override
  String payDriverPending(String amount) {
    return 'Zipu $amount n\'ime ngwa ụlọakụ gị';
  }

  @override
  String get payDriverCopyAccount => 'Detuo nọmba';

  @override
  String get payDriverAccountCopied => 'E detuola nọmba akaụnt';

  @override
  String get payDriverWaitingTransfer => 'Na-eche ego ị ga-ezipu';

  @override
  String get payDriverOtherAmount => 'Ọzọ';

  @override
  String get payDriverOtherHint => 'Tinye ego';

  @override
  String payDriverExpires(int seconds) {
    return 'Ọ ga-agwụ n\'ime ${seconds}s';
  }

  @override
  String get payDriverOpenCheckout => 'Mepee ibe ụlọakụ';

  @override
  String get payDriverMethodTransfer => 'Nzipu ụlọakụ';

  @override
  String get payDriverMethodUssd => 'USSD';

  @override
  String get payDriverChangeMethod => 'Gbanwee';

  @override
  String payDriverCashOnly(String name) {
    return '$name na-anabata naanị ego aka';
  }

  @override
  String get payDriverInactive => 'Koodu a anaghị arụ ọrụ ọzọ';

  @override
  String get payDriverDifferentDriver => 'Njem gị ugbu a so ọkwọ ụgbọ ọzọ';

  @override
  String get payDriverConfirmOther =>
      'Ọ bụghị ọkwọ ụgbọ njem m — kwụọ n\'agbanyeghị';

  @override
  String get payDriverFailed => 'Ịkwụ ụgwọ adaala';

  @override
  String get payDriverRetry => 'Nwaa ọzọ';

  @override
  String get payDriverSuccessTitle => 'Akwụọla';

  @override
  String payDriverSuccessItemised(
    String driverAmount,
    String name,
    String feeAmount,
  ) {
    return '$driverAmount nye $name · $feeAmount ego Along';
  }

  @override
  String get payDriverHistoryOptIn => 'Tinye njem a n\'akụkọ gị?';

  @override
  String get scanToPayTitle => 'Nyochaa ka ịkwụ ụgwọ';

  @override
  String get scanEnterCode => 'Tinye koodu kama';

  @override
  String get scanEnterCodePrompt => 'Tinye koodu ọkwọ ụgbọ';

  @override
  String get scanCodeHint => 'Koodu mkpụrụ 8';

  @override
  String get scanCodeSubmit => 'Gaa n\'ihu';

  @override
  String get scanBackToCamera => 'Laghachi na kamera';

  @override
  String get scanNotAlong => 'Ọ bụghị koodu Along';

  @override
  String get payMethodsTitle => 'Ụzọ ịkwụ ụgwọ';

  @override
  String get payMethodsDefault => 'Ndabere';

  @override
  String get payMethodsSetDefault => 'Mee ka ọ bụrụ ndabere';

  @override
  String get payMethodsRemove => 'Wepụ';

  @override
  String get payMethodsAdd => 'Tinye kaadị';

  @override
  String get payMethodsTransferDefault => 'Jiri nzipu kwụọ dịka ndabere';

  @override
  String get activeTripScan => 'Nyochaa';

  @override
  String get tripsEmpty => 'Enweghị njem emechara ugbu a.';

  @override
  String get tripDetailTitle => 'Nkọwa njem';

  @override
  String get tripDetailMissing => 'Ahụghị njem ahụ';

  @override
  String get tripDetailShareReceipt => 'Kesaa nnata';

  @override
  String get tripDetailReceiptCopied => 'E detuola nnata';

  @override
  String get sosTeamAlerted => 'Njikere ịkpọ 112';

  @override
  String get sosSharingDetails => 'Kesaa ọnọdụ gị ugbu a na ndị kọntaktị gị';

  @override
  String sosCallEmergency(String number) {
    return 'Kpọọ $number';
  }

  @override
  String get sosShareWithContact => 'Kesaa na onye kọntaktị';

  @override
  String get sosHoldToCancel => 'Jide ka ịkagbu';

  @override
  String get sosRaising => 'Na-emepe oku 112…';

  @override
  String get sosRaiseFailed => 'Enweghị ike imepe oku 112';

  @override
  String get sosRetry => 'Nwaa ọzọ';

  @override
  String get reportIncidentTitle => 'Kọọ ihe mere';

  @override
  String get reportIncidentCategoryHeading => 'Gịnị mere?';

  @override
  String get reportIncidentDescriptionHeading => 'Gwakwuo anyị';

  @override
  String get reportIncidentDescriptionHint =>
      'Kọwaa ihe mere (nkọwa na-enyere aka)';

  @override
  String get reportIncidentAttachPhoto => 'Tinye foto';

  @override
  String get reportIncidentSubmit => 'Ziga akụkọ';

  @override
  String get reportIncidentPickCategory => 'Họrọ otu';

  @override
  String get reportIncidentDescriptionRequired => 'Tinye nkọwa dị mkpirikpi';

  @override
  String get reportIncidentSubmitted => 'Echekwara akụkọ na ekwentị a';

  @override
  String get incidentCategorySafety => 'Nchekwa';

  @override
  String get incidentCategoryFareDispute => 'Esemokwu ego ụgbọ';

  @override
  String get incidentCategoryVehicleQuality => 'Ọnọdụ ụgbọala';

  @override
  String get incidentCategoryDriverBehavior => 'Omume ọkwọ ụgbọ';

  @override
  String get incidentCategoryLostItem => 'Ihe furu efu';

  @override
  String get incidentCategoryOther => 'Ọzọ';

  @override
  String get shareTripTitle => 'Kesaa njem ugbu a';

  @override
  String get shareTripCreateLink => 'Mepụta njikọ';

  @override
  String get shareTripCopy => 'Detuo njikọ';

  @override
  String get shareTripSms => 'SMS';

  @override
  String get shareTripCopied => 'E detuola njikọ';

  @override
  String get shareTripExpiryNote => 'Njikọ na-agwụ mgbe njem gị kwụsịrị';

  @override
  String get shareTripActiveHeading => 'Nkesa na-arụ ọrụ';

  @override
  String get shareTripAnonymousContact => 'Onye kọntaktị e kesara';

  @override
  String shareTripExpires(String date) {
    return 'Ọ ga-agwụ $date';
  }

  @override
  String shareTripSmsBody(String url) {
    return 'Soro njem Along m: $url';
  }

  @override
  String get accountProfileHeading => 'PROFAỊLỤ';

  @override
  String get accountPreferencesHeading => 'NHỌRỌ';

  @override
  String get accountCityLabel => 'Obodo ụlọ';

  @override
  String get accountCityHint =>
      'Maapụ na ọchụchọ na-eji obodo a mgbe enweghị ebe';

  @override
  String get accountPaymentHeading => 'ỊKWỤ ỤGWỌ';

  @override
  String get accountSafetyHeading => 'NCHEKWA';

  @override
  String get accountWayfindingLabel => 'Ụdị ntụziaka';

  @override
  String get accountSortLabel => 'Usoro nhazi njem';

  @override
  String get accountWomenOnlyLabel => 'Njikọ ụmụnwaanyị naanị';

  @override
  String get accountWomenOnlyHint => 'Họrọ ndị ọkwọ ụgbọ nwaanyị mgbe ha dị';

  @override
  String get accountPaymentCashDefault => 'Ego aka';

  @override
  String get accountPaymentCashHint => 'Ụzọ ịkwụ ụgwọ ndabere maka njem Along';

  @override
  String get accountSafetyHowSos => 'Otu SOS si arụ ọrụ';

  @override
  String get accountSafetyHowSosBody =>
      'Jide SOS ka ịkpọ 112 ma kesaa ọnọdụ gị';

  @override
  String get accountHelp => 'Enyemaka';

  @override
  String get accountLegal => 'Iwu';

  @override
  String get accountSignOut => 'Pụọ';

  @override
  String get homePlanYourDay => 'Hazie ụbọchị gị';

  @override
  String get dayPlannerTitle => 'Atụmatụ taa';

  @override
  String get dayPlannerEmpty => 'Enweghị ebe nkwụsị n\'atụmatụ gị';

  @override
  String get dayPlannerNotBookedHint =>
      'E hazierela ebe nkwụsị — njikọ na-amalite mgbe ị pịa Jikọọ ugbu a. Ọ dịghị ihe e debere tupu oge.';

  @override
  String get dayPlannerLoadToggle => 'Ibu taa';

  @override
  String get dayPlannerMatchNow => 'Jikọọ ugbu a';

  @override
  String get dayPlannerPrepare => 'Kwadebe';

  @override
  String get dayPlannerAddStop => 'Tinye ebe nkwụsị';

  @override
  String get dayPlannerStopDone => 'Emechaala';

  @override
  String dayPlannerStopInProgress(int minutes) {
    return 'Na-aga · ETA $minutes min';
  }

  @override
  String get dayPlannerStopReady => 'Njikere — pịa Jikọọ ugbu a n\'okpuru';

  @override
  String get dayPlannerStopPrepareHint => 'Pịa Kwadebe mgbe ị dị njikere';

  @override
  String get dayPlannerStopPending => 'Nke na-esote';

  @override
  String get dayPlannerStopSkipped => 'Ahapụrụ';

  @override
  String get itineraryEntryTitle => 'Hazie ụbọchị gị';

  @override
  String get itineraryEntryStructured => 'Ebe nkwụsị';

  @override
  String get itineraryEntryNaturalLanguage => 'Kọwaa';

  @override
  String get itineraryEntryStopHint => 'Ebee?';

  @override
  String get itineraryEntryAddRow => 'Tinye ebe nkwụsị ọzọ';

  @override
  String get itineraryEntryDescribeDay => 'Kọwaa ụbọchị gị';

  @override
  String get itineraryEntryNlHint =>
      'dịka bunye ụmụaka n\'ụlọakwụkwọ, wee rụọ ọrụ, wee gaa ahịa';

  @override
  String get itineraryEntryMicTitle => 'Kwuo ebe nkwụsị gị';

  @override
  String get itineraryEntryMicHint => 'Kwuo ma ọ bụ dee ebe nkwụsị gị…';

  @override
  String get itineraryEntryParse => 'Lelee ebe nkwụsị';

  @override
  String get itineraryEntryProposalTitle => 'Anyị nụrụ';

  @override
  String get itineraryEntryUnresolved => 'Ọ chọrọ aha ebe';

  @override
  String get itineraryEntryLooksRight => 'Ọ dị mma';

  @override
  String get itineraryEntrySavePlan => 'Chekwaa atụmatụ';

  @override
  String get sosQueued =>
      'Echekwara na ekwentị a. Kpọọ 112 mgbe ị laghachiri n\'ịntanetị.';

  @override
  String get sosLiveLink => 'Detuo njikọ ọnọdụ ugbu a';

  @override
  String get sosLiveLinkCopied => 'E detuola njikọ ọnọdụ';

  @override
  String get sosContactsHeading => 'Gwa onye ị tụkwasịrị obi';

  @override
  String sosContactWhatsapp(String name) {
    return 'WhatsApp $name';
  }

  @override
  String sosContactSms(String name) {
    return 'Ziga ozi nye $name';
  }

  @override
  String get emergencyContactsHeading => 'NDỊ KỌNTAKTỊ MBEREDE';

  @override
  String get emergencyContactsHint =>
      'Anyị na-agwa ndị a ma ị pịa SOS. Ruo 5. WhatsApp ma ọ bụ ozi ga-emepe na ekwentị gị.';

  @override
  String get emergencyContactsEmpty => 'Enweghị onye kọntaktị mberede';

  @override
  String get emergencyContactName => 'Aha';

  @override
  String get emergencyContactPhone => 'Ekwentị';

  @override
  String get emergencyContactAdd => 'Tinye onye kọntaktị';

  @override
  String emergencyContactRemove(String name) {
    return 'Wepụ $name';
  }

  @override
  String get emergencyContactInvalidPhone => 'Jiri nọmba dịka +2348012345678';

  @override
  String get emergencyContactLimit => 'Ị nwere ike ichekwa ruo mmadụ 5';

  @override
  String get emergencyContactSaveFailed => 'Enweghị ike ichekwa onye ahụ';

  @override
  String get vehiclesTitle => 'Ụgbọala';

  @override
  String freeSeatCount(int count) {
    return '$count tọgbọrọ chakoo';
  }

  @override
  String get seatStale => 'Maapụ oche karịrị otu nkeji';

  @override
  String get filterRulesHint => 'Chọọ iwu ọkwọ ụgbọ';

  @override
  String get seatTaken => 'E werela oche ahụ ugbu a';

  @override
  String get acknowledgeToClaim => 'Ekwenyere m';

  @override
  String get noVehicles => 'Enweghị ụgbọala dabara iwu ndị a';

  @override
  String get seatFree => 'tọgbọrọ';

  @override
  String get seatOccupied => 'e nwere onye';

  @override
  String get seatHeld => 'ejidere';

  @override
  String get seatBlocked => 'egbochiri';

  @override
  String get seatDriver => 'onye ọkwọ';

  @override
  String get seatLuggage => 'ibu';

  @override
  String get voiceBookingHint => 'Kwuo ya, dịka Wuse ruo Berger';

  @override
  String get textMapTitle => 'Ụgbọala nso';

  @override
  String get textMapEmpty => 'Enweghị ụgbọala n\'ụzọ a';

  @override
  String get plateCheck => 'Ahụrụ m nọmba a';

  @override
  String get plateMatches => 'Nọmba dabara';

  @override
  String get plateScan => 'Nyochaa nọmba';

  @override
  String get plateScanHint => 'Tinye nọmba ụgbọ n\'ime okpokolo';

  @override
  String get plateScanDenied =>
      'Kamera gbanyụrụ. Ị ka nwere ike ịkwado nọmba ahụ n\'onwe gị.';

  @override
  String get plateScanMismatch => 'Nọmba a adabaghị nke edebanyere aha.';

  @override
  String get plateScanReport => 'Kọọ';

  @override
  String get plateScanSos => 'SOS';

  @override
  String get plateScanTorch => 'Ọkụ';

  @override
  String get plateScanContinue => 'Gaa n\'ihu';

  @override
  String get guardianTitle => 'Onye nche';

  @override
  String get guardianEnabled => 'Lelee njem a';

  @override
  String get guardianOffRoute => 'Mita n\'ụzọ';

  @override
  String get guardianLongStop => 'Nkeji nkwụsị ogologo';

  @override
  String get guardianCheckIn => 'Nkeji nlele';

  @override
  String get guardianSafeWord => 'Okwu nchekwa';

  @override
  String get guardianSave => 'Chekwaa';

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
  String get tripMessagesTitle => 'Ziga ọkwọ ụgbọ ozi';

  @override
  String get tripMessagesClosed => 'Emechiela mkparịta ụka a.';

  @override
  String get tripMessagesDriver => 'Ọkwọ ụgbọ';

  @override
  String get tripMessagesRider => 'Gị';

  @override
  String get tripMessagesHint => 'Ndetu maka ihe ahapụrụ';

  @override
  String get tripMessagesSend => 'Ziga';

  @override
  String get holdNotOffered => 'Ọkwọ ụgbọ a agbanyeghị njide oche';

  @override
  String get walkExtension => 'Nkeji ị chọrọ ije';

  @override
  String get stageRadarTitle => 'Bọọdụ ogige';

  @override
  String get stageRadarLeaving => 'Ọ na-apụ ọzọ';

  @override
  String stageRadarSeats(int free, int total) {
    return '$free n\'ime $total tọgbọrọ';
  }

  @override
  String get stageRadarEmpty => 'Enweghị ụgbọala na-ebu ebe a';

  @override
  String get stageRadarVerified => 'Enyochaala';

  @override
  String get stageRadarFavourite => 'Chekwaa ọkwọ ụgbọ';

  @override
  String get fareShieldTitle => 'Ego ụgbọ ziri ezi';

  @override
  String get fareShieldQuiet => 'Njem ezughị n\'ụzọ a ugbu a';

  @override
  String get fareShieldDispute => 'Ego a dị oke ọnụ';

  @override
  String fareShieldAnchored(int seconds) {
    return 'Otu onyinye, mepere maka sekọnd $seconds';
  }

  @override
  String get fareHistoryTitle => 'Site n\'awa';

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

  @override
  String get wayfindingYouAreHere => 'Ị nọ ebe a';

  @override
  String wayfindingStepOf(int step, int total) {
    return 'Nzọụkwụ $step n\'ime $total';
  }

  @override
  String get wayfindingIveArrived => 'Abịarutela m';

  @override
  String get scanFitHint => 'Tinye koodu n\'ime akụkụ ndị a';

  @override
  String get scanFound => 'Achọtala koodu';

  @override
  String get requestingNextTitle => 'Ihe ga-eme ọzọ';

  @override
  String get requestingStepSent => 'Ezigara ndị ọkwọ ụgbọ nọ nso arịrịọ';

  @override
  String get requestingStepAccept =>
      'Onye ọkwọ ụgbọ nabata, ị ga-ahụ nọmba ụgbọ ya';

  @override
  String requestingStepMeet(String place) {
    return 'Zute ha na $place';
  }

  @override
  String get tripGlanceTitle => 'Njem gị';

  @override
  String tripGlanceWalk(String place) {
    return 'Jee ije gaa $place';
  }

  @override
  String get tripGlanceWait => 'Chere ụgbọ gị';

  @override
  String tripGlanceRide(String place) {
    return 'Nọdụ ụgbọ gaa $place';
  }

  @override
  String tripGlanceMinutes(int minutes) {
    return 'nkeji $minutes';
  }

  @override
  String get tripsSummaryTitle => 'Njem ndị na-adịbeghị anya';

  @override
  String tripsSummaryCount(int count) {
    return 'Njem $count';
  }

  @override
  String tripsSummarySpent(String amount) {
    return 'Akwụọla $amount';
  }

  @override
  String get tripsEmptyHint =>
      'Njem ị ji Along mee ga-apụta ebe a, ya na nnata.';

  @override
  String get tripsEmptyCta => 'Hazie njem';

  @override
  String get scanCodeWhereTitle => 'Ebe ị ga-ahụ ya';

  @override
  String get scanCodeWhereBody =>
      'E biri koodu mkpụrụedemede 8 n\'okpuru QR na stịka onye ọkwọ ụgbọ, ma ọ bụ gwa ya mepee My QR.';

  @override
  String get connOffline => 'Enweghị ịntanetị · ị nwere ike ịga n\'ihu';

  @override
  String connOfflineQueued(int count) {
    return 'Enweghị ịntanetị · $count echekwara iziga';
  }

  @override
  String get connReconnecting => 'Na-ejikọ ọzọ';

  @override
  String connSending(int count) {
    return 'Na-ejikọ ọzọ · na-eziga $count';
  }

  @override
  String get connRestored => 'Ịlaghachila n\'ịntanetị';

  @override
  String connRestoredSent(int count) {
    return 'Ịlaghachila · ezigala $count';
  }

  @override
  String get connRetry => 'Nwaa ọzọ';

  @override
  String get searchPausedTitle => 'Akwụsịla ọchịchọ';

  @override
  String get searchPausedBody =>
      'Ịntanetị kwụsịrị. Ebe echekwara na map ka na-arụ ọrụ.';

  @override
  String get searchEmptyTitle => 'Ahụghị ebe ọ bụla';

  @override
  String get searchEmptyBody =>
      'Nwaa ebe a ma ama, ahịa ma ọ bụ ebe nkwụsị ụgbọ dị nso.';

  @override
  String get searchEmptyOfflineBody =>
      'Ị nọghị n\'ịntanetị, ya mere naanị ebe echekwara na-egosi. Tinye pin kama.';

  @override
  String connNeedsConnection(int count) {
    return 'Enweghị ịntanetị · $count ka emeghachi n\'ịntanetị';
  }

  @override
  String connOfflineMixed(int queued, int needs) {
    return 'Enweghị ịntanetị · $queued iziga · $needs imeghachi';
  }

  @override
  String get walletTitle => 'Obere akpa';

  @override
  String get walletSubtitle => 'Ego Along';

  @override
  String get walletBalance => 'Ego fọdụrụ';

  @override
  String get walletBalanceNote => 'Ọ na-anọ na Along';

  @override
  String get walletAddCredit => 'Tinye ego';

  @override
  String get walletCustom => 'Nke gị';

  @override
  String get walletHistory => 'Akụkọ';

  @override
  String get walletHistoryEmpty =>
      'Enweghị ego ugbu a. Itinye ego, ụgwọ njem na nkwụghachi ga-egosi ebe a.';

  @override
  String get walletAddCustom => 'Tinye ego ịchọrọ';

  @override
  String walletAdd(String amount) {
    return 'Tinye $amount';
  }

  @override
  String get walletTopUp => 'Itinye ego';

  @override
  String get walletFare => 'Ụgwọ njem';

  @override
  String get walletRefund => 'Nkwụghachi';

  @override
  String get walletToday => 'Taa';

  @override
  String get walletYesterday => 'Ụnyaahụ';

  @override
  String get walletUnavailable => 'Obere akpa emepeghị';

  @override
  String get walletUnavailableBody =>
      'Ego gị dị mma. Lelee ịntanetị gị ma nwaa ọzọ.';

  @override
  String get walletRetry => 'Nwaa ọzọ';

  @override
  String get walletCustomTitle => 'Ego ole?';

  @override
  String get walletCustomHint => '₦100 ruo ₦50,000';

  @override
  String get walletCustomTooSmall => 'Opekata mpe ₦100';

  @override
  String get walletCustomTooLarge => 'Kachasị ₦50,000';

  @override
  String get walletCancel => 'Kagbuo';

  @override
  String walletAdded(String amount) {
    return 'Etinyere $amount';
  }

  @override
  String get walletTopUpFailed => 'Ọ dịghị ihe etinyere. Nwaa ọzọ.';

  @override
  String get walletActionTopUp => 'Tinye ego';

  @override
  String get walletActionSend => 'Zipu';

  @override
  String get walletActionPass => 'Pass';

  @override
  String get walletActionSplit => 'Kee';

  @override
  String get walletActivity => 'Ihe omume';

  @override
  String get walletEarlier => 'Na mbụ';

  @override
  String get walletActivityEmpty =>
      'Enweghị ihe omume. Tinye ego ka ị gaa n\'ụzọ na-enweghị ego aka.';

  @override
  String walletBalanceSemantics(String amount) {
    return 'Ego fọdụrụ $amount';
  }

  @override
  String walletSentTo(String name) {
    return 'Nye $name';
  }

  @override
  String walletReceivedFrom(String name) {
    return 'Site n\'aka $name';
  }

  @override
  String get walletSent => 'Ezigara';

  @override
  String get walletReceived => 'Natara';

  @override
  String get walletPassEntry => 'Along Pass';

  @override
  String get walletSplitPaid => 'Akwụọla òkè';

  @override
  String get walletSplitReceived => 'Natara òkè';

  @override
  String walletOwedTitle(String name, String amount) {
    return '$name rịọrọ $amount';
  }

  @override
  String get walletOwedBody => 'Òkè gị n\'njem e kekọrịtara';

  @override
  String get walletOwedPay => 'Kwụọ';

  @override
  String get walletOwedDecline => 'Jụ';

  @override
  String walletOwedPaidSnack(String amount) {
    return 'Akwụọla $amount';
  }

  @override
  String get walletOwedDeclinedSnack => 'Ajụrụ arịrịọ';

  @override
  String get walletInsufficient => 'Ego ezughị. Buru ụzọ tinye ego.';

  @override
  String get walletActionFailed =>
      'Ọ gwụchaghị. Nwaa ọzọ — a gaghị ana gị ugboro abụọ.';

  @override
  String get walletSendTitle => 'Zipu ego';

  @override
  String get walletSendSubtitle => 'Nye onye ọzọ na-eji Along';

  @override
  String get walletSendPhone => 'Nọmba ekwentị';

  @override
  String get walletSendPhoneHint => '0803 123 4567';

  @override
  String get walletSendPhoneInvalid => 'Tinye nọmba ekwentị Naịjirịa';

  @override
  String get walletSendAmount => 'Ego ole';

  @override
  String get walletSendTooSmall => 'Zipu opekata mpe ₦50';

  @override
  String get walletSendTooLarge => 'Zipu ọ karịghị ₦50,000';

  @override
  String get walletSendOverBalance => 'Ọ karịrị ego gị';

  @override
  String walletSendCta(String amount) {
    return 'Zipu $amount';
  }

  @override
  String get walletSendCtaEmpty => 'Zipu';

  @override
  String get walletSendNotFound => 'Ọ dịghị onye Along nwere nọmba ahụ';

  @override
  String walletSentSnack(String amount) {
    return 'Ezigara $amount';
  }

  @override
  String walletAvailable(String amount) {
    return 'Dị $amount';
  }

  @override
  String get walletPassTitle => 'Along Pass';

  @override
  String get walletPassSubtitle => 'Njem akwụọla ugwo site n\'ego gị';

  @override
  String walletPassPrice(String amount) {
    return '$amount kwa ọnwa';
  }

  @override
  String get walletPassBody =>
      'Otu ịkwụ ụgwọ site na wallet gị. Enweghị kaadị, enweghị ego aka n\'ọnụ ụzọ.';

  @override
  String walletPassCta(String amount) {
    return 'Zụta pass · $amount';
  }

  @override
  String get walletPassBought => 'Pass na-arụ ọrụ · Emechala';

  @override
  String walletPassShort(String amount) {
    return 'Tinye $amount ọzọ ka ị zụta';
  }

  @override
  String get walletSplitTitle => 'Kee ụgwọ njem';

  @override
  String get walletSplitSubtitle => 'Rịọ ndị ibe gị òkè ha';

  @override
  String get walletSplitFare => 'Ụgwọ njem';

  @override
  String get walletSplitYou => 'Gị';

  @override
  String walletSplitCoRider(int n) {
    return 'Onye ibe $n';
  }

  @override
  String get walletSplitAdd => 'Tinye onye ibe';

  @override
  String get walletSplitRemove => 'Wepụ';

  @override
  String walletSplitEach(String amount) {
    return '$amount onye ọ bụla';
  }

  @override
  String walletSplitCta(String amount) {
    return 'Rịọ $amount onye ọ bụla';
  }

  @override
  String get walletSplitCtaEmpty => 'Rịọ òkè';

  @override
  String get walletSplitFareInvalid => 'Tinye ụgwọ njem, opekata mpe ₦100';

  @override
  String walletSplitSentSnack(int count) {
    return 'Arịọrọ ndị ibe $count';
  }

  @override
  String get walletSplitNotFound => 'Otu n\'ime nọmba ndị ahụ anọghị na Along';

  @override
  String get walletSplitNote =>
      'Ha ga-akwụ site na wallet ha. Ị ga-akwụ onye ọkwọ ụgbọ dịka ọ dị na mbụ.';

  @override
  String get accountWallet => 'Wallet';

  @override
  String get accountWalletHint => 'Tinye ego, zipu, pass, kee ụgwọ njem';

  @override
  String get walletPassPlanWeek => 'Izu';

  @override
  String get walletPassPlanPack => 'Njem 5';

  @override
  String get walletPassPlanMonth => 'Ọnwa';

  @override
  String walletPassRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Njem $count',
      one: 'Njem 1',
    );
    return '$_temp0';
  }

  @override
  String walletPassValidity(int days) {
    return 'Ọ dị mma maka ụbọchị $days';
  }

  @override
  String walletPassPerRide(String amount) {
    return '$amount otu njem';
  }

  @override
  String get walletPassVersus => 'Ma e jiri ya tụnyere ụgwọ otu otu';

  @override
  String walletPassSingleRow(int count, String fare) {
    return '$count × $fare otu';
  }

  @override
  String get walletPassPassRow => 'Pass';

  @override
  String walletPassSave(String amount) {
    return 'Ị chekwara $amount';
  }

  @override
  String get walletPassNoSave => 'Enweghị nchekwa n\'ụgwọ ị na-akwụ mgbe niile';

  @override
  String get walletPassNoHistory =>
      'Nchekwa ga-egosi mgbe ị kwụchara ụgwọ mbụ site na wallet';

  @override
  String walletPassUsualFare(String amount) {
    return 'Ụgwọ ị na-akwụ mgbe niile bụ $amount';
  }

  @override
  String walletPassActive(String date) {
    return 'Na-arụ ọrụ ruo $date';
  }

  @override
  String walletSplitNotFoundNumber(String phone) {
    return '$phone anọghị na Along';
  }

  @override
  String get walletSplitNotOnAlong => 'Anọghị na Along';

  @override
  String get walletSplitRequests => 'Arịrịọ gị';

  @override
  String get walletSplitPending => 'Na-eche';

  @override
  String get walletSplitPaidStatus => 'Akwụọla';

  @override
  String get walletSplitDeclined => 'Ajụrụ';

  @override
  String get walletPassSaveLabel => 'Ihe ị chekwara';

  @override
  String get walletPassHow => 'Otu o si arụ ọrụ';

  @override
  String get walletPassStep1 => 'Họrọ atụmatụ n\'elu';

  @override
  String get walletPassStep2 =>
      'Kwụọ otu ugboro site n\'ego Along gị. Ọ dịghị mkpa kaadị';

  @override
  String walletPassStep3(int days) {
    return 'Ọ ga-arụ ọrụ ụbọchị $days site taa';
  }

  @override
  String get walletPassDetails => 'Nkọwa';

  @override
  String get walletPassRowRides => 'Njem';

  @override
  String get walletPassRowValid => 'Dị irè ruo';

  @override
  String get walletPassRowPaid => 'Ejiri kwụọ';

  @override
  String get walletPassRowPaidValue => 'Ego Along';

  @override
  String get sosTitle => 'Nchekwa';

  @override
  String get sosStatusSending => 'Anyị na-agwa ndị nchekwa Along…';

  @override
  String sosStatusSent(String time) {
    return 'Agwala ndị nchekwa · $time';
  }

  @override
  String get sosStatusQueued =>
      'Enweghị signal · echekwara ya, ọ ga-eziga mgbe ọ lọghachiri';

  @override
  String get sosStatusFailed => 'Eziteghị ya · kpọọ 112 ugbu a';

  @override
  String get sosHoldHint => 'Jide ka ị kpọọ';

  @override
  String get sosMapLive => 'Ndụ';

  @override
  String get sosContactsTitle => 'Ndị kọntaktị';

  @override
  String get sosNoContacts => 'Enweghị onye ntụkwasị obi ka';

  @override
  String get sosAddContact => 'Tinye';

  @override
  String get sosShareLive => 'Kesaa njem ndụ';

  @override
  String get sosImSafe => 'Adị m mma';

  @override
  String get sosImSafeTitle => 'Kagbuo mkpu a?';

  @override
  String get sosImSafeBody =>
      'Ndị nchekwa ga-akwụsị ịgbaso njem a. Kagbuo naanị ma ọ bụrụ na ị dị mma.';

  @override
  String get sosImSafeConfirm => 'Ee, adị m mma';

  @override
  String get sosKeepAlert => 'Hapụ mkpu ahụ';

  @override
  String sosReach(String name) {
    return 'Kpọtụrụ $name';
  }

  @override
  String get guardianShareSubtitle => 'Ka onye ị tụkwasịrị obi soro njem a';

  @override
  String guardianShareWatching(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mmadụ $count na-ahụ njem a',
      one: 'Mmadụ 1 na-ahụ njem a',
    );
    return '$_temp0';
  }

  @override
  String get guardianShareWho => 'Onye nwere ike iso';

  @override
  String get guardianShareNoContacts =>
      'Tinye onye ntụkwasị obi ka ị kesaa n\'otu mmetụ';

  @override
  String get guardianShareAddContact => 'Tinye kọntaktị';

  @override
  String get guardianSharePlate => 'Kesaa nọmba ụgbọ';

  @override
  String get guardianShareLocation => 'Kesaa ebe ị nọ ugbu a';

  @override
  String get guardianShareExpiry => 'Kwụsị mgbe';

  @override
  String get guardianShare30 => 'Nkeji 30';

  @override
  String get guardianShare60 => 'Awa 1';

  @override
  String get guardianShareTripEnd => 'Njem kwụsịrị';

  @override
  String guardianShareCta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kesaa mmadụ $count',
      one: 'Kesaa mmadụ 1',
      zero: 'Mepụta njikọ nkesa',
    );
    return '$_temp0';
  }

  @override
  String get guardianShareStop => 'Kwụsị ịkesa';

  @override
  String guardianShareUntil(String time) {
    return 'Ruo $time';
  }

  @override
  String get guardianShareWhatsapp => 'WhatsApp';

  @override
  String get guardianShareOffline =>
      'Ịkesa chọrọ ịntanetị. SOS ka na-arụ ọrụ na-enweghị ya.';

  @override
  String get guardianShareFailed => 'Enweghị ike ịmalite ịkesa. Nwaa ọzọ.';

  @override
  String get guardianShareStopped => 'Akwụsịla ịkesa';

  @override
  String get guardianShareNoTrip => 'Ịkesa na-amalite mgbe ị nọ na njem';

  @override
  String get reportIncidentPhotosHeading => 'Foto';

  @override
  String get reportIncidentPhotosNote =>
      'Ruo 4 · naanị ndị nchekwa anyị na-ahụ ha';

  @override
  String get reportIncidentAddPhoto => 'Tinye foto';

  @override
  String get reportIncidentTakePhoto => 'See foto';

  @override
  String get reportIncidentChoosePhoto => 'Họrọ site na gallery';

  @override
  String reportIncidentRemovePhoto(int n) {
    return 'Wepụ foto $n';
  }

  @override
  String reportIncidentUploading(int done, int total) {
    return 'Na-eziga foto $done n\'ime $total';
  }

  @override
  String get reportIncidentSent =>
      'Ezigala akụkọ. Ndị nchekwa anyị ga-esochi ya.';

  @override
  String get reportIncidentQueued =>
      'Enweghị signal. Echekwala akụkọ, ọ ga-eziga mgbe ọ lọghachiri.';

  @override
  String get reportIncidentFailed => 'Enweghị ike iziga akụkọ. Nwaa ọzọ.';

  @override
  String get reportIncidentPhotoError => 'Enweghị ike itinye foto ahụ';

  @override
  String optionCardRouteLine(String board, String alight) {
    return 'Banye na $board → $alight';
  }
}
