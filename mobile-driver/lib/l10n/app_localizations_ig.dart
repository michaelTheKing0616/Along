// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Igbo (`ig`).
class AppLocalizationsIg extends AppLocalizations {
  AppLocalizationsIg([String locale = 'ig']) : super(locale);

  @override
  String get driverBrandingLine => 'Nyere Along aka';

  @override
  String get phoneEntryTitle => 'Nyere Along aka';

  @override
  String get phoneEntrySubtitle =>
      'Anyị ga-ezitere nọmba a koodu ka ụbọchị gị bụrụ nke gị.';

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
  String get errorInvalidPhone => 'Tinye nọmba Naịjirịa ziri ezi';

  @override
  String get errorWrongOtp => 'Koodu ezighi ezi — nwaa ọzọ';

  @override
  String get errorExpiredOtp => 'Koodu agwụla — rịọ nke ọhụrụ';

  @override
  String errorRateLimited(int seconds) {
    return 'Ọ gafere ugboro. Nwaa ọzọ n\'ime ${seconds}s';
  }

  @override
  String get errorGeneric => 'Ihe adịghị mma mere. Biko nwaa ọzọ.';

  @override
  String get errorAuthNotConfigured =>
      'Ewu a ejikọghị na Along. Wughachi staging APK jiri env/staging.json.';

  @override
  String get errorValidation => 'Biko lelee mpaghara ndị ahụ ma nwaa ọzọ.';

  @override
  String get errorPlateConflict => 'E debanyelarị nọmba ụgbọ a.';

  @override
  String get profileTitle => 'Profaịlụ gị';

  @override
  String get profileSubtitle => 'Gwa anyị ntakịrị maka onwe gị';

  @override
  String get nameLabel => 'Aha zuru ezu';

  @override
  String get nameHint => 'Aha gị';

  @override
  String get cityLabel => 'Obodo';

  @override
  String get genderLabel => 'Okike (nhọrọ)';

  @override
  String get genderFemale => 'Nwaanyị';

  @override
  String get genderMale => 'Nwoke';

  @override
  String get genderOther => 'Achọghị m ikwu';

  @override
  String get photoOptional => 'Tinye foto (nhọrọ)';

  @override
  String get vehicleTitle => 'Ụgbọala gị';

  @override
  String get vehicleSubtitle => 'Kedu ka ị ga-esi kwọọ na Along?';

  @override
  String get plateLabel => 'Nọmba ụgbọ';

  @override
  String get plateHint => 'dịka ABC-123-XY';

  @override
  String get seatsLabel => 'Oche';

  @override
  String get colorLabel => 'Agba';

  @override
  String get makeModelLabel => 'Ụdị na model';

  @override
  String get ownerQuestion => 'Ụgbọala a ọ bụ nke gị?';

  @override
  String get ownerYes => 'Ee, ọ bụ nke m';

  @override
  String get ownerNo => 'Mba, ọ bụ nke onye ọzọ';

  @override
  String get ownerNameLabel => 'Aha onye nwe ya';

  @override
  String get ownerPhoneLabel => 'Ekwentị onye nwe ya';

  @override
  String get documentsTitle => 'Kwado akwụkwọ gị';

  @override
  String get documentsSubtitle => 'Bulite akwụkwọ ọ bụla ka ịmalite ịkwọ';

  @override
  String get docStatusNotStarted => 'Amalitebeghị';

  @override
  String get docStatusPending => 'Na-echere';

  @override
  String get docStatusApproved => 'Akwadola';

  @override
  String get docStatusRejected => 'A jụrụ ya';

  @override
  String get saveAndContinueLater => 'Chekwaa ma gaa n\'ihu emesịa';

  @override
  String captureTitle(String document) {
    return 'See $document';
  }

  @override
  String get captureGuide => 'Tinye akwụkwọ n\'ime okpokolo';

  @override
  String get takePhoto => 'See foto';

  @override
  String get retakePhoto => 'See ọzọ';

  @override
  String get submitDocument => 'Ziga akwụkwọ';

  @override
  String get ocrReviewTitle => 'Lelee nkọwa e wepụtara';

  @override
  String get ocrReviewSubtitle => 'Kwado mpaghara ọ bụla tupu iziga';

  @override
  String ocrSuggestedValue(String value) {
    return 'Atụrụ aro: $value';
  }

  @override
  String get ocrConfirmField => 'Jiri nke a';

  @override
  String get ocrFieldConfirmed => 'Akwadola';

  @override
  String get ocrNoAutoFillNote =>
      'Anaghị etinye nọmba NJ n\'onwe ya — pịa kwado maka mpaghara ọ bụla.';

  @override
  String get pendingTitle => 'Nkwado na-aga n\'ihu';

  @override
  String get pendingHero => 'Anyị na-enyocha akwụkwọ gị';

  @override
  String get pendingExpectedGeneric => 'Ọ na-ewekarị ụbọchị ọrụ 1–3';

  @override
  String pendingExpectedHours(int hours) {
    return 'A na-atụ anya n\'ime awa $hours';
  }

  @override
  String get pendingWhatNext =>
      'Anyị ga-agwa gị mgbe akwadoro gị. Ị nwere ike ịhazi ụzọ gị ka ị na-eche.';

  @override
  String get setupRouteCta => 'Hazie ụzọ gị ka ị na-eche';

  @override
  String get routesListTitle => 'Ụzọ gị';

  @override
  String get routesAddRoute => 'Tinye ụzọ';

  @override
  String get routesEmptyTitle => 'Hazie ụzọ gị na mpịa ole na ole';

  @override
  String get routesEmptyBody =>
      'Bipụta ebe nkwụsị na ọnụahịa gị ka ndị njem chọta gị n\'ụzọ gị.';

  @override
  String get routeSuggestedCardTitle => 'Ụzọ a tụrụ aro';

  @override
  String routeSuggestedCardBody(String mode, int stopCount) {
    return 'Anyị chọpụtara ụzọ $mode ị na-aga nwere ebe nkwụsị $stopCount.';
  }

  @override
  String get routeSuggestedCardCta => 'Pịa ka ilele ma bipụta';

  @override
  String routeUnnamedProfile(String mode) {
    return 'Ụzọ $mode';
  }

  @override
  String routeStopsCount(int count) {
    return 'Ebe nkwụsị $count';
  }

  @override
  String routeLoadSurchargeLabel(String amount) {
    return 'Ego mgbakwunye ibu: $amount';
  }

  @override
  String get routeLoadSurchargeOptional => 'Ego mgbakwunye ibu (nhọrọ)';

  @override
  String get routeLoadSurchargeHint => 'dịka 50';

  @override
  String get routeFastSetupTitle => 'Nhazi ụzọ';

  @override
  String get routeFastSetupQuestion => 'Nke a ọ bụ ụzọ gị?';

  @override
  String routeFastSetupSubtitle(int count) {
    return 'Achọpụtara ebe nkwụsị $count n\'ụzọ gị';
  }

  @override
  String get routeYesPublish => 'Ee, bipụta';

  @override
  String get routeEditPrices => 'Dezie ọnụahịa';

  @override
  String get routeDrawManually => 'Mba, see ya n\'aka';

  @override
  String get routeDrawTitle => 'See ụzọ gị';

  @override
  String get routeDrawHint => 'Pịa maapụ ka itinye ebe nkwụsị';

  @override
  String get routeDrawEmptyStops => 'Tinye ọ dịkarịa ala ebe nkwụsị abụọ';

  @override
  String get routePublish => 'Bipụta';

  @override
  String routePriceToEnd(String amount) {
    return 'Ruo ọgwụgwụ: $amount';
  }

  @override
  String routeSnapMatched(String name) {
    return 'Dabara: $name ✓';
  }

  @override
  String get routeSnapNewStopHint => 'Ebe nkwụsị ọhụrụ — aha?';

  @override
  String get routeSnapPending => 'Na-edozi…';

  @override
  String get routePriceKeypadTitle => 'Tọọ ọnụahịa ruo ọgwụgwụ';

  @override
  String get routePriceKeypadSet => 'Tọọ';

  @override
  String get routePriceErrorNonMonotone =>
      'Ọnụahịa ekwesịghị ịrị elu ka a na-aga ebe a na-aga.';

  @override
  String get routePriceErrorLastNotZero => 'Ebe nkwụsị ikpeazụ ga-abụ ₦0.';

  @override
  String get routePriceErrorEmpty =>
      'Tinye ọ dịkarịa ala otu ebe nwere ọnụahịa.';

  @override
  String get routeLoadError => 'Enweghị ike ibuli ụzọ.';

  @override
  String get routePublishError => 'Enweghị ike ibipụta ụzọ. Nwaa ọzọ.';

  @override
  String get back => 'Laghachi';

  @override
  String get navHome => 'Ụlọ';

  @override
  String get navRoutes => 'Ụzọ';

  @override
  String get navEarnings => 'Ego';

  @override
  String get navAccount => 'Akaụnt';

  @override
  String get homeUnverifiedBanner => 'Mezue nkwado ka ị banye n\'ịntanetị.';

  @override
  String get homeBatteryGuardBanner =>
      'Batrị adịla ala — ọnọdụ na-emelite nwayọ iji chekwa ike.';

  @override
  String get homeLedgerBlockedBanner =>
      'Akwụsịtụla njikọ — kwụọ ụgwọ gị ka ị banye.';

  @override
  String get homeSelectPark => 'Na: họrọ ogige ▾';

  @override
  String homeAtPark(String parkName) {
    return 'Na: $parkName ▾';
  }

  @override
  String get homeDirectionOnRoute => 'Ụzọ: n\'ụzọ m ▾';

  @override
  String get homeDirectionNone => 'Ụzọ: ọ dịghị ▾';

  @override
  String get homeErrorSelectPark => 'Họrọ ogige tupu ị banye n\'ogige.';

  @override
  String get homeErrorLocation => 'Gbanye ọnọdụ ka ị banye.';

  @override
  String get homeParkPickerTitle => 'Ogige dị nso';

  @override
  String get homeParkPickerEmpty => 'Enweghị ogige nso.';

  @override
  String homeParkDistance(int meters) {
    return '$meters m site ebe a';
  }

  @override
  String get homeParkSomewhereElse => 'Anọ m ebe ọzọ';

  @override
  String get incomingRequestTitle => 'Arịrịọ ọhụrụ';

  @override
  String incomingRequestCountdown(int seconds) {
    return '${seconds}s';
  }

  @override
  String incomingRequestRiderLine(String name, String rating, int trips) {
    return '$name · $rating · njem $trips';
  }

  @override
  String get incomingRequestPickup => 'Nbuli';

  @override
  String get incomingRequestRoamingPickup => 'Ebe onye njem nọ';

  @override
  String get incomingRequestRoamingPickupMeta =>
      'Ịkpọ ụgbọ n\'ụzọ — zute na ntụtụ';

  @override
  String incomingRequestCascade(int attempt, int max) {
    return 'Nwaa ọzọ $attempt n\'ime $max';
  }

  @override
  String get incomingRequestDropoff => 'Ebe ọdịda';

  @override
  String incomingRequestPickupMeta(int distance, int eta) {
    return '$distance m · $eta min';
  }

  @override
  String incomingRequestFareLine(String amount, String tierLabel) {
    return 'Onye njem ga-akwụ $amount · $tierLabel';
  }

  @override
  String incomingRequestAlongFee(String amount, String percent) {
    return 'Ụgwọ Along $amount · $percent%';
  }

  @override
  String get incomingRequestLoadDefault => 'Onye njem nwere ibu';

  @override
  String incomingRequestLoadDetail(String size, String note) {
    return 'Ibu $size — $note';
  }

  @override
  String get incomingRequestWomenOnly => 'Njikọ ụmụnwaanyị naanị';

  @override
  String get incomingRequestApproachBandUnder2 => 'n\'okpuru min 2';

  @override
  String get incomingRequestApproachBandM2_5 => 'min 2–5';

  @override
  String get incomingRequestApproachBandOver5 => 'min 5+';

  @override
  String get incomingRequestAccept => 'Nabata';

  @override
  String get incomingRequestDecline => 'Jụ';

  @override
  String get declineReasonTitle => 'Gịnị mere ị jụrụ?';

  @override
  String get declineReasonNoRoomForLoad => 'Enweghị ohere maka ibu';

  @override
  String get declineReasonTooFar => 'O teere aka';

  @override
  String get declineReasonEndingShift => 'Ana m akwụsị ọrụ';

  @override
  String get declineReasonOther => 'Ọzọ';

  @override
  String get fareTierStandard => 'Ụgwọ nkịtị';

  @override
  String get fareTierCommunity => 'Ụgwọ ndị mmadụ';

  @override
  String get fareTierProfile => 'Ọnụahịa ọkwọ ụgbọ';

  @override
  String get fareTierEstimate => 'Atụmatụ — kwenye ọnụahịa';

  @override
  String pricingRiderOffer(String amount) {
    return 'Onye njem nyere $amount';
  }

  @override
  String get pricingLapsed =>
      'Enweghị nkwekọrịta — onye njem nwere ike ịhọrọ ụgbọ ọzọ';

  @override
  String get pricingOutOfRange => 'Ụgbọala agafeela — mkparịta ụka emechiela';

  @override
  String get pricingDeclined => 'Ị jụrụ ego a';

  @override
  String get pricingDismiss => 'Laghachi na maapụ';

  @override
  String get manifestTitle => 'Njem na-aga';

  @override
  String get manifestEmpty => 'Enweghị onye njem a nabatara';

  @override
  String manifestBoarding(String stage) {
    return 'Mbata: $stage';
  }

  @override
  String manifestStatus(String status) {
    return 'Ọnọdụ: $status';
  }

  @override
  String get manifestMarkBoarded => 'Abanyela';

  @override
  String manifestOpen(int count) {
    return 'Njem na-aga ($count)';
  }

  @override
  String get activeTripStart => 'Malite njem';

  @override
  String get activeTripComplete => 'Mechaa njem';

  @override
  String activeTripBoardAlight(String board, String alight) {
    return '$board → $alight';
  }

  @override
  String activeTripWalkEta(int minutes) {
    return 'Ije nkeji $minutes';
  }

  @override
  String get activeTripStalledCaption => 'anaghị abịaru nso';

  @override
  String get activeTripRelease => 'Hapụ';

  @override
  String get activeTripReport => 'Kọọ akụkọ';

  @override
  String get sosTeamAlerted => 'Njikere ịkpọ 112';

  @override
  String get sosSharingDetails => 'Kesaa ọnọdụ gị ugbu a na ndị kọntaktị gị';

  @override
  String sosCallEmergency(String number) {
    return 'Kpọọ $number';
  }

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
  String get reportIncidentSubmit => 'Ziga akụkọ';

  @override
  String get reportIncidentPickCategory => 'Họrọ otu';

  @override
  String get reportIncidentDescriptionRequired => 'Tinye nkọwa dị mkpirikpi';

  @override
  String get reportIncidentSubmitted => 'Echekwara akụkọ na ekwentị a';

  @override
  String get incidentCategorySafety => 'Nchegbu nchekwa';

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
  String get accountProfileHeading => 'PROFAỊLỤ';

  @override
  String get accountProfileUnknown => 'Ọkwọ ụgbọ';

  @override
  String get accountVerified => 'Enyochaala';

  @override
  String get accountUnverified => 'Akwadobeghị';

  @override
  String get accountVehicleHeading => 'ỤGBỌALA';

  @override
  String get accountVehicleActiveHint => 'Ụgbọala na-arụ ọrụ';

  @override
  String get accountVehicleEmpty => 'Tinye ụgbọala gị';

  @override
  String get accountVehicleSwitchHint => 'Kpọtụrụ enyemaka ka ịgbanwe ụgbọala';

  @override
  String get accountDocumentsHeading => 'AKWỤKWỌ';

  @override
  String get accountDocumentsAllApproved => 'Akwadola akwụkwọ niile';

  @override
  String get accountDocumentsPending => 'Akwụkwọ na-eche nyocha';

  @override
  String get accountDocumentsNeedsAttention =>
      'Ụfọdụ akwụkwọ chọrọ nlebara anya';

  @override
  String get accountDocumentsIncomplete => 'Akwụkwọ ezughị ezu';

  @override
  String get accountDocumentsUnknown => 'Ọnọdụ akwụkwọ adịghị';

  @override
  String get accountPayoutHeading => 'ỊNATA EGO';

  @override
  String get accountPayoutBank => 'Ụlọakụ ịnata ego';

  @override
  String accountPayoutConfigured(String last4) {
    return 'Ụlọakụ na-akwụsị na $last4';
  }

  @override
  String get accountPayoutNotConfigured => 'Tọọ ụlọakụ ịnata ego';

  @override
  String get accountPreferencesHeading => 'NHỌRỌ';

  @override
  String get accountCityLabel => 'Obodo ọrụ';

  @override
  String get accountCityHint => 'Maapụ, paks na arịrịọ na-eji obodo a';

  @override
  String get accountLanguage => 'Asụsụ';

  @override
  String get accountLanguageValue => 'Igbo';

  @override
  String get accountSafetyHeading => 'NCHEKWA';

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
  String get homeLedgerBlockedTitle => 'Akwụsịtụla njikọ';

  @override
  String homeLedgerBlockedBalance(String amount) {
    return 'Ego fọdụrụ $amount';
  }

  @override
  String homeLedgerBlockedThreshold(String amount) {
    return 'Oke mgbochi $amount';
  }

  @override
  String get settleCta => 'Kwụọ ụgwọ';

  @override
  String get settleTitle => 'Kwụọ ụgwọ';

  @override
  String settleCurrentBalance(String amount) {
    return 'Ego fọdụrụ ugbu a: $amount';
  }

  @override
  String get settleAmountLabel => 'Ego a ga-akwụ';

  @override
  String get settleChannelBank => 'Nzipu ụlọakụ';

  @override
  String get settleChannelUssd => 'USSD';

  @override
  String get settleChannelCard => 'Kaadị';

  @override
  String get settleChannelAgent => 'Kwụọ onye nnọchite';

  @override
  String get settleAgentCodeTitle => 'Koodu onye nnọchite gị';

  @override
  String settleAgentExpires(String time) {
    return 'Ọ ga-agwụ $time';
  }

  @override
  String get settleNearbyAgentsTitle => 'Ndị nnọchite nso';

  @override
  String settleNearbyAgentDistance(int distance) {
    return '$distance m site ebe a';
  }

  @override
  String get settleDone => 'Emechaala';

  @override
  String get earningsLedgerSection => 'Mmegharị ego';

  @override
  String get earningsTripsSection => 'NJEM';

  @override
  String get earningsLedgerEmpty => 'Enweghị ndekọ ugbu a';

  @override
  String get earningsTripsCaption =>
      'Ego aka ị natara ozugbo — ọ bụghị akụkụ ego Along gị';

  @override
  String get earningsTripsEmpty => 'Enweghị njem ego aka emechara taa';

  @override
  String earningsTripsTodaySummary(int count, String amount) {
    return 'Njem $count taa · natara $amount';
  }

  @override
  String get standingLink => 'Ọnọdụ';

  @override
  String get standingTitle => 'Ọnọdụ gị';

  @override
  String standingBalanceAt(String amount) {
    return 'Ego fọdụrụ mgbe mgbanwe: $amount';
  }

  @override
  String standingBlockThreshold(String amount) {
    return 'Nhazi na-akwụsị ma ụgwọ gafere $amount';
  }

  @override
  String standingGraceDeadline(String date) {
    return 'Oge ntachi obi: $date';
  }

  @override
  String get standingRestoreHint =>
      'Kwụọ karịa oke ịdọ aka na ntị ka ọnọdụ gị laghachi';

  @override
  String get standingHistoryTitle => 'AKỤKỌ';

  @override
  String get standingHistoryEmpty => 'Enweghị mgbanwe ọnọdụ';

  @override
  String get guarantorLink => 'Tinye onye nkwado';

  @override
  String get guarantorTitle => 'Onye nkwado';

  @override
  String get guarantorExplainer =>
      'A na-agwa onye nkwado gị ma ụgwọ gị anaghị akwụ mgbe oge ntachi obi gafere. Anaghị ewepụ ego n\'aka ya.';

  @override
  String get guarantorTypeDriver => 'Ọkwọ ụgbọ ibe';

  @override
  String get guarantorTypeOwner => 'Onye nwe ụgbọ';

  @override
  String get guarantorNameLabel => 'Aha zuru ezu';

  @override
  String get guarantorPhoneLabel => 'Nọmba ekwentị';

  @override
  String get guarantorSubmit => 'Tinye onye nkwado';

  @override
  String get guarantorSuccess =>
      'Etinyela onye nkwado — ọ ga-anata njikọ nkwenye';

  @override
  String get extendTripTitle => 'Gbatịa njem';

  @override
  String get extendTripSearchHint => 'Ebee ugbu a?';

  @override
  String extendTripDestination(String destination) {
    return 'Na-aga n\'ihu ruo $destination';
  }

  @override
  String get extendTripPropose => 'Tụọ onye njem aro';

  @override
  String get incomingExtensionTitle => 'Arịrịọ mgbatị';

  @override
  String get incomingExtensionDecline => 'Jụ';

  @override
  String get incomingExtensionAccept => 'Nabata';

  @override
  String incomingRiderExtensionBody(String destination, String delta) {
    return 'Onye njem chọrọ ịga n\'ihu ruo $destination maka +$delta';
  }

  @override
  String get tripCompleteTitle => 'Njem agwụla';

  @override
  String tripCompleteFareLine(String amount) {
    return 'Ego $amount — onye njem ga-akwụ gị ego aka';
  }

  @override
  String tripCompleteAlongFeeLine(String amount) {
    return 'Ego Along $amount — etinyere n\'akaụnt gị';
  }

  @override
  String tripCompleteNewBalance(String amount) {
    return 'Ego fọdụrụ ọhụrụ $amount';
  }

  @override
  String get tripCompleteCashQuestion => 'Kwado na ị natara ego aka?';

  @override
  String get tripCompleteYes => 'Ee';

  @override
  String get tripCompleteDifferent => 'Ego dị iche';

  @override
  String get tripCompleteDifferentPrompt => 'Ego ole ka ị natara?';

  @override
  String get tripCompleteRateTitle => 'Nye onye njem gị akara';

  @override
  String get tripCompleteDone => 'Emechaala';

  @override
  String get requestPayment => 'Rịọ ụgwọ';

  @override
  String tripCompleteDigitalLine(String amount) {
    return 'Akwụrụ n\'ịntanetị · $amount ezigara ụlọakụ gị';
  }

  @override
  String tripCompleteDigitalFeeLine(String amount) {
    return 'Ewepụlarị ego Along $amount';
  }

  @override
  String get myQrTitle => 'Koodu QR m';

  @override
  String get myQrAccountSubtitle => 'Kesaa koodu gị maka ịkwụ ụgwọ n\'ịntanetị';

  @override
  String get myQrDigitalDisabledBanner =>
      'Ịkwụ ụgwọ n\'ịntanetị amalitebeghị — QR gị bụ maka nhazi na nnwale naanị.';

  @override
  String get myQrPayoutPrompt => 'Tọọ ụlọakụ ịnata ego';

  @override
  String get myQrPayoutHint =>
      'Tinye akaụnt ụlọakụ gị ka ndị njem kwụọ gị n\'ịntanetị. Along anaghị ejide ego gị.';

  @override
  String get myQrSetupPayout => 'Tọọ ụlọakụ ịnata ego';

  @override
  String get myQrPayoutComingSoon =>
      'Nhazi ịnata ego ga-emepe na Akaụnt mgbe ịkwụ ụgwọ n\'ịntanetị malitere.';

  @override
  String get myQrShare => 'Kesaa dịka foto';

  @override
  String get myQrOrderSticker => 'Tụọ sitika';

  @override
  String myQrStickerStatus(String status) {
    return 'Arịrịọ sitika: $status';
  }

  @override
  String get myQrVerifySticker => 'Kwado sitika m';

  @override
  String get myQrVerifyMatch => 'Sitika dabara koodu na nọmba ụgbọ gị';

  @override
  String get myQrVerifyMismatch => 'Sitika a adabaghị akaụnt gị';

  @override
  String get myQrVerifyInvalid => 'Ọ bụghị koodu QR Along';

  @override
  String get myQrVerifyTimeout => 'Oge nyocha agwụla — nwaa ọzọ';

  @override
  String get myQrPauseDigital => 'Kwụsịtụ ịkwụ ụgwọ n\'ịntanetị';

  @override
  String get myQrPauseDigitalHint =>
      'Ndị njem ga-ahụ naanị ego aka mgbe akwụsịtụrụ';

  @override
  String get myQrPausedBanner =>
      'Akwụsịtụla ịkwụ ụgwọ n\'ịntanetị — ndị njem na-ahụ naanị ego aka';

  @override
  String get myQrRotate => 'Gbanwee koodu';

  @override
  String get myQrRotateConfirmTitle => 'Gbanwee koodu QR?';

  @override
  String get myQrRotateConfirmBody =>
      'Sitika gị ugbu a ga-akwụsị ịrụ ọrụ. Ndị ọrụ ga-ebipụta ọhụrụ.';

  @override
  String get myQrRotateCancel => 'Kagbuo';

  @override
  String get myQrRotateConfirm => 'Gbanwee';

  @override
  String get paymentRequestTitle => 'Arịrịọ ụgwọ';

  @override
  String paymentRequestForRider(String riderName) {
    return 'Maka $riderName';
  }

  @override
  String paymentRequestCountdown(int seconds) {
    return 'Ọ ga-agwụ n\'ime ${seconds}s';
  }

  @override
  String get paymentRequestWaiting => 'Na-eche ụgwọ…';

  @override
  String paymentRequestPaidLine(String amount) {
    return 'Akwụọla $amount ✓';
  }

  @override
  String paymentRequestBankLine(String amount) {
    return '$amount na ụlọakụ gị';
  }

  @override
  String get paymentRequestDone => 'Emechaala';

  @override
  String get paymentRequestExpired => 'QR a agwụla — mepụta ọhụrụ';

  @override
  String get paymentRequestDigitalDisabled =>
      'Ịkwụ ụgwọ n\'ịntanetị amalitebeghị';

  @override
  String get paymentRequestTokenError =>
      'Enweghị ike ịkwado QR ụgwọ — nwaa ọzọ';

  @override
  String get earningsDigitalSection => 'Ịkwụ ụgwọ dijitalụ';

  @override
  String get earningsDigitalCaption =>
      'Akwụrụ ozugbo n\'ụlọakụ gị — ọ bụghị akụkụ ego Along gị';

  @override
  String get earningsDigitalEmpty => 'Enweghị ụgwọ n\'ịntanetị';

  @override
  String earningsDigitalRow(String source) {
    return 'Ịntanetị · $source';
  }

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
  String get emergencyContactAdd => 'Tinye kọntaktị';

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
  String get buildMyDayTitle => 'Wuo ụbọchị m';

  @override
  String get buildMyDayStart => 'Chekwaa ma jiri ụbọchị a';

  @override
  String get buildMyDayCorridor => 'Ụzọ';

  @override
  String get saveLayout => 'Chekwaa nhazi';

  @override
  String get layoutName => 'Aha nhazi';

  @override
  String get addRow => 'Tinye ahịrị';

  @override
  String get addSeat => 'Tinye oche';

  @override
  String get removeRow => 'Wepụ ahịrị';

  @override
  String get overCapacityNote =>
      'Nke a karịrị ọnụọgụ oche a na-ahụ. Echekwara ya ma debe ya maka nyocha.';

  @override
  String get seatMapTitle => 'Maapụ oche';

  @override
  String get seatFull => 'Ejupụtala';

  @override
  String get seatEmpty => 'Tọgbọrọ';

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
  String get rideRulesHeading => 'Iwu njem';

  @override
  String get customRuleHint => 'Isiokwu iwu';

  @override
  String get customRuleBody => 'Ihe ndị njem kwesịrị ịma';

  @override
  String get customRuleSave => 'Tinye iwu m';

  @override
  String get holdMinutes => 'Nkeji njide';

  @override
  String get capMax => 'Oke oche';

  @override
  String get deleteRule => 'Wepụ iwu';

  @override
  String get dayNeedsCorridor => 'Họrọ ụzọ';

  @override
  String get seatStale => 'Maapụ oche karịrị otu nkeji';

  @override
  String get shiftStart => 'Ọrụ na-amalite';

  @override
  String get shiftEnd => 'Ọrụ na-akwụsị';

  @override
  String get homeLabel => 'Ebe nkwụsị ụzọ ụlọ';

  @override
  String get walkExtension => 'Nkeji njide ọzọ maka onye na-eje ije';

  @override
  String get seatLuggage => 'ibu';

  @override
  String get voiceCommandHint =>
      'Kwuo nabata, juru, ma ọ bụ oche azụ aka ekpe tọgbọrọ';

  @override
  String get conductorOpen => 'Koodu kọndọkịta';

  @override
  String get conductorTitle => 'Kọndọkịta';

  @override
  String get conductorCode => 'Koodu sitere n\'aka ọkwọ ụgbọ';

  @override
  String get conductorJoin => 'Mepee maapụ oche';

  @override
  String get ghostSeatTitle => 'Ka nwere onye mgbe ọdịda gasịrị?';

  @override
  String get ghostSeatFree => 'Tọhapụ ya';

  @override
  String freeSeatCount(int count) {
    return '$count tọgbọrọ chakoo';
  }

  @override
  String get restTitle => 'Izu ike';

  @override
  String get restDriveMinutes => 'Nkeji ịkwọ tupu izu ike';

  @override
  String get restMinutes => 'Nkeji izu ike';

  @override
  String get restSave => 'Chekwaa';

  @override
  String get restStart => 'Malite izu ike';

  @override
  String get restFinish => 'Kwụsị izu ike';

  @override
  String get restPriority => 'Ụzọ mbụ n\'ọrụ ruo mgbe oge izu ike gị gwụrụ';

  @override
  String get marketplaceTitle => 'Taa';

  @override
  String get marketplaceGoal => 'Ebumnuche taa';

  @override
  String get marketplaceEarned => 'Enwetala';

  @override
  String get marketplaceTypical => 'Ego oche a na-akwụkarị';

  @override
  String marketplaceSeats(int count) {
    return 'Oche $count fọdụrụ';
  }

  @override
  String get marketplaceGoalMet => 'Erutela ebumnuche';

  @override
  String get marketplaceSave => 'Chekwaa';

  @override
  String get marketplaceCorridor => 'Ụzọ ị na-ele';

  @override
  String get marketplaceRequests => 'Arịrịọ';

  @override
  String get marketplaceAddCorridor => 'Tinye';

  @override
  String marketplaceTip(String corridor) {
    return 'Banye n\'ahịrị gaa $corridor';
  }

  @override
  String get marketplaceFuel => 'Ọnụahịa otu lita';

  @override
  String get marketplaceFuelLabel => 'Pọmpụ';

  @override
  String get marketplaceFuelSave => 'Chekwaa ọnụahịa';

  @override
  String get marketplaceEventName => 'Aha emume';

  @override
  String get marketplaceEventHours => 'Awa ebe ahụ ga-emeghe';

  @override
  String get marketplaceEventSave => 'Mepee ebe ahụ';

  @override
  String activeTripMessageRider(String name) {
    return 'Zitere $name ozi';
  }

  @override
  String get activeTripMessageRiderUnknown => 'Zitere onye njem ozi';

  @override
  String get tripEtaCalculating => 'Anyị na-agbakọ…';

  @override
  String tripEtaPickup(String label) {
    return 'Ebe nbuli $label';
  }

  @override
  String get drivePhasePickup => 'Nbuli';

  @override
  String get drivePhaseBoard => 'Banye';

  @override
  String get drivePhaseDrop => 'Ịwụda';

  @override
  String activeTripPickUpTitle(String name) {
    return 'Buru $name';
  }

  @override
  String activeTripOnBoardTitle(String name) {
    return '$name abanyela';
  }

  @override
  String activeTripDropTitle(String name) {
    return 'Wụda $name';
  }

  @override
  String get activeTripRiderFallback => 'onye njem gị';

  @override
  String get activeTripBoardNaMe => 'Banye na Na Me';

  @override
  String get activeTripEnterPin => 'Tinye PIN nbuli';

  @override
  String get activeTripPinShort => 'PIN';

  @override
  String get activeTripMessageShort => 'Ozi';

  @override
  String get activeTripSeatsShort => 'Oche';

  @override
  String get activeTripExtendShort => 'Gbatịa';

  @override
  String get activeTripReportShort => 'Kọọ';

  @override
  String get activeTripFareLabel => 'Onye njem ga-akwụ';

  @override
  String activeTripFeeCaption(String amount, String percent) {
    return 'Ụgwọ Along $amount ($percent%)';
  }

  @override
  String incomingAcceptFare(String amount) {
    return 'Nabata · $amount';
  }

  @override
  String incomingFareCaption(String tierLabel) {
    return 'Onye njem ga-akwụ · $tierLabel';
  }

  @override
  String get homeOfflineTitle => 'Ị nọghị n\'ịntanetị';

  @override
  String get homeOnlineTitle => 'Ị nọ n\'ịntanetị';

  @override
  String get homeOfflineHint => 'Banye n\'ịntanetị ka ị nweta arịrịọ nso gị.';

  @override
  String get homeOnlineHint => 'Arịrịọ ga-apụta ebe a. Nabata n\'otu mmetụ.';

  @override
  String get homeGoOnline => 'GAA';

  @override
  String get homeGoOffline => 'Pụọ n\'ịntanetị';

  @override
  String get homeModeAtPark => 'N\'ogige';

  @override
  String get homeModeRoaming => 'Na-agagharị';

  @override
  String get homeModeFull => 'Ejupụtala';

  @override
  String homeTodayEarned(String amount) {
    return 'Taa · $amount';
  }

  @override
  String homeTodayTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Njem $count',
      one: 'Njem 1',
      zero: 'Enweghị njem ka',
    );
    return '$_temp0';
  }

  @override
  String get homeShortcutsTitle => 'Ụbọchị gị';

  @override
  String get homeDirectionShortOnRoute => 'N\'ụzọ m';

  @override
  String get homeDirectionShortNone => 'Ụzọ ọ bụla';

  @override
  String get homeTileDemand => 'Ọchịchọ';

  @override
  String get tripCompleteCashHero => 'Nara ego n\'aka';

  @override
  String get tripCompleteRowFare => 'Ụgwọ ụgbọ';

  @override
  String get tripCompleteRowFee => 'Ụgwọ Along (na ego fọdụrụ)';

  @override
  String get tripCompleteRowBalance => 'Ego fọdụrụ ọhụrụ';

  @override
  String tripCompleteYesAmount(String amount) {
    return 'Ee, anatara m $amount';
  }

  @override
  String get settleSubtitle => 'Akaụntụ Along gị';

  @override
  String get settleOwedLabel => 'Ị ji Along ụgwọ';

  @override
  String get settleCreditLabel => 'Ego fọdụrụ gị';

  @override
  String settleThreshold(String amount) {
    return 'Nhazi na-akwụsị ma ụgwọ gafere $amount';
  }

  @override
  String get settleMethodTitle => 'Kwụọ site na';

  @override
  String settleSubmit(String amount) {
    return 'Kwụọ $amount';
  }

  @override
  String get settleChannelBankDetail => 'Zigara akaụntụ Along gị';

  @override
  String get settleChannelUssdDetail => 'Kpọọ koodu, enweghị data';

  @override
  String get settleChannelCardDetail => 'Kaadị ụlọ akụ';

  @override
  String get settleChannelAgentDetail => 'Kwụọ ego n\'aka onye nnọchi Along';

  @override
  String earningsBalanceAfter(String amount) {
    return 'Ego fọdụrụ $amount';
  }

  @override
  String get ratingTagSafeDriving => 'Ịnya nke ọma';

  @override
  String get ratingTagFairFare => 'Ụgwọ ziri ezi';

  @override
  String get ratingTagCleanVehicle => 'Ụgbọ dị ọcha';

  @override
  String get ratingTagPolite => 'Nwere nsọpụrụ';

  @override
  String get ratingTagOnTime => 'N\'oge';

  @override
  String get ratingTagReady => 'Dị njikere';

  @override
  String get ratingTagPaidPromptly => 'Kwụrụ ngwa ngwa';

  @override
  String get guarantorWhoTitle => 'Onye ga-akwado gị';

  @override
  String get guarantorDetailsTitle => 'Nkọwa ha';

  @override
  String get seatToolsTitle => 'Ngwa ọrụ ngwa ngwa';

  @override
  String get seatBoardEmptyBody =>
      'Hazie ụbọchị gị iji hazie oche ụgbọ gị. Mgbe ahụ ị nwere ike igosi ndị nọ n\'ime ebe a.';

  @override
  String get mpGoalSection => 'Ebumnuche taa';

  @override
  String get mpDemandSection => 'Ebe ndị njem nọ';

  @override
  String get mpFuelSection => 'Ọnụ ahịa mmanụ';

  @override
  String get mpEventSection => 'Mmemme dị nso';

  @override
  String seatBoardSubtitle(int count) {
    return '$count tọgbọrọ chakoo · pịa oche iji gbanwee ya';
  }

  @override
  String get mpSubtitle => 'Tọọ ebumnuche, hụ ebe ndị njem nọ, kesaa ndụmọdụ.';

  @override
  String get mpGoalEmpty => 'Tọọ ebumnuche ka ịhụ oche ole fọdụrụ';

  @override
  String get mpMoreSection => 'Kesaa ndị ọkwọ ụgbọ';

  @override
  String get mpFuelDetail => 'Ọnụ ahịa mmanụ taa nso';

  @override
  String get mpEventDetail => 'Mepee ebe nnabata maka igwe mmadụ';

  @override
  String get restSubtitle =>
      'Zuru ike nke ọma mgbe ogologo ịnya. Ezumike zuru oke na-ebuli gị n\'ahịrị.';

  @override
  String get restStatusDriving => 'N\'okporo ụzọ';

  @override
  String restStatusResting(String time) {
    return 'Na-ezu ike kemgbe $time';
  }

  @override
  String restPlan(int rest, int drive) {
    return 'Ezumike nkeji $rest kwa nkeji $drive';
  }

  @override
  String get restPlanEmpty => 'Tọọ ogologo ị na-anya tupu ezumike';

  @override
  String get restRhythmSection => 'Usoro gị';

  @override
  String get conductorSubtitle => 'Nyere onye ọkwọ aka ka oche dị ọhụrụ.';

  @override
  String get conductorHowTo =>
      'Onye ọkwọ na-emepe Map oche → Koodu kondọkta wee gụọrọ gị koodu mkpụrụ 8.';

  @override
  String get restDriveShort => 'Ịnya (nkeji)';

  @override
  String get restBreakShort => 'Ezumike (nkeji)';

  @override
  String get mpTargetShort => 'Ebumnuche';

  @override
  String get mpEarnedShort => 'Enwetara';

  @override
  String get daySubtitle =>
      'Họrọ ebe ị ga-arụ ọrụ, hazie oche na iwu ndị njem ga-ahụ.';

  @override
  String daySeatsCount(int count) {
    return 'Oche $count';
  }

  @override
  String get dayRouteOptional => 'Ụzọ (nhọrọ)';

  @override
  String get dayHoursSection => 'Oge gị';

  @override
  String get daySeatsSection => 'Oche';

  @override
  String get dayRemove => 'Wepu';

  @override
  String get dayAddRule => 'Tinye iwu';

  @override
  String get dayRuleRow => 'Metụtara';

  @override
  String dayRowN(int n) {
    return 'Ahịrị $n';
  }

  @override
  String get dayRuleDetails => 'Nkọwa iwu';

  @override
  String get dayRuleDetailsBody => 'Oge njide, ije ọzọ, oke oche, okwu';

  @override
  String get dayCustomRule => 'Dee iwu nke gị';

  @override
  String get dayCustomRuleBody => 'A na-egosi ndị njem tupu ha edebe';

  @override
  String get howItWorks => 'Otu o si arụ ọrụ';

  @override
  String get conductorStep1 => 'Nweta koodu';

  @override
  String get conductorStep1Body => 'Onye ọkwọ ụgbọ na-eker ya site na map oche';

  @override
  String get conductorStep2 => 'Banye n\'ụgbọ';

  @override
  String get conductorStep2Body => 'Ị na-ahụ otu oche ozugbo';

  @override
  String get conductorStep3 => 'Melite oche';

  @override
  String get conductorStep3Body => 'Pịa oche mgbe ndị njem banyere ma ọ bụ pụọ';

  @override
  String get seatEmptyStep1 => 'Họrọ ụgbọ gị';

  @override
  String get seatEmptyStep1Body => 'Anyị ga-ese oche ya';

  @override
  String get seatEmptyStep2 => 'Họrọ ụzọ';

  @override
  String get seatEmptyStep2Body => 'Ndị njem nọ na ya ga-ahụ oche gị';

  @override
  String get seatEmptyStep3 => 'Jupụta oche ka ị na-aga';

  @override
  String get seatEmptyStep3Body => 'Pịa oche iji kaa ya';

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
  String connNeedsConnection(int count) {
    return 'Enweghị ịntanetị · $count ka emeghachi n\'ịntanetị';
  }

  @override
  String connOfflineMixed(int queued, int needs) {
    return 'Enweghị ịntanetị · $queued iziga · $needs imeghachi';
  }

  @override
  String get homeOnlineNoSignal => 'Nọ n\'ịntanetị · enweghị signal';
}
